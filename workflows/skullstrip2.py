from nipype.interfaces import fsl
import os

def skullstrip_asl(asl_ref_file, outputdir):
    #asl_file = "/tmp/tmp5vg6ic3k/asl_reference_wf/enhance_and_skullstrip_asl_wf/n4_correct/ref_bold_corrected.nii.gz"
    btr = fsl.BET()
    btr.inputs.in_file = asl_ref_file
    btr.inputs.frac = 0.8
    btr.inputs.mask = True
    btr.inputs.out_file = os.path.join(outputdir, "aslref_skullstripped.nii.gz")
    res = btr.run()
    mask_file = res.outputs.mask_file
    return mask_file