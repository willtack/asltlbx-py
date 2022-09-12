#!/bin/bash

python /home/will/Gears/asltlbx-py/batch_run.py \
--aslfile /home/will/Gears/asltlbx-py/test2/data/ASL.nii \
--m0file /home/will/Gears/asltlbx-py/test2/data/M0.nii \
--m0type "Separate" \
--m0scale 10 \
--fwhm 8 \
--labelefficiency 0.72 \
--aslcontext /home/will/Gears/asltlbx-py/test2/data/aslcontext.tsv \
--pld 2.0 \
--ld 3.0 \
--outputdir /home/will/Gears/asltlbx-py/test2/output
