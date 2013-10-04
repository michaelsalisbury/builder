#!/bin/bash

function main(){
	# Add Google Chrome Repo
	echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > \
	"/etc/apt/sources.list.d/google-chrome.list"
	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -

	# Add Adobe Repo
	local list='/etc/apt/sources.list.d/canonical_Adobe.list'
	local http='http://archive.canonical.com/ubuntu'
	local do_release=$(lsb_release -sc)
	rm -f "${list}"
	case ${do_release} in
		olivia) do_release=quantal;;
		saucy)	do_release=quantal;;
		raring)	for deb in deb deb-src; do
				echo ${deb} ${http} ${do_release} partner >> "${list}"
			done
			do_release=quantal;;
	esac
	for repo in "" -updates -security -backports; do
		for deb in deb deb-src; do
			echo ${deb} ${http} ${do_release}${repo} partner >> "${list}"
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

}

LOG_ROOT="${LOGS:-/root/SEED}"

main "$@" 2>&1 | tee -a "${LOG_ROOT}-setup_repos.log"
