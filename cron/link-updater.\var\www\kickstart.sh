#!/bin/bash

dst=`readlink -nf $BASH_SOURCE`
dst=`basename "${dst}" .sh`
dst=`echo ${dst#*.} | tr '\\\\' '/'`

# Clean out stale links
find "${dst}" -type l | while read link; do
        pointer=`readlink -nf "${link}"`
        [ -f "${pointer}" ] || rm -f "${link}"
done

# Add new files from list of source paths
while read src; do
        ln -s "${src}"/* "${dst}"/.
done << SOURCE-PATHS
/var/www/repos/github/michaelsalisbury_builder/builder
SOURCE-PATHS

#/var/www/html/repos/github/michaelsalisbury_builder/UCK

# Add new files and subdirectorys from list of source paths
while read src; do
	find "${src}"   -type d | sed "s|${src}\(.*\)|mkdir -v        \"${dst}\1\"|" | bash
	find "${src}" ! -type d | sed "s|${src}\(.*\)|ln   -sv \"\0\" \"${dst}\1\"|" | bash
done << SOURCE-PATHS
/var/www/repos/github/michaelsalisbury_builder/kickstart
SOURCE-PATHS

# Clean up and remove all empty directories
find "${dst}" -depth -type d -empty -exec rm -rf '{}' \;

