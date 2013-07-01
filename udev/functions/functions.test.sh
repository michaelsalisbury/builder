#!/bin/bash
function LOG_OLD(){
	local LOG_="${BASH_SRCDIR}"/$(basename "${BASH_SRCNAME}" .sh).log
	local LOG_=${LOG:-${LOG_}}
	(( ${#@} > 0 )) && echo "$@" >> "${LOG_}"
	read -t 0 -N 0 && cat >> "${LOG_}" 2>&1
	echo ${FUNCNAME} >> "${LOG_}"
}
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
function SOURCE_CONFIG_GLOBAL_VARS_OLD(){
	if [ -f "${BASH_SRCDIR}/${1}" ]; then
		local config="${BASH_SRCDIR}/${1}"
	elif [ -f "${1}" ]; then
		local config=$1
	elif [ "${1}" == "/dev/fd/63" ]; then
		local config=$1
	else
		echo ERROR :: ${FUNCNAME} :: File \"$1\" not found. >> "${LOG}"
		return
	fi
	#cat "${config}" >> "${LOG}"
	source <(sed -n "${config}" -f <(cat <<-SED
		/^[[:space:]]*$/d				# delete blank lines
		/^[[:space:]]*#/d				# delete comment lines
		/^[[:space:][:alnum:]\"\'=_]*$/{		# ensure no command execution
			s/[\"\']//g				# remove punctuation
			s/[[:space:]]*=[[:space:]]*/=\"/	# ammend quotes to =
			s/[[:space:]]*$/\"/			# ammend quotes to $
			s/[[:space:]]\+/ /g			# remove tabs, reduce spaces
			p					# print
		}
	SED
	))
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
function GET_DEVICE_SIZE(){
	local DEV=$(basename "${1}")
	# verify that block device exists
	if ! file "/dev/${DEV}" | grep -q "block special"; then
		LOG ERROR :: ${FUNCNAME} :: DEV[$DEV}] is not a blocl device.
		echo none
		return 1
	fi
	cat <<-SED | sed -n -f <(cat) <(fdisk -l /dev/${DEV})
		\|^Disk[[:space:]]\+/dev/${DEV}[:]|{
			s/^[^:]\+[:][[:space:]]\+\([^,]\+\).*/\1/p
		}
	SED
}
function GET_DEVICE_HDD_SERIAL(){
	echo
}
function GET_DEVICE_HDD_MAN(){
	echo
}
function GET_DEVICE_HDD_PRODUCT(){
	echo
}
function GET_DEVICE_USB_BUS_ID(){
	local DEV=$(basename "${1}")
	# verify that block device exists
	if ! file "/dev/${DEV}" | grep -q "block special"; then
		LOG ERROR :: ${FUNCNAME} :: DEV[$DEV}] is not a blocl device.
		echo none
		return 1
	fi
	# parse /dev/disk/by-id to find link to DEV
	local path x BUS DEVICE SERIAL
	while read path; do
		if readlink "${path}" | grep -q ${DEV}$; then
			path=$(basename "${path}")
			if [ "${path%%-*}" == "usb" ]; then
				while read x BUS x DEVICE x; do
					SERIAL=( $(GET_DEVICE_USB_ATTRIBUTE ${BUS} ${DEVICE} iSerial) )
					if (( ${#SERIAL[1]} > 0 )) \
					&& echo "${path}" | grep -q "${SERIAL[1]}"; then
						echo ${BUS//[^0-9]/} ${DEVICE//[^0-9]/}
						return 0
					fi
				done < <(lsusb)
			fi
			echo ""
			return 1
		fi
	done < <(ls -1 /dev/disk/by-id/*)
}
function GET_DEVICE_USB_ATTRIBUTE(){
	# supply USB device BUS #, DEVICE #, ATTRIBUTE name
	local BUS=${1//[^0-9]/}
	local DEVICE=${2//[^0-9]/}
	local ATTRIBUTE=$3
	lsusb -s ${BUS}:${DEVICE} &>/dev/null || { echo ""; return 1; }
	cat <<-SED | sed -n -f <(cat) <(lsusb -v -s ${BUS}:${DEVICE})
		h							# copy pattern to hold buffer
		s/^[[:space:]]*\([^[:space:]]\+\).*/\1/			# isolate first element
		/${ATTRIBUTE}/{						# match first element
			x						# swap hold buffer back to pattern space
			s/^[[:space:]]*[^[:space:]]\+[[:space:]]\+//	# strip out first element
			p						# print
		}
	SED
}
function GET_DEVICE_USB_MAN(){
	local ATTRIB=( $(GET_DEVICE_USB_ATTRIBUTE $1 $2 iManufacturer) )
	echo ${ATTRIB[*]:1}
}
function GET_DEVICE_USB_SERIAL(){
	local ATTRIB=( $(GET_DEVICE_USB_ATTRIBUTE $1 $2 iSerial) )
	echo ${ATTRIB[*]:1}
}
function GET_DEVICE_USB_PRODUCT(){
	local ATTRIB=( $(GET_DEVICE_USB_ATTRIBUTE $1 $2 idProduct) )
	(( ${#ATTRIB[1]} > 0 )) && echo ${ATTRIB[*]:1} && return 0
	local ATTRIB=( $(GET_DEVICE_USB_ATTRIBUTE $1 $2 iProduct) )
	echo ${ATTRIB[*]:1}
}
function GET_DEVICE_HWINFO_ATTRIBUTE(){
	local DEV=$(basename "${1}")
	shift
	local ATTRIB=$*
	# verify that block device exists
	if ! file "/dev/${DEV}" | grep -q "block special"; then
		LOG ERROR :: ${FUNCNAME} :: DEV[$DEV}] is not a blocl device.
		echo none
		return 1
	fi
	[ -f "/dev/shm/$$${FUNCNAME}" ] || SET_DEVICE_HWINFO_ATTRIBUTES_SHMF "/dev/shm/$$${FUNCNAME}"

	cat <<-SED | sed -n -f <(cat) "/dev/shm/$$${FUNCNAME}"
		/^${DEV}:[[:space:]]\+${ATTRIB}[[:space:]]/p
		#/^${DEV}:/p
	SED
}
function SET_DEVICE_HWINFO_ATTRIBUTES_SHMF(){
	local SHMF="$1"
	cat <<-SED | sed -n -f <(cat) <(hwinfo --block 2>/dev/null) > /dev/shm/$$${FUNCNAME}
		/ Disk$/,/^\$/{
			/ Disk$/{h;d}
			/^$/d
			G
			s/\(.*\)\n\([0-9:]*\).*/\2\1/p
		}
	SED
	cat <<-SED | sed -n -f <(cat) /dev/shm/$$${FUNCNAME} \
		   | sed    -f <(cat) /dev/shm/$$${FUNCNAME} > "${SHMF}"
		/ SysFS ID: /{
			s|^\([0-9:]\+\)[[:space:]].*/\([a-z]\+$\)|s/^\1/\2:/|p
		}
	SED
}













