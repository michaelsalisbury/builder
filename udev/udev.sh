#!/bin/bash
function main(){
	ACTION=$1
	DEVICE=$2
	local DISPLAY_0_USER=$(GET_DISPLAY_0_USER)
	local DISPLAY_0_HOME=$(GET_DISPLAY_0_HOME)

	# Set GLOBAL VARS
	GET_DEVICE_DETAIL &>/dev/null

	# filter out root; system drive
	awk '/[[:space:]]\/[[:space:]]/{print $1}' /etc/mtab |\
		grep -q "/dev/${DEVICE}[0-9]\+" &&\
		echo SYSTEM DRIVE EXITING &&\
		exit

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

	# ammend VRDEPORT and DEVICE to NAME
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

	# cleanup old virtual machine
	for DEV in ${DEVICE[*]}; do
		cat <<-SU | su - $username -s /bin/bash
			VBoxManage list vms |\
			while read line; do
				eval words=( "\${line}" )
				[[ "\${words[0]}" =~ $(GET_VRDEPORT ${DEV})$ ]] &&\
				VBoxManage unregistervm \${words[1]} --delete
			done
		SU
	done

	# unmount devices
	for DEV in ${DEVICE[*]}; do
		umount /dev/${DEV}*
		umount /dev/${DEV}*
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

	# 



	
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
		DISPLAY=:0 zenity			\
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
				grep "^Disk[[:space:]]\+/dev/${DEVICE}:[[:space:]]" |\
				cut -d, -f1)
	fi	
	echo ${DEVICE_DETAIL}
}
function GET_SELECTION_DETAILS(){
	# dependant on global variables; SELECTION
	local LINE=""
	while read LINE; do
		echo LINE :: "${LINE}"
                eval IFS=${DIFS} SELECTION=( ${SELECTION[0]} "${LINE}" )
	done < <(GET_SELECTIONS | sed "/^[[:space:]]*${SELECTION[1]}[[:space:]]/!d")
}
function GET_DEFAULT_SELECTION(){
	echo 0 PXE DEFAULT pxe.iso 512
}
function SET_DEFAULT_SELECTION(){
	# dependant on global variables; SELECTION
	IFS=$DIFS SELECTION=( ${SELECTION[0]} $(GET_DEFAULT_SELECTION) )
	IFS=$DIFS SELECTION=( ${SELECTION[*]:0:4} )
}
function SET_DEFAULT_NAME(){
	# dependant on global variables; NAME
	IFS=$DIFS NAME=( ${NAME[0]} $(GET_DEVICE_DETAIL) )
	IFS=$DIFS NAME=( ${NAME[0]} "${DEVICE}.${NAME[3]}${NAME[4]}" )
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
		DISPLAY=:0 zenity			\
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
	echo "${DISPLAY_0_HOME}/${USER_TOOL_LIST_PATH}" >> "${LOG}"
	cat <<-SED | sed -n -f <(cat) "${DISPLAY_0_HOME}/${USER_TOOL_LIST_PATH}"
		/[[:space:]]*\[\s${SECTION}\s\]/,/[[:space:]]*\[/{
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
	echo ${SELECTION[4]}
}
function GET_SELECTION_MEM(){
	# dependant on global variables; SELECTION
	echo ${SELECTION[5]} | sed 's/^$/128/'
}
function GET_DISPLAY_0_USER(){
	# get user logged into disaply :0
	who -u | awk '/[[:space:]]\(:0\)/{print $1}'
}
function GET_DISPLAY_0_HOME(){
	local DISPLAY_0_USER=$(GET_DISPLAY_0_USER)
	awk -F: -v USER=${DISPLAY_0_USER} '$1~"^"USER"$"{print $6}' /etc/passwd
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
			s/[[:space:]]\+/\s/g			# remove tabs, reduce spaces
			p					# print
		}
	SED
	))
}

# GLOBAL vars; fully qualified script paths and names
BASH_SRCFQFN=$(canonicalpath "${BASH_SOURCE}")
BASH_SRCNAME=$(basename "${BASH_SRCFQFN}")
BASH_SRCDIR=$(dirname "${BASH_SRCFQFN}")

# GLOBAL vars; source config file
SOURCE_CONFIG_GLOBAL_VARS "config"

# User Task Managment Folder
USER_TOOL_DIR=${USER_TOOL_DIR:-ISO}
TOOl_LIST_FILE_NAME=${TOOl_LIST_FILE_NAME:-tool.list.txt}
USER_TOOL_LIST_PATH=${USER_TOOL_DIR}/${TOOl_LIST_FILE_NAME}
cat <<-SU | su - $(GET_DISPLAY_0_USER) -s /bin/bash
	mkdir -p ~/"${USER_TOOL_DIR}"
	touch ~/"${USER_TOOL_LIST_PATH}"	
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
SCTLE='ide'

# GLOBAL vars; TMP
TMP="/tmp/$$_${BASH_SRCNAME}_$$"
mkdir "${TMP}"
SHM="/dev/shm/$$_${BASH_SRCNAME}_$$"
mkdir    "${SHM}"
chmod +t "${SHM}"

# GLOBAL vars; LOG
LOG="${BASH_SRCDIR}"/$(basename "${BASH_SRCNAME}" .sh).log
touch     "${LOG}"
chmod 777 "${LOG}"

# GLOBAL vars; DIFS = default array delimiter
DIFS=${IFS}


# Source git repo sudirectory
#http='https://raw.github.com/michaelsalisbury/builder/master/x11vnc_solaris'

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



