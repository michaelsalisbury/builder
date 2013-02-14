#!/bin/bash
echo Setting up initial softlinks
ln -s ../../../builder .
ln -s ../../../functions .
ln -s ../../../defaults .
ln -s ../../../deploy_ubuntu deploys
ln -s ../DEB .
ln -s ../wget* .
echo Copying kickstart templates
cp                ../local.cfg.template    local.cfg
cp             ../defaults.cfg.template defaults.cfg
cp             ../packages.cfg.template packages.cfg
cp ../post.chroot.setup_workstation_wo.cfg post.chroot.setup_workstation.cfg
cp     ../post.chroot.setup_runonce.cfg post.chroot.setup_runonce.cfg
echo Copying preseed templates
cp    ../preseed/preseed.local.template    local.preseed
echo Copying CGI templates
cp                  ../ks.cgi.template        ks.cgi
cp     ../preseed/preseed.cgi.template   preseed.cgi
