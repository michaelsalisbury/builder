#!/bin/sh

IP=$(echo http://$(echo ${url} | cut -d/ -f3)/kickstart/mint/s.mint-xfce/mint.seed)
HTTP=${url%/*}
SEED=${url##*/}
FUNC=$(ps -w | sed -n "\|sed|d;s|.*${HTTP}/\([^ ]\+\).*|\1|p")
LOGS="/root/root/${FUNC%.*}"
USER=$(wget -q -O - ${url} | awk '/username/{print $NF}')

main(){
	explore "$@" 2>&1 | tee -a ${LOGS}_explore.log
	wget_tgz ${HTTP}/scripts.cgi /root/scripts
	#interactive 8
	#count_down 5
	#interactive 6
	count_down 15
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

