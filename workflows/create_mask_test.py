from skullstrip import init_asl_reference_wf

def print_outputs(file, workflow_results):
    print('', file=file)
    print(list(workflow_results.nodes), file=file)
    print('', file=file)
    for i in range(len(list(workflow_results.nodes)) - 1):
        print("%s: %s" % ("NODE", list(workflow_results.nodes)[i]), file=file)
        print(list(workflow_results.nodes)[i].result.outputs, file=file)
        print('', file=file)
    file.close()

# Args
nthreads = 2
asl_file = "/test1/data/ASL.nii"

# Set up and run
asl_reference_wf = init_asl_reference_wf(omp_nthreads=nthreads)

asl_reference_wf.inputs.inputnode.asl_file = asl_file
asl_reference_wf.outputs.outputnode.asl_mask = '/home/will/Gears/asltlbx-py/test1/output/asl_mask.nii'
run_wf = asl_reference_wf.run()
print(asl_reference_wf.outputs)
print(run_wf.nodes)

print()
n4_corrected_ref_file = list(run_wf.nodes)[5].result.outputs.output_image
print(n4_corrected_ref_file)
print()

import skullstrip2
mask_file = skullstrip2.skullstrip_asl(n4_corrected_ref_file)

print(mask_file)








# output_txt = open("/home/will/Gears/asltlbx-py/test1/output/outputs.txt", 'w')
# print_outputs(output_txt, run_wf)
# print()

