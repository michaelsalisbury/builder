#!/bin/sh

url=$(dmesg | grep "Kernel command line" | tr \  \\n | sed -n 's/^url=//p')
IP=$(dmesg | grep "Kernel command line" | tr [:space:] \\n | awk -F/ '/^url=/{print $3}' | xargs -i@ echo http://@/kickstart)
USER=$(wget -q -O - ${url} | awk '/username/{print $NF}')
HTTP=${url%/*}
SEED=${url##*/}
FUNC=$(ps -fC sh | sed -n "s!.*${HTTP}/\([^ ]\+\).*!\1!p")
LOGS="/target/root/${FUNC%.*}"

main(){
	explore "$@"	2>&1 | tee -a ${LOGS}_explore.log 
	count_down 20
	mkdir /target/root/explore
	cp -vf /root/root/* /target/root/explore/.
	interactive 8
	apt_update
	apt_install prep
	apt_install packages.cfg
	setup_sudo ${USER}
	setup_repos
	#apt_install prep2
	count_down 15
}
setup_sudo(){
	local USER=$1
	local FILE='/target/etc/sudoers.d/admins'
	echo "${USER} ALL=(ALL) NOPASSWD: ALL" > ${FILE}
	chmod 440 ${FILE}
}
setup_repos(){
	/usr/sbin/chroot /target /bin/bash << BASH 2>&1 |\
			tee -a ${LOGS}_repos.log
	# Add Google Chrome Repo
	echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > \
	"/etc/apt/sources.list.d/google-chrome.list"
	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -

	# Add Adobe Repo
	local list='/etc/apt/sources.list.d/canonical_Adobe.list'
	local http='http://archive.canonical.com/ubuntu'
	local do_release=\${lsb_release -sc}
	rm -f "\${list}"
	case \${do_release} in
		saucy)	do_release=quantal;;
		raring)	for deb in deb deb-src; do
				echo \${deb} \${http} \${do_release} partner >> "\${list}"
			done
			do_release=quantal;;
	esac
	for repo in "" -updates -security -backports; do
		for deb in deb deb-src; do
			echo \${deb} \${http} \${do_release}\${repo} partner >> "\${list}"
		done
	done
	
	# Oracle Java
	add-apt-repository -y ppa:webupd8team/java

	# Add X2GO Repos
	add-apt-repository -y ppa:x2go/stable

	# Add Grub Customizer Repos
	add-apt-repository -y ppa:danielrichter2007/grub-customizer

	sleep 5
	apt-get update
	sleep 5
	apt-get -q -y install apt-file dlocate
	sleep 5
	apt-file update
BASH
}
apt_install_prep(){
	cat << EOE
		#[prep]#
		vim
		ntp
		git
		lsof iotop iftop
		expect expect-dev
		terminator multitail
		#[screen]#
		screen byobu
		incron
		bc
		xterm
		hwinfo ethtool ipcalc smartmontools jockey-common
EOE
}
apt_update(){
	/usr/sbin/chroot /target /bin/bash << BASH 2>&1 |\
			tee -a ${LOGS}_apt-update.log
		apt-get update
BASH
}
apt_fix(){
	/usr/sbin/chroot /target /bin/bash << BASH 2>&1 |\
			tee -a ${LOGS}_apt-fix.log
		apt-get -y -q -f install
BASH
}
apt_install(){
	local SECTION_NAME PKGS NAME=$1
	get_package_list ${NAME} |\
	while read SECTION_NAME PKGS; do
		apt_install_chroot ${SECTION_NAME} ${PKGS}
	done
}
apt_install_chroot(){
	local NAME=$1
	shift
	local PKGS="$*"
	echo "# ${NAME} ###################################################"
	echo "# ${PKGS}"
	echo
	/usr/sbin/chroot /target /bin/bash << BASH 2>&1 |\
			tee -a ${LOGS}_apt-install-${NAME}.log
		echo ${PKGS}
		echo
		apt-get -y -q install ${PKGS}
BASH
}
get_package_list(){
	local NAME=$1
	if wget_url_is_live ${HTTP}/${NAME}; then
		wget -O - ${HTTP}/${NAME} 2>/dev/null | format_package_list
	else
		apt_install_${NAME} 2>/dev/null	| format_package_list
	fi
}
format_package_list(){
	sed 's/.*\([[][^]]\+\).*/\1/;s/[#%].*//'|\
	xargs echo				|\
	sed 's/[[]/\n/g;s/\n//'			|\
	grep ""
}
wget_url_is_live(){
	local url=$1
	wget -q --spider ${url} 2>/dev/null
	return $?
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
	echo
	echo .url :: ${url}
	echo . IP :: ${IP}
	echo USER :: ${USER}
	echo HTTP :: ${HTTP}
	echo SEED :: ${SEED}
	echo FUNC :: ${FUNC}
	echo LOGS :: ${LOGS}
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
	/target/bin/bash
	#/bin/sh

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

main "$@" 2>&1 | tee -a ${LOGS}.log
