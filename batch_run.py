import sys
import os
import logging
import argparse
import nibabel as nb
from nibabel.processing import smooth_image

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
        "--frac",
        help="fractional intensity threshold for brain extraction",
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
    frac = args.frac
    aslcontext = args.aslcontext
    outputdir = args.outputdir

    if not os.path.exists(outputdir):
        os.mkdir(outputdir)
    # Anatomical workflow
    # anat_results = structural.run_structural_workflow(mprage, outputdir)
    # print(anat_results)
    # print()

    # ASL processing workflow
    # create ASL mask
    from workflows.skullstrip import init_asl_reference_wf
    nthreads = 2
    #asl_file = "/home/will/Gears/asltlbx-py/test1/data/ASL.nii"

    # Set up and run
    asl_reference_wf = init_asl_reference_wf(omp_nthreads=nthreads)

    asl_reference_wf.inputs.inputnode.asl_file = asl
    # asl_reference_wf.outputs.outputnode.asl_mask = '/home/will/Gears/asltlbx-py/test1/output/asl_mask.nii'
    run_wf = asl_reference_wf.run()

    n4_corrected_ref_file = list(run_wf.nodes)[5].result.outputs.output_image

    from workflows import skullstrip2
    mask_file = skullstrip2.skullstrip_asl(n4_corrected_ref_file, frac, outputdir)

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

    exit(0)


if __name__ == '__main__':
    sys.exit(main())
