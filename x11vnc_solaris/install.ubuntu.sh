#!/bin/bash
function main(){
	local version=`echo "${latest}" | head -1 | xargs dirname`
	local version_dir="/etc/${NAME}/${version}"
	
	# Verify that currect version is latest
	# If an update is need then re-download and re-run install
	if ! VERSION_IS_CURRENT; then
		echo Version not current, downloading...
		DOWNLOAD_UPDATE
		return
	fi

	# Move install into etc if nessisary and re-run install
	if ! IS_IN_ETC; then
		echo Version not in etc, moving...
		MOVE_TO_ETC
		return
	fi

	# Install dependencies
	echo Installing Depndencies...
	apt-get ${aptopt} install x11vnc xinetd netcat-openbsd \
				  xfonts-base xfonts-100dpi xfonts-75dpi \
				  xfonts-biznet-base xfonts-biznet-100dpi xfonts-biznet-75dpi

	# Update tigervnc in /opt
	echo Installing TigerVNC...
	rm   -rf /opt/TigerVNC
	cd       "${version_dir}"
	tar -zxf "${version_dir}"/tigervnc-Linux-`uname -m`-*.tar.gz
	cp   -rf "${version_dir}"/opt/* /opt/.
	rm   -rf "${version_dir}"/opt/
	ln   -sf /opt/TigerVNC/bin/* /usr/bin/.

	# Update major scripts
	echo Installing/Updating scripts...
	local major=""
	for major in ${majors}; do
		cp -f "${version_dir}/${major}" /etc/x11vnc/.
	done

	# Update xinetd configs and re-start xinetd
	echo Installing/Updating xinetd...
	local xinetd=""
	for xinetd in vncserver x11vnc; do
		local newXinetd="${version_dir}/xinetd.${xinetd}"
		local oldXinetd="/etc/xinetd.d/${xinetd}"
		if ! diff     "${oldXinetd}" "${newXinetd}" &>/dev/null; then
			[  -f "${oldXinetd}" ] &&\
			cp    "${oldXinetd}" "${newXinetd}".bk_`date "+%s"`
			cp -f "${newXinetd}" "${oldXinetd}"
			stop xinetd
		fi
	done
	status xinetd | grep -q "^xinetd stop/waiting$" && start xinetd

	# verify that root imports command aliases
	echo Sourcing command aliases for root...
	local root_home=$(grep ^root /etc/passwd | cut -d: -f6)
	local alias_entry_header="# Import ${NAME} command aliases"
	if ! grep "^${alias_entry_header}$" "${root_home}/.bashrc" &>/dev/null; then
		cat <<-ENTRIES >> "${root_home}/.bashrc"
			${alias_entry_header}
			[ -f /etc/${NAME}/aliases ] && . /etc/${NAME}/aliases
		ENTRIES
	fi
	cp -f "${version_dir}/aliases" "/etc/${NAME}/".

	# Install or skip allowed users files for vncserver and x11vnc
	echo Installing or skipping allowed users config files...
	for xinetd in vncserver x11vnc; do
		if [ -f "/etc/${NAME}/allowed.${xinetd}" ]; then
			echo Config file \""allowed.${xinetd}"\" already exists\!
		else
			cp -f "${version_dir}/allowed.${xinetd}" "/etc/${NAME}/".
		fi
	done
			
}
function MOVE_TO_ETC(){
	# Dependant on GLOBAL var "NAME"
	local latest=`GET_LATEST`
	local version=`echo "${latest}" | head -1 | xargs dirname`
	local version_dir="/etc/${NAME}/${version}"
	rm    -rf "${version_dir}"
	mkdir  -p "${version_dir}"
	cd        "${version_dir}"

	# find and copy compressed package
	if   cp -f "${BASH_SRCDIR}/${version}/${version}".tgz_* .; then
		# copy successfull
		echo -n
	elif cp -f "${BASH_SRCDIR}/${version}".tgz_* .; then
		# copy successfull
		echo -n
	else
		# source
		DOWNLOAD_UPDATE
		return
	fi

	cat "${version}".tgz_* | tar -zxf -
	./"${BASH_SRCNAME}"
	return
}
function IS_IN_ETC(){
	# Dependant on GLOBAL var "NAME"
	local latest=`GET_LATEST`
	local version=`echo "${latest}" | head -1 | xargs dirname`
	local version_dir="/etc/${NAME}/${version}"
	[ "${BASH_SRCDIR}" == "${version_dir}" ]
}
function DOWNLOAD_UPDATE(){
	# Dependant on GLOBAL var "NAME"
	local latest=`GET_LATEST`
	local version=`echo "${latest}" | head -1 | xargs dirname`
	local version_dir="/etc/${NAME}/${version}"

	rm    -rf "${version_dir}"
	mkdir  -p "${version_dir}"
	cd        "${version_dir}"
	local part=""
	for part in ${latest}; do
		wget "${http}/${part}"
	done
	cat * | tar -zxvf -
	./"${BASH_SRCNAME}"
	return
}
function VERSION_IS_CURRENT(){
	local LATEST="${BASH_SRCDIR}/LATEST.TXT"
	[ -f "${LATEST}" ] &&\
	diff "${LATEST}" <(GET_LATEST) &>/dev/null
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
	Xcommon-functions.sh
	Xvnc-dynamic.sh
	x11vnc.sh
	xstartup
EOE

main "$@"
