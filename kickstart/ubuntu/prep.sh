#!/bin/bash
##############################################################################
echo Setting up initial softlinks
ln -s ../../../builder .
ln -s ../../../functions .
ln -s ../../../defaults .
ln -s ../../../deploy_ubuntu deploys
ln -s ../preseed .
ln -s ../DEB .
ln -s ../wget* .
##############################################################################
echo Copying kickstart templates
read -d $'' cfgs << END-OF-LIST
	local.cfg
	defaults.cfg
	packages.cfg
	packages.gnome.cfg
	packages.kde.cfg
END-OF-LIST
for cfg in $cfgs; do [ ! -e ${cfg} ] && cp ../${cfg}.template ${cfg}; done
##############################################################################
echo Copying kickstart post scripts
read -d $'' cfgs << END-OF-LIST
	post.chroot.setup_workstation_wo-Proxy.cfg
	post.chroot.setup_workstation_w-ProxyC.cfg
	post.chroot.setup_workstation_w-Proxy.cfg
	post.chroot.setup_runonce.cfg
END-OF-LIST
for cfg in $cfgs; do [ ! -e ${cfg} ] && cp ../${cfg} .; done
##############################################################################
echo Copying preseed templates
read -d $'' cfgs << END-OF-LIST
	local
END-OF-LIST
for cfg in $cfgs; do [ ! -e ${cfg}.preseed ] && cp ../preseed/preseed.${cfg}.template ${cfg}.preseed; done
##############################################################################
echo Copying CGI templates
read -d $'' cfgs << END-OF-LIST
	ks.cgi
	preseed.cgi
END-OF-LIST
for cfg in $cfgs; do [ ! -e ${cfg} ] && cp ../${cfg}.template ${cfg}; done
