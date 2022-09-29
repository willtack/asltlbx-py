#!/bin/bash
# gzip the ASL and M0 files if they are not already
#

#
file=$1
type=$2
if (file $file | grep -q compressed ) ; then
     echo "The ${type} file is compressed."
else
     echo "The ${type} file is not compressed. Gzipping now."
     gzip $file #> ${file}".gz"
fi
