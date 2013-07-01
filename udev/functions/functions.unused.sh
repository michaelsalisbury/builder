#!/bin/bash
function LOG_OLD(){
	local LOG_="${BASH_SRCDIR}"/$(basename "${BASH_SRCNAME}" .sh).log
	local LOG_=${LOG:-${LOG_}}
	(( ${#@} > 0 )) && echo "$@" >> "${LOG_}"
	read -t 0 -N 0 && cat >> "${LOG_}" 2>&1
	echo ${FUNCNAME} >> "${LOG_}"
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
###########################################################################################
######################################################################## ASSOCIATIVE ARRAYS
function GET_DEVICE_SIZE_(){
	# set arg :: declare associative array :: fill if empty :: return value
	local DEV=${1:-${DEVICE}}
	declare -A DEVICE_SIZE
	(( ${#DEVICE_SIZE[${DEV}]} > 0 )) || DEVICE_SIZE[${DEV}]=$(GET_DEVICE_SIZE ${DEV})
	echo ${DEVICE_SIZE[${DEV}]}
}
function GET_DEVICE_INTERFACE_(){
	# set arg :: declare associative array :: fill if empty :: return value
	local DEV=${1:-${DEVICE}}
	declare -A DEVICE_INTERFACE
	(( ${#DEVICE_INTERFACE[${DEV}]} > 0 )) || DEVICE_INTERFACE[${DEV}]=$(GET_DEVICE_INTERFACE ${DEV})
	echo ${DEVICE_INTERFACE[${DEV}]}
}
function GET_DEVICE_USB_ID_(){
	# set arg :: declare associative array :: fill if empty :: return value
	local DEV=${1:-${DEVICE}}
	declare -A DEVICE_USB_ID
	(( ${#DEVICE_USB_ID[${DEV}]} > 0 )) || DEVICE_USB_ID[${DEV}]=$(GET_DEVICE_USB_ID ${DEV})
	echo ${DEVICE_USB_ID[${DEV}]}
}
function GET_DEVICE_SERIAL_(){
	# set arg :: declare associative array :: fill if empty :: return value
	local DEV=${1:-${DEVICE}}
	declare -A DEVICE_SERIAL
	if ! (( ${#DEVICE_SERIAL[${DEV}]} > 0 )); then
 		case "${DEVICE_INTERFACE[${DEV}]}" in
			ata|scsi)	DEVICE_SERIAL[${DEV}]=$(GET_DEVICE_HDD_SERIAL ${DEV});;
			usb)		DEVICE_SERIAL[${DEV}]=$(GET_DEVICE_USB_SERIAL ${DEVICE_USB_ID[${DEV}]});;
		esac
	fi
	echo ${DEVICE_SERIAL[${DEV}]}
}
function GET_DEVICE_MAN_(){
	# set arg :: declare associative array :: fill if empty :: return value
	local DEV=${1:-${DEVICE}}
	declare -A DEVICE_MAN
	if ! (( ${#DEVICE_MAN[${DEV}]} > 0 )); then
 		case "${DEVICE_INTERFACE[${DEV}]}" in
			ata|scsi)	DEVICE_MAN[${DEV}]=$(GET_DEVICE_HDD_MAN ${DEV});;
			usb)		DEVICE_MAN[${DEV}]=$(GET_DEVICE_USB_MAN ${DEVICE_USB_ID[${DEV}]});;
		esac
	fi
	echo ${DEVICE_MAN[${DEV}]}
}
function GET_DEVICE_PRODUCT_(){
	# set arg :: declare associative array :: fill if empty :: return value
	local DEV=${1:-${DEVICE}}
}
###########################################################################################
###########################################################################################
function GET_DEVICE_DETAIL(){
	# dependant on global variables; DEVICE_DETAIL, DEVICE
	local DEV=${1:-${DEVICE}}

	IS_DEVICE_REAL ${DEV}

	declare -A DEVICE_DETAIL

	if [ -z "${DEVICE_DETAIL[${DEV}]}" ];then
		DEVICE_DETAIL[${DEV}]=$(fdisk -l /dev/${DEV} |\
			sed -n "\|^Disk[[:space:]]\+/dev/${DEV}:[[:space:]]|p" |\
			cut -d, -f1)
	fi	
	echo ${DEVICE_DETAIL[${DEV}]} |\
	tee -a >(${DEBUG} && xargs echo ${FUNCNAME} :: >> "${LOG}") |\
	grep ""
	(( $? > 0 )) && { echo ERROR \"${FUNCNAME}\" >> "${LOG}"; EXIT 1; }
}










