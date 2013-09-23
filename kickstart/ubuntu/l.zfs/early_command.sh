#!/bin/sh

IP=$(echo ${url} | cut -d/ -f3)
HTTP=${url%/*}
SEED=${url##*/}
FUNC=$(ps -w | sed -n "\|sed|d;s|.*${HTTP}/\([^ ]\+\).*|\1|p")
LOGS="/root/root/${FUNC%.*}"
USER=$(wget -q -O - ${url} | awk '/username/{print $NF}')

main(){
	explore "$@" 2>&1 | tee -a ${LOGS}_explore.log
	wget_tgz ${HTTP}/scripts.cgi /root/scripts
	#apt_get -y install vim
	profile
	runonce
	#partman
	#dpkg_info
	#interactive 8
	#count_down 5
	#interactive 6
	count_down 5
}
chroot_mount(){
	mount --bind /dev  /root/dev
	mount --bind /sys  /root/sys
	mount --bind /proc /root/proc
}
chroot_umount(){
	umount /root/dev
	umount /root/sys
	umount /root/proc
}
chroot_enable_dns(){
	echo nameserver ${IP} > /root/etc/resolv.conf
}
apt_get(){
	chroot_enable_dns
	chroot_mount
	#chroot /root /usr/bin/apt-get update
	chroot /root /usr/bin/apt-get $@
	chroot_umount
}
profile(){
	cat << PROFILE >> /root/etc/profile.d/aliases.sh
export url=${url}
export IP=${IP}
export HTTP=${HTTP}
export SEED=${SEED}
PROFILE
}
runonce(){
	wget  -O /root/etc/run_once ${HTTP}/run_once
	rm    -f /root/etc/rc.local     
	wget  -O /root/etc/rc.local ${HTTP}/rc.local
	chmod +x /root/etc/rc.local
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
	count=$1
	while [ $count -ge 0 ]
	do
		sleep .5
		echo -n $count.
		count=$(( count - 1 ))
	done
	echo	
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
interactive2(){
	echo	
}
interactive(){
	tty
	echo $$
	count_down 10
	tty_num=$1
	tty_dev="/dev/tty$tty_num"
	exec < $tty_dev > $tty_dev 2> $tty_dev
	chvt $tty_num

	# Interact with the install
	echo Welcome to your kickstart pre instalation interactive shell...
	echo There is job control hence Ctrl-c will not work.
	echo Jump to tty2 or tty3 for job control.  Ctrl + Alt + F2'|'F3.
	/bin/sh

	# Then switch back to Anaconda on the first console
	chvt 1
	exec < /dev/tty1 > /dev/tty1 2> /dev/tty1
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

