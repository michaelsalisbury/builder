#!/bin/bash

function main(){
	setup_Configure_SSH
}
function setup_Configure_SSH(){
	#desc SSH: disable GSSAPIAuth, UseDNS, ecdsa keys
	# Disable GSSAPIAuthentication
        sed /etc/ssh/sshd_config -i \
		-e '\|^[^#]*GSSAPIAuthentication[[:space:]]\+|s|^|#|'\
		-e '$a\GSSAPIAuthentication no'
	# Disable DNS verification
        sed /etc/ssh/sshd_config -i \
		-e '\|^[^#]*UseDNS|s|^|#|'\
		-e '$a\UseDNS no'
	# Disable HostKey /etc/ssh/ssh_host_ecdsa_key
        sed /etc/ssh/sshd_config -i \
		-e '\|^[^#]*HostKey[[:space:]]\+/etc/ssh/ssh_host_ecdsa_key|s|^|#|'

	# Restart service
	stop ssh
	sleep 1
	start ssh
}
main "$@"
