#!/bin/sh
#!/bin/dash

LOGS="/root/root/early_command"

main(){
	# SOURCE common functions
	source_funcs common_funcs

	# print to screen some details about the environment
	explore "$@" 2>&1 | tee -a ${LOGS}_explore.log

	# retrieve a folder of files: the cgi file packs tar.gz file fresh so files are always up-to-date
	wget_tgz ${HTTP}/scripts.cgi /root/scripts


	# Add command aliases and exports to the squashfs environment
	chroot_profile_d /root aliases.sh export              url=\"${url}\"
	chroot_profile_d /root aliases.sh export               IP=\"${IP}\"
	chroot_profile_d /root aliases.sh export             HTTP=\"${HTTP}\"
	chroot_profile_d /root aliases.sh export             SEED=\"${SEED}\"
	chroot_profile_d /root aliases.sh export       FIRST_USER=\"${USER}\"
	chroot_profile_d /root aliases.sh export APT_CACHE_SERVER=\"${APT_CACHE_SERVER}\"

	chroot_profile_d /root aliases.sh alias test1=\"wget -q -O - ${HTTP}/test1 \| /bin/bash\"
	chroot_profile_d /root aliases.sh alias test2=\"wget -q -O - ${HTTP}/test2 \| /bin/bash\"

	# tests
	# chroot_enable_apt_cache_proxy
	# partman

	# setup rc.local and a run_once script
	chroot_enable_dns             /root
	chroot_enable_apt_cache_proxy /root
	#chroot_apt_get                /root -y install gnome-terminal
	runonce

	# pause the install process ald allow for command line interaction
	pause_install /tmp/early-command-pause -n 30 .. /tmp/early-command-pause ...

	# pause a few second (default 10) before continuing
	count_down
}
source_funcs(){
	# SOURCE script file path is relative to the seed file in ${url}
	local SOURCE="$1"
	eval "$(wget -O - ${url%/*}/${SOURCE})"
}
runonce(){
	wget  -O /root/etc/run_once ${HTTP}/run_once
	rm    -f /root/etc/rc.local     
	wget  -O /root/etc/rc.local ${HTTP}/rc.local
	chmod +x /root/etc/rc.local
}
pause_install(){
	local install_pause_file="$1"
	shift
	local count_down_opts="$*"
	touch "${install_pause_file}"
	local
	# Setup shell /bin/sh on tty2
	interactive 2 /bin/sh &
	local interactive_PID_sh=$!
	# Setup shell /bin/bash with chroot /root.  Install vim and gdisk first.
	chroot_enable_dns             /root
	chroot_enable_apt_cache_proxy /root
	chroot_apt_get                /root -y install vim gdisk
	chroot_mount                  /root
	interactive          3 chroot /root /bin/bash --login &
	local interactive_PID_bash=$!
	# Inform the user to switch to tty2 or tty3 to explore and effect changes.
	echo
	echo '################################################################'
	echo Welcome to your kickstart pre instalation interactive shell...
	echo Jump to tty2 for /bin/sh to navigate the initramfs
	echo Jump to tty3 for /bin/bash to navigate chroot /root
	echo chroot /root is the squashfs where the LiveCD boots too.
	echo Jump to tty2 or tty3 via Ctrl + Alt + F2'|'F3.
	echo
	echo To continue install rm \"${install_pause_file}\" from tty2
	echo

	# Start wait loop
	while [ -f "${install_pause_file}" ]; do
		count_down ${count_down_opts}
	done
	# kill interactive shells
	kill -9 ${interactive_PID_sh}
	kill -9 ${interactive_PID_bash}
	# umount /root/dev /root/sys /root/proc
	chroot_umount /root
	echo
}
partman(){
	local preseed_partman="preseed.hd.atomic.cfg"
	local preseed_partman="preseed.hd.basic.cfg"
	wget -O /root/tmp/${preseed_partman} ${HTTP}/preseed/${preseed_partman}
	mount --bind /dev /root/dev
	chroot  /root /usr/bin/debconf-set-selections   /tmp/${preseed_partman}
}
explore(){
	date
	echo
	ls -l /
	echo
	ls -l /bin
	echo
	wget --version
	echo
	wget --help
	echo
	env
	echo
	echo .url :: ${url}
	echo . IP :: ${IP}
	echo USER :: ${USER}
	echo HTTP :: ${HTTP}
	echo SEED :: ${SEED}
	echo FUNC :: ${FUNC}
	echo LOGS :: ${LOGS}
	echo PROX :: ${APT_CACHE_SERVER}  
	echo .KCL :: $(dmesg | grep "Kernel com" | tr \  \\n | grep ^url)
}
setup_wget(){
	baseURL=$(sed 's|.*ks=\([^ ]*\)/[^/ ]*.*|\1|p;d' /var/log/syslog | uniq)
	echo          ${baseURL}
	wget -P  /lib ${baseURL}/wget-12.10/libssl.so.1.0.0
	wget -P  /lib ${baseURL}/wget-12.10/libidn.so.11
	wget -P  /tmp ${baseURL}/wget-12.10/wget
	chmod +x /tmp/wget
}
setup_builder(){
	opts="-r -nd -l 1 --cut-dirs 1 -A deb,exp,sh,cfg,sed,crt"
	for f in builder functions defaults deploys DEB preseed; do
		mkdir /tmp/$f
		/tmp/wget $opts -P /tmp/$f/ ${baseURL}/$f/
	done
	env
}

main "$@"

