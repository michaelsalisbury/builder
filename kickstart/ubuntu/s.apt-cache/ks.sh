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
echo '#############################################################################'
cat ../post.chroot.get_VBoxGuestAdditions.cfg
cat ../post.chroot.setup_root_auth_keys.cfg
cat ../post.chroot.setup_ntpd.cfg
cat ../post.chroot.interactive.cfg
cat ../post.nochroot.setup_builder.cfg
cat ../post.nochroot.interactive.cfg

echo
cat ../pre.interactive-n-download.cfg

#cat defaults.cfg.template

