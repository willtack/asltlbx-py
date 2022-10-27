#!/bin/bash

python /opt/base/batch_run.py \
--aslfile /opt/base/input/ASL.nii \
--m0file /opt/base/input/M0.nii \
--m0type "Separate" \
--m0scale 10 \
--fwhm 8 \
--labelefficiency 0.72 \
--aslcontext /opt/base/input/aslcontext.tsv \
--pld 2.0 \
--ld 3.0 \
--asl_fwhm 3 \
--prefix "test3" \
--outputdir /opt/base/output
