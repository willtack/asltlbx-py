#!/bin/bash

docker run -ti --rm -v /home/will/Gears/asltlbx-py/test1/data:/opt/base/input:rw --entrypoint=/bin/bash willtack/asltlbx-py:0.1.2
