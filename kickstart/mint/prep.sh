#!/bin/bash
##############################################################################
echo Setting up initial softlinks
ln -s ../../../builder .
ln -s ../../../functions .
ln -s ../../../defaults .
ln -s ../../../deploy_ubuntu deploys
ln -s ../preseed .
#ln -s ../DEB .
ln -s ../wget* .
##############################################################################
echo Copying command templates
read -d $'' cfgs << END-OF-LIST
	early_command.sh
	success_command.sh
END-OF-LIST
for cfg in $cfgs; do [ ! -e ${cfg} ] && cp ../${cfg}.template ${cfg}; done
##############################################################################
echo Copying kickstart post scripts
read -d $'' cfgs << END-OF-LIST
	post.chroot.setup_workstation_wo-Proxy.cfg
	post.chroot.setup_workstation_w-Proxy.cfg
	post.chroot.setup_runonce.cfg
END-OF-LIST
#for cfg in $cfgs; do [ ! -e ${cfg} ] && cp ../${cfg} .; done
##############################################################################
echo Copying preseed templates
read -d $'' cfgs << END-OF-LIST
	mint.seed
END-OF-LIST
for cfg in $cfgs; do [ ! -e ${cfg}.preseed ] && cp ../preseed/${cfg}.template ${cfg}; done
##############################################################################
echo Copying CGI templates
read -d $'' cfgs << END-OF-LIST
	success_command.cgi
END-OF-LIST
for cfg in $cfgs; do [ ! -e ${cfg} ] && cp ../${cfg}.template ${cfg}; done
