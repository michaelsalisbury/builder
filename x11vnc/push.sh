#!/bin/bash

foldername=$(dirname "$(readlink -f ${BASH_SOURCE})")
packagename=$(basename "${foldername}")

# create tgz
tar -zcvf "${packagename}.tgz" *




