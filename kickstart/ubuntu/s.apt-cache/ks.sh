#!/bin/bash
echo "Content-Type: text/plain"
echo # DO NOT REMOVE THIS BLANK LINE
#############################################################################
cat local.cfg
echo
cat ../defaults.cfg.template
echo
cat packages.cfg
echo
cat ../pre.interactive-n-download.cfg

#cat defaults.cfg.template

