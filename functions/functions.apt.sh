#!/bin/builder.sh
skip=( false )
step=1
prefix="setup"
source="https://raw.github.com/michaelsalisbury/builder/master/functions/${scriptName}"
#source=http://10.173.119.78/scripts/system-setup/$scriptName

###########################################################################################
#                                                             Repo Support
###########################################################################################
function apt_amend_proxy(){
	local proxyEntry="${1}"
	local proxyConfig=$(egrep -l -R '^Acquire::http::Proxy ' /etc/apt |\
				grep -v '.[0-9]\+.save')
	if ! grep -q "${proxyEntry}" "${proxyConfig}"; then
		sed "${proxyConfig}" -i.`date "+%s"`.save\
		-e "/^Acquire::http::Proxy /a${proxyEntry}"
	fi
}
function apt_search(){
	local help=`cat << END-OF-HELP
---------------------------------------------------------------
-v "regex filter for package version"
-e "extend the search text and decrement till a match is found"
---------------------------------------------------------------
USAGE
apt_search [-v "filter"] [-e "extended package name"] "package name" 
 
END-OF-HELP`
	local OPTIND=
	local OPTARG=
	while getopts "e:hv:" OPTION 
               do case $OPTION in
			v)	local filter=$OPTARG;;
			e)	local ext_search=$OPTARG;;
			h)	echo "${help}"; return 0;;
			?)	;;
		esac
	done
	
	shift $(($OPTIND - 1))
	local search=$1$ext_search
	unset IFS
	#local IFS=$'\ '

	for (( less_char=0; less_char <= ${#ext_search}; less_char++ )); do
		(( $less_char )) 					\
			&& local query=${search:0:-${less_char}}	\
			|| local query=${search}
		apt-cache search $query				|\
		egrep ^$query					|\
		while read pkg desc; do
			apt-cache show $pkg			|\
			egrep ^Version:				|\
			egrep ${filter:-'.*'}			|\
			while read Version version; do
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
	waitAptgetUpdate
	apt-get clean
	waitAptgetUpdate
	apt-get autoclean
	waitAptgetUpdate
	apt-get -y -q update
}
function apt_update_n_upgrade(){
	desc Apt update \& upgrade
	waitAptgetUpdate
	apt-get -y -q update
	waitAptgetInstall
	apt-get -y -q -f install
	waitAptgetInstall
	apt-get -y -q upgrade
}
function apt_clean_update_upgrade(){
	desc Apt clean \& update
	waitAptgetUpdate
	apt-get clean
	waitAptgetUpdate
	apt-get autoclean
	waitAptgetUpdate
	apt-get -y -q update
	waitAptgetInstall
	apt-get -y -q -f install
	waitAptgetInstall
	apt-get -y -q upgrade
}
