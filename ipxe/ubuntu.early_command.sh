#!/bin/sh

main(){
	# SOURCE common functions
	source_funcs common_funcs

	# Fix Waiting for Network
	chroot_configure_staticip     /root

	# TESTING; setup DNS and Apt-Cache-Proxy
	#chroot_fix_wait_for_net       /root
	#chroot_enable_dns             /root
	#chroot_enable_apt_cache_proxy /root
	chroot_apt_get                /root -y install vim hwinfo ncdu apt-file software-properties-common terminator rdesktop
	chroot                        /root /usr/bin/apt-file update

	chroot_profile_d ${pass_env_to_live} aliases.sh #alias rdesktop.DLPBMM1-VB='rdesktop 10.173.119.93 -u mi164210 -d cos -T Win7-x86_64 -k en-us -r clipboard:PRIMARYCLIPBOARD -x 0x81 -z -N -a 32 -g 1020x1227'
	chroot_profile_d ${pass_env_to_live} aliases.sh alias rdesktop.DLPBMM1-VB.hd='rdesktop 10.173.119.78 -u mi164210 -d cos -T Win7-x86_64 -k en-us -r clipboard:PRIMARYCLIPBOARD -r sound=local -x 0x81 -z -N -a 32 -g 1980x1020 &'
	chroot_profile_d ${pass_env_to_live} aliases.sh alias rdesktop.DLPBMM1-VB.ld='rdesktop 10.173.119.78 -u mi164210 -d cos -T Win7-x86_64 -k en-us -r clipboard:PRIMARYCLIPBOARD -r sound=local -x 0x81 -z -N -a 32 -g 1333x768 &'
	chroot_profile_d ${pass_env_to_live} aliases.sh alias rdesktop.DLPBMM1-VB.xga='rdesktop 10.173.119.78 -u mi164210 -d cos -T Win7-x86_64 -k en-us -r clipboard:PRIMARYCLIPBOARD -r sound=local -x 0x81 -z -N -a 32 -g 1024x768 &'
	chroot_profile_d ${pass_env_to_live} aliases.sh alias rdesktop.DLPBMM1-VB.sxga='rdesktop 10.173.119.78 -u mi164210 -d cos -T Win7-x86_64 -k en-us -r clipboard:PRIMARYCLIPBOARD -r sound=local -x 0x81 -z -N -a 32 -g 1280x1024 &'

	#pause_install_early /tmp/early-command-pause -n 30 .. /tmp/early-command-pause ..
}
source_funcs(){
        # SOURCE script file path is relative to the seed file in ${url}
        local SOURCE="$1"
        #echo eval \"\$\(wget -O - ${url%/*}/${SOURCE}\)\"
        eval "$(wget -q -O - ${url%/*}/${SOURCE})"
}

main "$@"
