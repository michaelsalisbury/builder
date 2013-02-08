#!/bin/bash
function include(){
	echo '#############################################################################'
	cat $1
	echo
}
echo "Content-Type: text/plain"
echo # DO NOT REMOVE THIS BLANK LINE
#############################################################################
cat local.cfg
echo
cat ../defaults.cfg.template
echo
cat packages.cfg
echo
include ../post.chroot.get_VBoxGuestAdditions.cfg
include ../post.chroot.setup_root_auth_keys.cfg
include ../post.chroot.setup_ntpd.cfg
include ../post.chroot.interactive.cfg
include ../post.nochroot.setup_builder.cfg
include ../post.nochroot.interactive.cfg

echo
cat ../pre.interactive-n-download.cfg

#cat defaults.cfg.template

