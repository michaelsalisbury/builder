#!/bin/bash
echo "Content-Type: text/plain"
echo # DO NOT REMOVE THIS BLANK LINE
#############################################################################
cat local.preseed
echo
cat ../preseed/preseed.hd.basic
echo
cat ../preseed/preseed.ntp
echo
cat ../preseed/preseed.repos-n-updates


#cat defaults.cfg.template

