#!/bin/bash
function main(){
	ACTION=$1
	DEVICE=$2
	local DISPLAY_0_USER=$(GET_DISPLAY_0_USER)
	local DISPLAY_0_HOME=$(GET_DISPLAY_0_HOME)

	# Set GLOBAL VARS
	GET_DEVICE_DETAIL &>/dev/null

	# filter out root; system drive
	IS_DEVICE_ROOT # function exits if positive

	# prompt user to choose tool or disregard
	IFS=: SELECTION=( $(zenity_choose_tool) )

	# exit if user chose cancel or closed dialog
	(( ${SELECTION[0]} == 1 )) && exit

	# set default if next was selected without chooseing a tool
	(( ${#SELECTION[*]} > 1 )) && GET_SELECTION_DETAILS || SET_DEFAULT_SELECTION

	# prompt user to add seconadary device 
	if echo ${SELECTION[2]} | grep -qi "^diag"; then
		DEVICE[1]=$(zenity_choose_second)
	fi

	# prompt user to label task/vm
	IFS=: NAME=( $(zenity_name_task) )

	# exit if user chose cancel or closed dialog
	(( ${NAME[0]} == 1 )) && exit

	# set default name if start vm was selected without entering a name
	(( ${#NAME[*]} > 1 )) || SET_DEFAULT_NAME

	# amend VRDEPORT and DEVICE to NAME[1]
	NAME[1]="${NAME[1]}-${VRDEPORT}.${DEVICE}"

	# set path for vmdk files
	declare -A VMDK
	for DEV in ${DEVICE[*]}; do
		VMDK[${DEV}]="${DISPLAY_0_HOME}/.VirtualBox/udev.${DEV}.${NAME[1]}.vmdk"
	done
	
	# cleanup old primary vmdk files
	for DEV in ${DEVICE[*]}; do
		rm -f "${DISPLAY_0_HOME}/.VirtualBox/udev.${DEV}."*.vmdk
	done

	# cleanup conflicting stale virtual machines
	for DEV in ${DEVICE[*]}; do
		# unregister vm
		cat <<-SU | su - $username -s /bin/bash
			VBoxManage list vms |\
			while read line; do
				eval words=( "\${line}" )
				[[ "\${words[0]}" =~ $(GET_VRDEPORT ${DEV})$ ]] &&\
				VBoxManage unregistervm \${words[1]} --delete
			done
		SU
		# remove rm folder
		rm -rf "${DISPLAY_0_HOME}/.VirtualBox"/*.${DEV}
	done

	# unmount devices
	for DEV in ${DEVICE[*]}; do
		echo
		#umount /dev/${DEV}*
		#umount /dev/${DEV}*
	done

	# create virtualbox raw vmdk files
	for DEV in ${DEVICE[*]}; do
		VBoxManage internalcommands createrawvmdk	\
			-filename "${VMDK[${DEV}]}"		\
			-rawdisk /dev/${DEV}
		chmod a+rw                        "${VMDK[${DEV}]}"
		chown ${DISPLAY_0_USER}.vboxusers "${VMDK[${DEV}]}"
		chmod a+rw                        /dev/${DEV}
		chown ${DISPLAY_0_USER}.vboxusers /dev/${DEV}
	done

	


	
	echo "      name :: "${NAME[*]}
	echo "  name err :: "${NAME[0]}
	echo " selection :: "${SELECTION[*]}
	echo "select err :: "${SELECTION[0]}
	echo "      path :: "$(GET_SELECTION_PATH)
	echo "       mem :: "$(GET_SELECTION_MEM)
	echo "      name :: "${NAME[1]}

	# 

	echo "$@"
}
function IS_DEVICE_ROOT(){
	if awk '/[[:space:]]\/[[:space:]]/{print $1}' /etc/mtab |\
	   grep -q "/dev/${DEVICE}[0-9]\+"; then
		echo SYSTEM DRIVE EXITING
		exit 1
	else
		return 0
	fi
}
function SET_VM(){
	local DISPLAY_0_USER=$(GET_DISPLAY_0_USER)
	local DISPLAY_0_HOME=$(GET_DISPLAY_0_HOME)
	local DISPLAY_0_TOOL_DIR="${DISPLAY_0_HOME}/${TOOL_DIR}"
	local VBM='VBoxManage'
	# prep
	case ${SELECTION[1]} in
		-)	local boot1='net';;
		0)	local boot1='disk';;
		*)	local boot1='dvd'
			local DVD=$(GET_SELECTION_PATH);;
	esac
	# create vm
	cat <<-SU | su - ${DISPLAY_0_USER} -s /bin/bash
		${VBM} createvm --name ${NAME[1]}	\
				--ostype Other		\
				--register
	SU
	# memory
	cat <<-SU | su - ${DISPLAY_0_USER} -s /bin/bash
		${VBM} modifyvm ${NAME[1]} --memory $(GET_SELECTION_MEM)
	SU
	# set boot device
	cat <<-SU | su - ${DISPLAY_0_USER} -s /bin/bash
		${VBM} modifyvm ${NAME[1]} --boot1 ${boot1} \
					   --boot2 none     \
					   --boot3 none     \
					   --boot4 none
	SU
	# set nic
	cat <<-SU | su - ${DISPLAY_0_USER} -s /bin/bash
		${VBM} modifyvm ${NAME[1]} --nic1 bridged        \
					   --cableconnected1 on  \
					   --bridgeadapter1 eth1 \
					   --nictype1 82540EM    \
					   --macaddress1 $(GET_MAC)
	SU
	# set VRDE
	cat <<-SU | su - ${DISPLAY_0_USER} -s /bin/bash
		${VBM} modifyvm ${NAME[1]} --vrde on                  \
					   --vrdeport $(GET_VRDEPORT) \
					   --vrdeauthtype null        \
					   --vrdemulticon on
	SU
	# set ide controler and dvd
	cat <<-SU | su - ${DISPLAY_0_USER} -s /bin/bash
		${VBM} modifyvm ${NAME[1]} --name ${SCTL}	\
					   --add ${SCTL}	\
					   --bootable on
		${VBM} modifyvm ${NAME[1]} --storagectl ${SCTL} \
					   --port 0		\
					   --device 1		\
					   --type dvddrive	\
					   ${DVD:+--medium} "${DVD}"
	SU
	# set disks
	for dev in ${DEVICE[*]}; do
	cat <<-SU | su - ${DISPLAY_0_USER} -s /bin/bash
		${VBM} modifyvm ${NAME[1]} --storagectl ${SCTL}	\
					   --port $(( index++ ))\
					   --device 0		\
					   --type hdd		\
					   --medium "${VMDK[${DEV}]}"
	SU
	done
}
function GET_VRDEPORT(){
	# dependant on global variables; VRDEPORT, DEVICE
	local DEV=${1:-${DEVICE}}
	# get vrdeport; convert the sd disk letter to a number and add to port base
	echo $(( VRDEPORT + $(printf "%d\n" \'${DEV:2}) -99 ))
}
function GET_MAC(){
	# dependant on global variables; MAC
	local DEV=${1:-${DEVICE}}
	# get mac; convert the sd disk letter to a number and add to mac base
	echo ${MAC}$(( 196 - $(printf "%d\n" \'${DEV:2}) ))
}
function zenity_name_task(){
	# dependant on global variables; DEVICE
	local DISPLAY_0_USER=$(GET_DISPLAY_0_USER)
	# get drive size
	local zenityTitle=$(GET_DEVICE_DETAIL)
	# naming instructions
	local zenityText=$(GET_CONFIG_SECTION "${NAMING_INSTRUCTIONS}")

	(
	cat <<-ZENITY | su - ${DISPLAY_0_USER} -s /bin/bash 2>/dev/null
		DISPLAY=${DISPLAY} zenity			\
			--timeout=25			\
			--ok-label="START VM"		\
			--cancel-label="CANCEL"		\
			--title="${zenityTitle// /   }"	\
			--text="${zenityText}"		\
			--entry
		ZENITY
	echo $?:
	) | tac | tr -d '\n'
}
function zenity_choose_second(){
	echo
}
function GET_DEVICE_DETAIL(){
	# dependant on global variables; DEVICE_DETAIL, DEVICE
	if [ -z "${DEVICE_DETAIL}" ];then
		DEVICE_DETAIL=$(fdisk -l /dev/${DEVICE} |\
			sed -n "\|^Disk[[:space:]]\+/dev/${DEVICE}:[[:space:]]|p" |\
			cut -d, -f1)
	fi	
	echo ${DEVICE_DETAIL} |\
	tee -a >(${DEBUG} && xargs echo ${FUNCNAME} :: >> "${LOG}") |\
	grep ""
	(( $? > 0 )) && { echo ERROR \"${FUNCNAME}\" >> "${LOG}"; exit; }
}
function GET_SELECTION_DETAILS(){
	# dependant on global variables; SELECTION
	local LINE=""
	while read LINE; do
                eval IFS=${DIFS} SELECTION=( ${SELECTION[0]} "${LINE}" )
	done < <(GET_SELECTIONS | sed "/^[[:space:]]*${SELECTION[1]}[[:space:]]/!d")
}
function GET_DEFAULT_SELECTION(){
	echo - PXE  DEFAULT      none 512
	echo 0 DISK EXPERIMENTAl none 512
}
function SET_DEFAULT_SELECTION(){
	# dependant on global variables; SELECTION
	IFS=$DIFS SELECTION=( ${SELECTION[0]} $(GET_DEFAULT_SELECTION) )
	IFS=$DIFS SELECTION=( ${SELECTION[*]:0:6} )
}
function SET_DEFAULT_NAME(){
	# dependant on global variables; NAME
	IFS=$DIFS NAME=( ${NAME[0]} $(GET_DEVICE_DETAIL) )
	IFS=$DIFS NAME=( ${NAME[0]} "${DEVICE}-${NAME[3]}${NAME[4]}" )
}
function zenity_choose_tool(){
	# dependant on global variables; DEVICE
	local DISPLAY_0_USER=$(GET_DISPLAY_0_USER)
	
	# get drive size
	local zenityTitle=$(GET_DEVICE_DETAIL)

	# get selection instructions
	local zenityText=$(GET_CONFIG_SECTION "${TOOL_INSTRUCTIONS}")

	# get column headers
	eval local column=( $(GET_CONFIG_SECTION "${CONFIG_COLUMN_HEADERS}") )

	(
	cat <<-ZENITY | su - ${DISPLAY_0_USER} -s /bin/bash 2>/dev/null
		DISPLAY=${DISPLAY} zenity		\
			--width=250			\
			--height=400			\
			--timeout=25			\
			--ok-label="NEXT"		\
			--cancel-label="CANCEL"		\
			--title="${zenityTitle// /   }"	\
			--text="${zenityText}"		\
			--list				\
			--print-column=ALL		\
			--separator=:			\
			--column "#"			\
			--column "${column[0]}"		\
			--column "${column[1]}"		\
			$(zenity_selection_list)
		ZENITY
	echo $?:
	) | tac | tr -d '\n'
}
function zenity_selection_list(){
	GET_SELECTIONS |\
	while read LINE; do
		eval ARGS=( ${LINE} )
		echo -n ${ARGS[0]} \"${ARGS[1]}\" \"${ARGS[2]}\" ""
	done
}
function GET_SELECTIONS(){
	# dependant on global variables; CONFIG_TOOL_SELECTIONS
	GET_DEFAULT_SELECTION
	GET_CONFIG_SECTION "${TOOL_SELECTIONS}" | cat -n
}
function GET_CONFIG_SECTION(){
	# dependant on global variables; USER_TOOL_LIST_PATH
	local DISPLAY_0_HOME=$(GET_DISPLAY_0_HOME)
	local SECTION=$1
	cat <<-SED | sed -n -f <(cat) "${DISPLAY_0_HOME}/${USER_TOOL_LIST_PATH}"
		/[[:space:]]*\[ ${SECTION} \]/,/[[:space:]]*\[/{
			/[[:space:]]*\[/d	# delete first and last line
			/^$/d			# delete empty lines
			/^[[:space:]]*#/d	# delete comment lines
			s/^\t//			# remove single leading tab char
			p			# print
		}
	SED
}
function GET_SELECTION_PATH(){
	# dependant on global variables; SELECTION
	local DISPLAY_0_HOME=$(GET_DISPLAY_0_HOME)
	local DISPLAY_0_TOOL_DIR="${DISPLAY_0_HOME}/${TOOL_DIR}"
	local ISO=${SELECTION[4]}
	if [[ "${ISO}" =~ ^\/ ]]; then
		if [ ! -f "${ISO}" ]; then
			if [ -f "${DISPLAY_0_TOOL_DIR}${ISO}" ]; then
				local ISO="${DISPLAY_0_TOOL_DIR}${ISO}"
			elif [ -f "${DISPLAY_0_HOME}${ISO}" ]; then
				local ISO="${DISPLAY_0_HOME}${ISO}"
			else
				unset ISO
			fi
		fi
	else
		if [ -f "${DISPLAY_0_TOOL_DIR}/${ISO}" ]; then
			local ISO="${DISPLAY_0_TOOL_DIR}/${ISO}"
		elif [ -f "${DISPLAY_0_HOME}/${ISO}" ]; then
			local ISO="${DISPLAY_0_HOME}/${ISO}"
		else
			unset ISO
		fi
	fi
	echo ${ISO}
}
function GET_SELECTION_MEM(){
	# dependant on global variables; SELECTION
	echo ${SELECTION[5]} | sed 's/^$/128/'
}
function GET_DISPLAY_0_USER(){
	# get user logged into disaply ${DISPLAY}, DEFAULTS to :0
	echo localcosadmin
	return
	who -u |\
	awk '/ tty[0-9].* \(:0\)/{print $1}' |\
	tee -a >(${DEBUG} && xargs echo ${FUNCNAME} :: >> "${LOG}") |\
	grep ""
	(( $? > 0 )) && { echo ERROR \"${FUNCNAME}\" >> "${LOG}"; exit; }
}
function GET_DISPLAY_0_HOME(){
	local DISPLAY_0_USER=$(GET_DISPLAY_0_USER)
	awk -F: -v USER=${DISPLAY_0_USER} '$1~"^"USER"$"{print $6}' /etc/passwd |\
	tee -a >(${DEBUG} && xargs echo ${FUNCNAME} :: >> "${LOG}") |\
	grep ""
	(( $? > 0 )) && { echo ERROR \"${FUNCNAME}\" >> "${LOG}"; exit; }
}
function SOURCE_CONFIG_GLOBAL_VARS(){
	local config="${BASH_SRCDIR}/${1}"
	[ -f "${config}" ] || return
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

# GLOBAL vars; source config file
SOURCE_CONFIG_GLOBAL_VARS "config"

# GLOBAL vars; LOG
LOG="${BASH_SRCDIR}"/$(basename "${BASH_SRCNAME}" .sh).log
touch     "${LOG}"
chmod 777 "${LOG}"

# User Task Managment Folder
USER_TOOL_DIR=${USER_TOOL_DIR:-ISO}
TOOl_LIST_FILE_NAME=${TOOl_LIST_FILE_NAME:-tool.list.txt}
USER_TOOL_LIST_PATH=${USER_TOOL_DIR}/${TOOl_LIST_FILE_NAME}
cat <<-SU | su - $(GET_DISPLAY_0_USER) -s /bin/bash
	mkdir -p ~/"${USER_TOOL_DIR}"
	touch ~/"${USER_TOOL_LIST_PATH}" 2>/dev/null
SU

# GLOBAL vars; Config file section headers
TOOL_COLUMN_HEADERS=${TOOL_COLUMN_HEADERS:-Task List Column Headers}
TOOL_SELECTIONS=${TOOL_SELECTIONS:-Task List Selections}
TOOL_INSTRUCTIONS=${TOOL_INSTRUCTIONS:-Task Selection Instructions}
NAMING_INSTRUCTIONS=${NAMING_INSTRUCTIONS:-Naming Instructions}

# GLOBAL vars; mac address base, vrdeport base
MAC=${MAC:-080027ABCD}
MAC=${MAC//:/}
MAC=${MAC:0:10}
VRDEPORT=${VRDEPORT:-33890}

# GLOBAL vars; VirtualBox
SCTL='ide'

# GLOBAL vars; TMP
TMP="/tmp/$$_${BASH_SRCNAME}_$$"
mkdir "${TMP}"
SHM="/dev/shm/$$_${BASH_SRCNAME}_$$"
mkdir    "${SHM}"
chmod +t "${SHM}"


# GLOBAL vars; DIFS = default array delimiter
DIFS=${IFS}

# GLOBAL vars; DEBUG
DEBUG=true
DEBUG=false

# GLOBAL vars; DISPLAY
DISPLAY=:0
DISPLAY=:12

# Source git repo sudirectory
#http='https://raw.github.com/michaelsalisbury/builder/master/udev'

# Project NAME
#NAME='x11vnc'

# Get details of the latest version
#latest=`wget -O - -o /dev/null "${http}/LATEST.TXT"`

# main
main "$@" >> "${LOG}" 2>&1

# cleanup
rm -rf "${TMP}"
rm -rf "${SHM}"

# simulation control
#
# trigger add and remove
#   udevadm trigger --action=remove --sysname-match="sdb"
#   udevadm trigger --action=add    --sysname-match="sdb"
#
# force re-read of linked udev rules
#   stop udev; sleep 1; start udev



