#!/bin/bash

foldername=$(dirname "$(readlink -f ${BASH_SOURCE})")
packagename=$(basename "${foldername}")

# create tgz
tar -zcvf "${packagename}.tgz" *

# folder list to copy package to
while read path; do
	[ -d "${path}" ] && cp "${packagename}.tgz" "${path}/."
done << PATH-LIST
	/var/www/packages/Apps_Linux

PATH-LIST


# host list to rsync updates to
while read IP; do
	

done << HOST-LIST



HOST-LIST

