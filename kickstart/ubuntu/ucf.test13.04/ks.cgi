#!/bin/bash
function include(){
	echo '#############################################################################'
	cat $1
	echo
}
echo "Content-Type: text/plain"
echo # DO NOT REMOVE THIS BLANK LINE
#############################################################################
include local.cfg
include ../defaults.cfg.template
include ../packages.cfg.template
#include ../packages.gnome.cfg.template
#include ../packages.kde.cfg.template

#############################################################################
include ../post.nochroot.setup_builder.cfg
#include ../post.chroot.setup_VBoxGuestAdditions.cfg
include ../post.chroot.setup_misc.cfg
include ../post.chroot.setup_root_auth_keys.cfg
include ../post.chroot.setup_ntpd.cfg
include ../post.chroot.setup_workstation_wo-Proxy.cfg
include ../post.chroot.setup_workstation_w-Proxy.cfg
#include ../post.chroot.setup_workstation_w-ProxyC.cfg
include ../post.chroot.setup_runonce.cfg
#include ../post.chroot.interactive.cfg
#include ../post.nochroot.interactive.cfg

#############################################################################
#cat ../pre.interactive-n-download.cfg
#cat ../pre.interactive.cfg
cat ../pre.download.cfg
