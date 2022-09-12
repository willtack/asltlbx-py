import nipype.interfaces.fsl as fsl
from nipype.interfaces import utility as niu
import nipype.pipeline.engine as pe
from nipype.interfaces.ants import N4BiasFieldCorrection
from nipype.interfaces.freesurfer import Binarize


def run_structural_workflow(anat_file, output_dir):
    """
    Structural processing workflow
    Inputs::
     skull_strip.in_file: raw T1 file

    Outputs::
     skull-stripped T1
     segmented T1

    """

    structural = pe.Workflow(name='structural', base_dir=output_dir)

    # inputnode = pe.Node(
    #     niu.IdentityInterface(fields=["in_files"]), name="inputnode"
    # )

    # Create brain mask
    #thr_brainmask = pe.Node(Binarize(), name="binarize")

    # INU correction
    inu_n4_final = pe.MapNode(
        N4BiasFieldCorrection(
            dimension=3,
            save_bias=True,
            copy_header=True,
            n_iterations=[50] * 5,
            convergence_threshold=1e-7,
            shrink_factor=4,
            bspline_fitting_distance=200,
        ),
        name="inu_n4_final",
        iterfield=["input_image"],
    )

    skull_strip = pe.Node(fsl.BET(), name='bet')
    segmentation = pe.Node(fsl.FAST(), name='fast')

    structural.connect([
    #     (inputnode, inu_n4_final, [("in_files", "input_image")]),
    # #    (inputnode, thr_brainmask, [("in_files", "in_file")]),
    #     (inu_n4_final, skull_strip, [("output_image", "in_file")]),
        (skull_strip, segmentation, [("out_file", "in_files")])
    ])

    # Run N4 bias correction
    #inu_n4_final.inputs.input_image = anat_file
    #n4 = inu_n4_final.run()
    #corrected_anat_file = n4.outputs.output_image

    # Run skull stripping and segmentation
    skull_strip.inputs.in_file = anat_file #corrected_anat_file[0]
    results = structural.run()

    return results
