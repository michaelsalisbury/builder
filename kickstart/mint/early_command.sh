#!/bin/sh

main(){
	explore "$@" 1>> /root/root/early_command_explore.log 2>> /root/root/early_command_explore.log
	#interactive
	#count_down 5
	#interactive 6
	count_down 15
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

