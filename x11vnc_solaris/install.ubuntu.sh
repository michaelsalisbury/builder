#!/bin/bash
function IS_IN_ETC(){
	# Dependant on GLOBAL var "NAME"
	local latest=`GET_LATEST`
	local version=`echo "${latest}" | head -1 | xargs dirname`
	local version_dir="/etc/${NAME}/${version}"
	[ "${BASH_SRCDIR}" == "${version_dir}" ]
}
function MOVE_TO_ETC{
	local latest=`GET_LATEST`
	local version=`echo "${latest}" | head -1 | xargs dirname`
	local version_dir="/etc/${NAME}/${version}"
	rm    -rf "${version_dir}"
	mkdir  -p "${version_dir}"
	cd        "${version_dir}"

	# FIX THIS use ls ... &>/dev/null
	if [ -d "${BASH_SRCDIR}/${version}" ]; then 
		cp -f "${BASH_SRCDIR}/${version}/${version}".tgz_* .
	elif
		cp -f "${BASH_SRCDIR}/${version}".tgz_* .
	else

	fi
	cat * | tar -zxvf -
	./"${BASH_SRCNAME}"



}
function main(){
	local version=`echo "${latest}" | head -1 | xargs dirname`
	local version_dir="/etc/${NAME}/${version}"
	
	# Verify that currect version is latest
	# If an update is need then re-download and re-run install
	if ! VERSION_IS_CURRENT; then
		DOWNLOAD_UPDATE
		return
	fi

	# Move install into etc if nessisary and re-run install
	if ! IS_IN_ETC; then
		MOVE_TO_ETC
		return
	fi
		rm    -rf "${version_dir}"
		mkdir  -p "${version_dir}"
		cd        "${version_dir}"
		if [ -d "${BASH_SRCDIR}/${version}" ]; then 
			cp -f "${BASH_SRCDIR}/${version}/${version}".tgz_* .
		else
			cp -f "${BASH_SRCDIR}/${version}".tgz_* .
		fi
		cat * | tar -zxvf -
		./"${BASH_SRCNAME}"
		return
	fi

	# Install dependencies
	apt-get ${aptopt} install x11vnc xinetd \
				  xfonts-base xfonts-100dpi xfonts-75dpi \
				  xfonts-biznet-base xfonts-biznet-100dpi xfonts-biznet-75dpi

	# Update tigervnc in /opt
	rm   -rf /opt/TigerVNC
	cd "${version_dir}"
	tar -zxvf "${version_dir}"/tigervnc-Linux-`uname -m`-*.tar.gz
	cp -rvf "${version_dir}"/opt/* /opt/.
	ln -s /opt/TigerVNC/bin/* /usr/bin/.

	# Update major scripts
	local major=""
	for major in ${majors}; do
		cp -f "${version_dir}/${major}" /etc/x11vnc/.
	done

	# Update xinetd configs and re-start xinetd

	# copy config files but don't overwrite  


}
function DOWNLOAD_UPDATE(){
	# Dependant on GLOBAL var "NAME"
	local latest=`GET_LATEST`
	local version=`echo "${latest}" | head -1 | xargs dirname`
	local version_dir="/etc/${NAME}/${version}"

	rm -rf    "${version_dir}"
	mkdir  -p "${version_dir}"
	cd        "${version_dir}"
	local part=""
	for part in ${latest}; do
		wget "${http}/${part}"
	done
	cat * | tar -zxvf -
	./"${BASH_SRCNAME}"
	exit
}
function VERSION_IS_CURRENT(){
	local LATEST="${BASH_SRCDIR}/LATEST.TXT"
	[ -x "${LATEST}" ] &&\
	diff <(GET_LATEST) "${LATEST}" &>/dev/null
}
function GET_LATEST(){
	# deplendant on GLOBAL var "http" and "latest"
	if (( ${#latest} > 0 )); then
		echo "${latest}"
	else
		latest=`wget -O - -o /dev/null "${http}/LATEST.TXT"`
		echo "${latest}"
	fi

}
function canonicalpath(){
	if [ -d $1 ]; then
		pushd $1 > /dev/null 2>&1
		echo $PWD
	elif [ -f $1 ]; then
		pushd $(dirname $1) > /dev/null 2>&1
		echo $PWD/$(basename $1)
	else
		echo "Invalid path $1"
	fi
	popd > /dev/null 2>&1
}
# GLOBAL vars; fully qualified script paths and names
BASH_SRCFQFN=$(canonicalpath "${BASH_SOURCE}")
BASH_SRCNAME=$(basename "${BASH_SRCFQFN}")
BASH_SRCDIR=$(dirname "${BASH_SRCFQFN}")

# Source git repo sudirectory
http='https://raw.github.com/michaelsalisbury/builder/master/x11vnc_solaris'

# Project NAME
NAME='x11vnc'

# Get details of the latest version
latest=`wget -O - -o /dev/null "${http}/LATEST.TXT"`

# Projects major scripts
read -d $'' majors <<-EOE
	Xvnc-dynamic.sh
	x11vnc.sh
	xstartup
EOE

main "$@"
