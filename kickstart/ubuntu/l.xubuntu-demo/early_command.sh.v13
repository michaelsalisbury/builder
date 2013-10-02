#!/bin/sh

IP=$(echo ${url} | cut -d/ -f3)
HTTP=${url%/*}
SEED=${url##*/}
FUNC=$(ps -w | sed -n "\|sed|d;s|.*${HTTP}/\([^ ]\+\).*|\1|p")
LOGS="/root/root/${FUNC%.*}"
USER=$(wget -q -O - ${url} | awk '/username/{print $NF}')
APT_CACHE_SERVER=${IP}
APT_CACHE_SERVER="192.168.253.3"

main(){
	explore "$@" 2>&1 | tee -a ${LOGS}_explore.log
	wget_tgz ${HTTP}/scripts.cgi /root/scripts

	pause_install /tmp/early-command-pause -n 30 .. /tmp/early-command-pause ...
	
	#partman
	count_down
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
	interactive          3 chroot /root /bin/bash -i &
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
chroot_mount(){
	local ROOT=$1
	mount --bind /dev  ${ROOT}/dev
	mount --bind /sys  ${ROOT}/sys
	mount --bind /proc ${ROOT}/proc
}
chroot_umount(){
	local ROOT=$1
	umount ${ROOT}/dev
	umount ${ROOT}/sys
	umount ${ROOT}/proc
}
chroot_enable_dns(){
	local ROOT=$1
	echo nameserver ${IP} > ${ROOT}/etc/resolv.conf
}
chroot_enable_apt_cache_proxy(){
	local ROOT=$1
	cat << PROXY  > ${ROOT}/etc/apt/apt.conf.d/01proxy
Acquire::http::Timeout "2";
Acquire::http::Proxy "http://${APT_CACHE_SERVER}:3142";
Acquire::http::Proxy::download.oracle.com "DIRECT";
Acquire::http::Proxy::virtualbox.org "DIRECT";
PROXY
}
chroot_apt_get(){
	local ROOT=$1
	shift
	chroot_mount ${ROOT}
	#chroot /root /usr/bin/apt-get update
	chroot ${ROOT} /usr/bin/apt-get $@
	chroot_umount ${ROOT}
}
chroot_add_apt_repo(){
	local ROOT=$1
	shift
	chroot_mount ${ROOT}
	chroot ${ROOT} /usr/bin/add-apt-repository $@
	chroot ${ROOT} /usr/bin/apt-get update
	chroot_umount ${ROOT}
}
partman(){
	local preseed_partman="preseed.hd.atomic.cfg"
	local preseed_partman="preseed.hd.basic.cfg"
	wget -O /root/tmp/${preseed_partman} ${HTTP}/preseed/${preseed_partman}
	mount --bind /dev /root/dev
	chroot  /root /usr/bin/debconf-set-selections   /tmp/${preseed_partman}
}
dpkg_info(){
	local file_list="/root/root/file_list"
	local file
	ls /root/var/lib/dpkg/info/* > "${file_list}"
	for file in $(ls /root/var/lib/dpkg/info/*.preinst); do
		sed -i "1a\echo \$(date) :: ${file} >> /root/root/preinst.alpha" "${file}"
		sed -i "1a\echo \$(date) :: ${file} >> /root/preinst.beta"       "${file}"
	done
}
wget_tgz(){
	local url=$1
	local dir=$2
	local dsc=$(basename ${dir})
	chroot /root /bin/bash << BASH			\
			1>> ${LOGS}_wget-${dsc}.log	\
			2>> ${LOGS}_wget-${dsc}.log
	mkdir ${dir}
	/usr/bin/wget -O - ${url} |\
	/bin/tar -xz -C ${dir}
BASH
}
count_down(){
	local message="$(echo "$*" | sed 's/[0-9]\+//')"
	local count="$(echo "$*" | sed 's/[^0-9]*\([0-9]\+\).*/\1/')"
	local count=${count:-10}
	while [ $count -ge 0 ]
	do
		sleep .5
		echo -n $count.
		count=$(( count - 1 ))
	done
	echo $message
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
	echo .KCL :: $(dmesg | grep "Kernel com" | tr \  \\n | grep ^url)
}
interactive(){
	local tty_num=$1
	shift
	tty_dev="/dev/tty$tty_num"
	exec $* < $tty_dev > $tty_dev 2> $tty_dev
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

