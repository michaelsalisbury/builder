#!/bin/sh

#LOGS="/target/root/success_command"
url=$(ps -ef | sed -n "\|sed|d;\|log-output|d;s|.*\(http[^ ]\+\).*|\1|p")
HTTP=${url%/*}
FUNC=${url##*/}
LOGS="/target/root/${FUNC%.*}"
USER=$(wget -q -O - ${url} | awk '/username/{print $NF}')

main(){
	explore "$@"	1>> ${LOGS}_explore.log \
			2>> ${LOGS}_explore.log
	count_down 10
	apt_update
	apt_install prep
	apt_install packages.cfg
	#apt_install prep2
	count_down 15
	interactive 8
}
apt_update(){
	/usr/sbin/chroot /target /bin/bash << BASH	\
			1>> ${LOGS}_apt-update.log	\
			2>> ${LOGS}_apt-update.log
		apt-get update
BASH
}
apt_fix(){
	/usr/sbin/chroot /target /bin/bash << BASH	\
			1>> ${LOGS}_apt-fix.log		\
			2>> ${LOGS}_apt-fix.log
		apt-get -y -q -f install
BASH
}
wget_package_list(){
	local NAME=$1
	if wget -q -s ${HTTP}/${NAME} &>/dev/null; then
		wget -O - ${HTTP}/${NAME}		|\
		sed '/%/d;s/.*\(\[.*\)\].*/\1/;s/#.*//'	|\
		tr \\n ' '				|\
		tr \[ \\n				|\
		sed '1d;$a\'
	else
		echo
	fi
}
apt_install(){
	local SECTION PKGS NAME=$1
	if wget -q -s ${HTTP}/${NAME} &>/dev/null; then
		wget_package_list ${NAME} |\
		while read SECTION PKGS; do
			apt_install_chroot ${SECTION} ${PKGS}
		done
	else
		apt_install_chroot ${NAME} $(apt_install_${NAME} | sed 's/#.*//')
	fi
}
apt_install_chroot(){
	local NAME=$1
	shift
	local PKGS=$*
		/usr/sbin/chroot /target /bin/bash << BASH		\
				1>> ${LOGS}_apt-install-${NAME}.log	\
				2>> ${LOGS}_apt-install-${NAME}.log
			echo ${PKGS} 
			echo
			apt-get -y -q install ${PKGS}
BASH
}

apt_install_prep(){
	cat << EOE
		vim
		ntp
		git
		lsof iotop iftop
		expect expect-dev
		terminator multitail
		screen byobu
		incron
		bc
		xterm
		hwinfo ethtool ipcalc smartmontools jockey-common
EOE
}
apt_install_prep2(){
	cat << EOE 
		# debian package managment helpers
		tasksel apt-file dlocate software-properties-common
		aptitude wajig
		debconf debconf-utils
		# gnome and unity dekstop registry manipulation
		gconf-editor
		# gnome and unity desktop visual manipulation
		compizconfig-settings-manager
		# gnome fallback desktop
		# gnome-session-fallback
		# cifs
		samba cifs-utils winbind
		# sshfs
		fuse-utils sshfs
		# vnc
		x11vnc xinetd netcat-openbsd

		# VPN
		openconnect

		# compression
		p7zip p7zip-full pigz unrar-free

		# Remote connections
		remmina remmina-plugin-nx remmina-plugin-rdp remmina-plugin-vnc

		# pdf
		okular
		cups-pdf

		# pidgin
		pidgin pidgin-plugin-pack pidgin-sipe pidgin-themes pidgin-twitter pidgin-facebookchat pidgin-encryption pidgin-librvp pidgin-extprefs

		# programming
		build-essential
		mpich2 gfortran cfortran gromacs tkgate
EOE
}
interactive_sh(){
	# Interact with the install
	echo Welcome to your kickstart pre instalation interactive shell...
	echo There is job control hence Ctrl-c will not work.
	echo Jump to tty2 or tty3 for job control.  Ctrl + Alt + F2'|'F3.
	/bin/sh
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
}
interactive(){
	tty
	echo $$
	count_down 30
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

