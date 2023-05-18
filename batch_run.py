import sys
import os
import logging
import argparse
import nibabel as nb
import shutil
from nibabel.processing import smooth_image
import nilearn.plotting

from workflows import process_asl

# logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('asltlbx')
logger.info("=======: ASL processing :=======")


def get_parser():
    parser = argparse.ArgumentParser(
        description="")
    parser.add_argument(
        "--aslfile",
        help="Path to raw ASL file",
        required=True
    )
    parser.add_argument(
        "--m0file",
        help="Path to m0file",
        required=True
    )
    parser.add_argument(
        "--outputdir",
        help="Path to output directory",
        required=True
    )
    parser.add_argument(
        "--pld",
        help="Post-labelling delay",
        required=True
    )
    parser.add_argument(
        "--ld",
        help="Labelling duration",
        required=True
    )
    parser.add_argument(
        "--m0scale",
        help="M0 Scale",
        required=True
    )
    parser.add_argument(
        "--m0type",
        help="M0 type",
        required=True
    ),
    parser.add_argument(
        "--fwhm",
        help="smoothing kernel for M0",
        required=True
    )
    parser.add_argument(
        "--labelefficiency",
        help="labelefficiency",
        required=False
    )
    parser.add_argument(
        "--aslcontext",
        help="ASL context file",
        required=True
    )
    parser.add_argument(
        "--prefix",
        help="output file prefix",
        required=True
    )
    parser.add_argument(
        "--asl_fwhm",
        help="size of smoothing kernel for output mean ASL",
        required=True
    )
    parser.add_argument(
        "--dir",
        help="does the M0 image contain a DIR volume",
        required=True
    )


    return parser


def main():

    # Parse command line arguments
    arg_parser = get_parser()
    args = arg_parser.parse_args()

    asl = args.aslfile
    m0 = args.m0file
    pld = args.pld
    ld = args.ld
    m0scale = args.m0scale
    m0type = args.m0type
    fwhm = args.fwhm
    prefix = args.prefix
    labelefficiency = args.labelefficiency
    asl_fwhm = args.asl_fwhm
    # frac = args.frac
    # alt_skullstrip = args.alt_skullstrip
    aslcontext = args.aslcontext
    dir = args.dir
    outputdir = args.outputdir

    if not os.path.exists(outputdir):
        os.mkdir(outputdir)
    # Anatomical workflow
    # anat_results = structural.run_structural_workflow(mprage, outputdir)
    # print(anat_results)
    # print()

    if not asl.endswith(".gz"):
        os.system(f"bash /opt/base/check_zipped.sh {asl} ASL")
        asl = asl + ".gz"
        print(f"ASL: {asl}")

    if not m0.endswith(".gz"):
        os.system(f"bash /opt/base/check_zipped.sh {m0} M0")
        m0 = m0 + ".gz"
        print(f"M0: {m0}")

    # If there's a DIR volume in the M0 image, cut short
    if dir:
        os.system(f"fslroi {m0} {m0} 0 1")

    # ASL processing workflow
    # create ASL mask
    from workflows.skullstrip import init_asl_reference_wf
    nthreads = 2

    # Set up and run
    asl_reference_wf = init_asl_reference_wf(omp_nthreads=nthreads)

    asl_reference_wf.inputs.inputnode.asl_file = asl
    # asl_reference_wf.outputs.outputnode.asl_mask = '/home/will/Gears/asltlbx-py/test1/output/asl_mask.nii'
    run_wf = asl_reference_wf.run()

    n4_corrected_ref_file = list(run_wf.nodes)[5].result.outputs.output_image
    shutil.copy(n4_corrected_ref_file, os.path.join(outputdir, prefix + "_aslref_n4_corrected.nii.gz"))

    logger.info("Running SynthStrip for brain extraction...")
    masked_file = os.path.join(outputdir, prefix + "_aslref_brain.nii.gz")
    mask_file = os.path.join(outputdir, prefix + "_aslref_brainmask.nii.gz")
    cmd="/opt/freesurfer/bin/mri_synthstrip -i {} -o {} -m {}".format(n4_corrected_ref_file, masked_file, mask_file)
    os.system(cmd)

    # control-label subtraction
    cbf_ts, new_m0, affine = process_asl.extract_cbf(asl, m0, aslcontext, m0type, fwhm, mask_file, outputdir)
    # perfusion factor calculation
    mean_cbf, tcbf = process_asl.cbfcomputation(pld, ld, m0scale, mask_file, new_m0, cbf_ts, labelefficiency)

    mcbf_img = nb.Nifti1Image(mean_cbf, affine=affine)

    # smooth mean cbf
    smooth_mcbf_img = smooth_image(mcbf_img, fwhm=asl_fwhm)
    nb.save(smooth_mcbf_img, os.path.join(outputdir, prefix+"_native_mean_cbf.nii"))

    tcbf_img = nb.Nifti1Image(tcbf, affine=affine)
    nb.save(tcbf_img, os.path.join(outputdir, prefix+"_native_cbf_timeseries.nii"))

    # visualizations
    nilearn.plotting.plot_epi(smooth_mcbf_img, display_mode='mosaic', bg_img=None, black_bg=True, draw_cross=False, cmap='gist_gray',
                      vmin=0,vmax=80, cut_coords=10, colorbar=True, title=prefix + "_meanCBF_80_mosaic",
                      output_file=os.path.join(outputdir, prefix+"_meanCBF_80_mosaic.png"))

    nilearn.plotting.plot_epi(smooth_mcbf_img, display_mode='mosaic', bg_img=None, black_bg=True, draw_cross=False,cmap='gist_gray',
                      vmin=0, vmax=100, cut_coords=10, colorbar=True, title=prefix + "_meanCBF_100_mosaic",
                      output_file=os.path.join(outputdir, prefix + "_meanCBF_100_mosaic.png"))

    exit(0)


if __name__ == '__main__':
    sys.exit(main())
