#!/bin/builder.sh
skip=( false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/global/$scriptName

###########################################################################################
#                                                             Repo Support
###########################################################################################
function apt_search(){
	local filter=$1
	local search=$2$3
	local ext_search=$3

	for (( less_char=0; less_char <= ${#ext_search}; less_char++ )); do
		(( $less_char )) 					\
			&& local query=${search:0:-${less_char}}	\
			|| local query=${search}
		apt-cache search $query			|\
		egrep ^$search					|\
		while IFS=\  read pkg desc; do
			apt-cache show $pkg			|\
			egrep ^Version:				|\
			grep $latest				|\
			while IFS=\  read Version version; do
				echo ${pkg}=${version}
			done
		done
	done							|\
		sort -u
}

function apt_get_repos(){
        local repo='-'
        local pkg=$1
        (
        echo Name Version Repo
        for ver in `apt-cache show $pkg | egrep ^Version | cut -f2- -d:`
                do
                        repo=`apt-cache showpkg $pkg | sed "s|^$ver (/var/lib/apt/lists/\([^()]*\)).*|\1|p;d"`
                        echo $pkg $ver $repo
                done
        ) | column -t
}
function apt_get_version(){
        local repo=$1
        local pkg=$2
        for ver in `apt-cache show $pkg | egrep ^Version | cut -f2- -d:`
                do
                apt-cache showpkg $pkg | grep $ver | grep $repo &> /dev/null && echo $ver
                done | sort -u
}

function apt_clean_n_update(){
	desc Apt clean \& update
	apt-get clean
	waitAptgetUpdate
	apt-get -y -q update
}
function apt_update_n_upgrade(){
	desc Apt update \& upgrade
	waitAptgetUpdate
	apt-get -y -q update
	waitAptgetInstall
	apt-get -y -q upgrade
}
