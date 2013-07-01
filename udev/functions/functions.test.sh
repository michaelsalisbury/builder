#!/bin/bash
function LOG(){
	# Dependant on GLOBAL var LOG
	# test first arg for true|false
	if (( ${#1} > 0 )) && [[ "$1" =~ ^(true|false)$ ]]; then
		$1 && shift || return
	fi
	# test GLOBAL var LOG; comment these out for speed
	(( ${#LOG} > 0 )) || { echo ERROR :: ${FUNCNAME} :: Log file not defined \(var LOG\). Log entry cancelled. 1>&2; return; }
	[ -f "${LOG}" ]   || { echo ERROR :: ${FUNCNAME} :: Log file doesn\'t exist.  LOG = ${LOG}.  Log entry cancelled. 1>&2; return; }
	# get args
	local ARGS="$@"
	# LOG piped data
	if readlink /proc/$$/fd/0 | egrep -q "^pipe:" \
	|| read -t 0 -N 0; then
		# Do not remove, this fixes something
		echo -n
		if (( ${#ARGS} > 0 )); then
			# prepend args
			cat 2>&1 | sed "s|^|${ARGS} |" >> "${LOG}"
		else
			# no prepend just log pipe
			cat >> "${LOG}" 2>&1
		fi
	else
		# LOG command line args
		(( ${#ARGS} > 0 )) && echo "${ARGS}" >> "${LOG}"
	fi
}
function SOURCE_CONFIG_GLOBAL_VARS(){
	# Dependant on GLOBAL vars; BASH_SRCDIR, BASH_SRCNAME
	# Dependant on function LOG
	(( ${#1} > 0 )) || { echo ERROR :: ${FUNCNAME} :: CONFIG file arg 1 not defined.  No vars sourced. 1>&2; return; }
	local PROG_NAME=$(basename "${BASH_SRCNAME}" .sh)
	# path is absolute and file exists
	if [ "${1:0:1}" == "/" ] && [ -f "${1}" ]; then
		local config=${1}
	# config is pipe <(cat)
	elif [ "${1}" == "/dev/fd/63" ]; then
		local config=$1
	# config is in same dir as program
	elif [ -f "${BASH_SRCDIR}/$1" ]; then
		local config="${BASH_SRCDIR}/$1"
	# config is in etc
	elif [ -f "/etc/${PROG_NAME}/$1" ]; then
		local config="/etc/${PROG_NAME}/$1"
	# config is in usr local
	elif [ -f "${BASH_SRCDIR}/../etc/${PROG_NAME}/$1" ]; then
		local config="${BASH_SRCDIR}/../etc/${PROG_NAME}/$1"

	else	
		echo ERROR :: ${FUNCNAME} :: File \"$1\" not found. 2>&1
		return
	fi
	LOG ${DEBUG:-false} DEBUG :: ${FUNCNAME} :: config = ${config}
	source <(sed -n "${config}" -f <(cat <<-SED
		/^[[:space:]]*$/d				# delete blank lines
		/^[[:space:]]*#/d				# delete comment lines
		/^[[:space:][:alnum:]\.\/\"\'=_]*$/{		# ensure no command execution
			s/[\"\']//g				# remove punctuation
			s/[[:space:]]*=[[:space:]]*/=\"/	# ammend quotes to =
			s/[[:space:]]*$/\"/			# ammend quotes to $
			s/[[:space:]]\+/ /g			# remove tabs, reduce spaces
			p					# print
		}
	SED
	) | tee >(LOG ${DEBUG:-false} DEBUG :: ${FUNCNAME} ::)
	)
}
function GET_CONFIG_SECTION(){
	# test config file is an accessable file
	if [ -f "${1}" ]; then
		local CONFIG_FILE=$1
		shift
	else
		echo ERROR :: ${FUNCNAME} :: Config file \"${1}\" is not accesable. No section returned. 1>&2
		return 1
	fi
	# set SECTION title
	local SECTION=$*
	# test that SECTION title was supplied
	if ! (( ${#SECTION} > 0 )); then
		echo ERROR :: ${FUNCNAME} :: Section name not supplied.  No section returned. 1>&2
		return 1
	fi
	# DEBUG
	LOG ${DEBUG:-false} DEBUG :: ${FUNCNAME} :: SECTION[${SECTION}] CONFIG_FILE[${CONFIG_FILE}]
	# return config section data
	cat <<-SED | sed -n -f <(cat) "${CONFIG_FILE}" | tee >(LOG ${DEBUG:-false} DEBUG :: ${FUNCNAME} ::)
		/[[:space:]]*\[ ${SECTION} \]/,/[[:space:]]*\[/{
			/[[:space:]]*\[/d	# delete first and last line
			/^$/d			# delete empty lines
			/^[[:space:]]*#/d	# delete comment lines
			s/^\t//			# remove single leading tab char
			p			# print
		}
	SED
}
function SETUP_CONFIG_IF_EMPTY(){
	local SOURCE_CONFIG=$1
	local DESTINATION=$2
	local PROG_NAME=$(basename "${BASH_SRCNAME}" .sh)
	if [ -e "${DESTINATION}" ] && [ ! -f "${DESTINATION}" ]; then
		LOG ERROR :: ${FUNCNAME} :: Destination \"${DESTINATION}\" is not a file. Exiting\!
		EXIT 1
	elif (( $(cat "${DESTINATION}" | wc -c) > 0 )); then
		LOG ${DEBUG:-false} DEBUG :: ${FUNCNAME} :: Destination \"${DESTINATION}\" is not empty.
		return 1
	elif [ -f "${BASH_SRCDIR}/${SOURCE_CONFIG}" ]; then
		SOURCE_CONFIG="${BASH_SRCDIR}/${SOURCE_CONFIG}"
	elif [ -f "/etc/${PROG_NAME}/${SOURCE_CONFIG}" ]; then
		SOURCE_CONFIG="/etc/${PROG_NAME}/${SOURCE_CONFIG}"
	elif [ -f "${BASH_SRCDIR}/../etc/${PROG_NAME}/${SOURCE_CONFIG}" ]; then
		SOURCE_CONFIG="${BASH_SRCDIR}/../etc/${PROG_NAME}/${SOURCE_CONFIG}"
	else
		LOG ERROR :: ${FUNCNAME} :: SOURCE_CONFIG \"${SOURCE_CONFIG}\" can\'t be found. Exiting\!
		EXIT 1
	fi
	LOG ${DEBUG:-false} DEBUG :: ${FUNCNAME} :: SOURCE_CONFIG[${SOURCE_CONFIG}] wrote Destination[${DESTINATION}]
	cat "${SOURCE_CONFIG}" >> "${DESTINATION}"
}
function GET_DEVICE_INTERFACE(){
	local DEV=$(basename "${1}")
	# verify that block device exists
	if ! file "/dev/${DEV}" | grep -q "block special"; then
		LOG ERROR :: ${FUNCNAME} :: DEV[$DEV}] is not a blocl device.
		echo none
		return 1
	fi
	# parse /dev/disk/by-id to find link to DEV
	# link format is [interface]-[manufacture]-[serial]-[part(optional)]
	local path=""
	while read path; do
		if readlink "${path}" | grep -q ${DEV}$; then
			path=$(basename "${path}")
			echo ${path%%-*}
			return 0
		fi
	done < <(ls -1 /dev/disk/by-id/*)
	# return error and none if no link match was found
	echo none
	return 1
}
function SET_DEVICE_HWI_ATTRIBUTES_SHMF(){
	local SHMF="$1"
	cat <<-SED | sed -n -f <(cat) <(hwinfo --block 2>/dev/null) > "${SHMF}"
		/ Disk$/,/^\$/{
			/ Disk$/{h;d}
			/^$/d
			G
			s/\(.*\)\n\([0-9:]*\).*/\2\1/p
		}
	SED
	cat <<-SED | sed -n -f <(cat) "${SHMF}" \
		   | sed -i -f <(cat) "${SHMF}"
		/ SysFS ID: /{
			s|^\([0-9:]\+\)[[:space:]].*/\(sd[a-z]\)$|s/^\1/\2:/|p
		}
	SED
}
function GET_DEVICE_HWI_ATTRIBUTES(){
	local DEV=$(basename "${1}")
	# verify that block device exists
	if ! file "/dev/${DEV}" | grep -q "block special"; then
		LOG ERROR :: ${FUNCNAME} :: DEV[$DEV}] is not a blocl device.
		echo none
		return 1
	fi
	# populate hwinfo shared memory file
	[ -f "/dev/shm/$$${FUNCNAME}" ] || SET_DEVICE_HWI_ATTRIBUTES_SHMF "/dev/shm/$$${FUNCNAME}"
	# return list
	sed -n "s|^${DEV}:[[:space:]]\+||p" "/dev/shm/$$${FUNCNAME}"
	
}
function GET_DEVICE_HWI_ATTRIBUTE(){
	local DEV=$1
	shift
	local ATTRIB=$*
	GET_DEVICE_HWI_ATTRIBUTES ${DEV} |\
	sed -n "/^${ATTRIB}[[:space:]]/p"
}
function GET_DEVICE_HWI_MODEL(){
	eval local ATTRIB=( $(GET_DEVICE_HWI_ATTRIBUTE $1 Model:) )
	echo ${ATTRIB[*]: -1}
}
function GET_DEVICE_HWI_SERIAL(){
	eval local ATTRIB=( $(GET_DEVICE_HWI_ATTRIBUTE $1 Serial ID:) )
	echo ${ATTRIB[*]: -1}
}
function GET_DEVICE_HWI_DEVICE(){
	eval local ATTRIB=( $(GET_DEVICE_HWI_ATTRIBUTE $1 Device:) )
	echo ${ATTRIB[*]: -1}
}
function GET_DEVICE_HWI_SIZE(){
cat <<-SED | sed -n -f <(cat) <(GET_DEVICE_HWI_ATTRIBUTE $1 Size:) | bc
	s/^[^0-9]*//
	s/[^0-9]*$//
	s/[^0-9]\+/ * /gp
SED
}
function FORMAT_TO_TB(){
	local bytes=${1//[^0-9\.]/}
	bytes=$(echo $bytes / 1000^3 | bc)
	echo ${bytes:0: -3}.${bytes: -3} TB
}
function FORMAT_TO_GB(){
	local bytes=${1//[^0-9\.]/}
	bytes=$(echo $bytes / 1000^2 | bc)
	echo ${bytes:0: -3}.${bytes: -3} GB
}
function FORMAT_TO_MB(){
	local bytes=${1//[^0-9\.]/}
	bytes=$(echo $bytes / 1000^1 | bc)
	echo ${bytes:0: -3}.${bytes: -3} MB
}
function FORMAT_TO_KB(){
	local bytes=${1//[^0-9\.]/}
	bytes=$(echo $bytes / 1000^0 | bc)
	echo ${bytes:0: -3}.${bytes: -3} KB
}














