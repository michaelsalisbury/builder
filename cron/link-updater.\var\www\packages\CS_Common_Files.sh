#!/bin/bash

dst=`readlink -nf $BASH_SOURCE`
dst=`basename "${dst}" .sh`
dst=`echo ${dst#*.} | tr '\\\\' '/'`
src="/home/localcosadmin/cos.ucf.edu/Departments\$/Technology/Technology Workspace/Client Services Files/CS Technician Resources/CS Common Files"

# Clean out stale links
#find "${dst}" -type l | while read link; do
#	pointer=`readlink -nf "${link}"`
#	[ -f "${pointer}" ] || rm -f "${link}"
#done

#    Copying files non-recursivelly from specific folders 
echo Copying files non-recursivelly from specific folders 
while read path; do
	folder=${path#${src}}
	echo $folder
	mkdir -p "${dst}/${folder}"
	find "${path}" ! -type d -maxdepth 1 -exec cp -v '{}' "${dst}/${folder}"/. \;
done << SOURCE-PATHS
${src}
SOURCE-PATHS

#    Copying files recursivelly from specific folders
echo Copying files recursivelly from specific folders
while read path; do
	folder=${path#${src}}
	echo $folder
	mkdir -p "${dst}/${folder}"
	rsync -rPu "${path}"/ "${dst}/${folder}"/
done << SOURCE-PATHS
${src}/Astra
${src}/Asset Utility
${src}/mac-Hardware-inventory
${src}/Post-OSD Files (For COSIT Use ONLY)
${src}/Registry Fixes
SOURCE-PATHS




