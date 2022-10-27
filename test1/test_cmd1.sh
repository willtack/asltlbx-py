#!/bin/bash

python /home/will/Gears/asltlbx-py/batch_run.py \
--aslfile /home/will/Gears/asltlbx-py/test1/data/ASL.nii \
--m0file /home/will/Gears/asltlbx-py/test1/data/M0.nii \
--m0type "Separate" \
--m0scale 10 \
--fwhm 8 \
--labelefficiency 0.72 \
--aslcontext /home/will/Gears/asltlbx-py/test1/data/aslcontext.tsv \
--pld 2.0 \
--ld 3.0 \
--asl_fwhm 2 \
--frac 0.5 \
--alt_skullstrip False \
--prefix sub-test1_ses-test1 \
--outputdir /home/will/Gears/asltlbx-py/test1/output


