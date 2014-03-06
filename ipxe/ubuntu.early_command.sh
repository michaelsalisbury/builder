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
	#chroot_apt_get                /root -y install vim hwinfo ncdu apt-file software-properties-common
	#chroot                        /root /usr/bin/apt-file update

	#pause_install_early /tmp/early-command-pause -n 30 .. /tmp/early-command-pause ..
}
source_funcs(){
        # SOURCE script file path is relative to the seed file in ${url}
        local SOURCE="$1"
        #echo eval \"\$\(wget -O - ${url%/*}/${SOURCE}\)\"
        eval "$(wget -q -O - ${url%/*}/${SOURCE})"
}

main "$@"
