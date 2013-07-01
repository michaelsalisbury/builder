#!/bin/bash
function main(){
	echo DEV DEV DEV
	DEV=sda
	cat <<-SED | sed -n -f <(cat) <(fdisk -l /dev/${DEV})
		\|^Disk[[:space:]]\+/dev/${DEV}[:]|{
			s/^[^:]\+[:][[:space:]]\+\([^,]\+\).*/\1/p
		}
	SED
		#\|^Disk[[:space:]]\+/dev/${DEV}:[[:space:]]|{
	
	return
	echo hi
	GET_DEVICE_USB_ATTRIBUTE  1 13 iSerial
	GET_DEVICE_USB_BUS_ID sdb
	GET_DEVICE_INTERFACE sdb
	return

	case "${1}" in
		a*|A*)		shift; ACTION_ADD     "$@";;
		r*|R*)		shift; ACTION_REMOVE  "$@";;
		t*|T*)		shift; ACTION_TRIGGER "$@";;
		sd*)		       ACTION_ADD     "$@";;
		*)      	UMOUNT=false
				STARTVM=false
				ACTION_ADD;;
	esac
}
function HELP(){
	cat <<-HELP
		Usage...
		 a [dev]	run device add
		 r [dev] run device remove
		 t [dev] trigger udev device add action

		 LOG :: ${LOG}
	HELP
	EXIT 1
}
function ACTION_ADD(){
	local DISPLAY_0_USER=$(GET_DISPLAY_0_USER)
	local DISPLAY_0_HOME=$(GET_DISPLAY_0_HOME)
	DEVICE=$(GET_DEVICE_LIST | head -1)
	DEVICE=${1:-${DEVICE}}

	# filter out root; system drive
	IS_DEVICE_ROOT # function exits if positive

	# Set GLOBAL VARS
	GET_DEVICE_DETAIL &>/dev/null

	# popup log
	OPEN_POPUP_LOG

	# prompt user to choose tool or disregard
	IFS=: SELECTION=( $(zenity_choose_tool) )

	# exit if user chose cancel or closed dialog
	(( ${SELECTION[0]} == 1 )) \
		&& { echo CANCELED :: Task selection dialog for disk \"${DEVICE}\". Exiting\!; EXIT 1; }
	(( ${SELECTION[0]} != 5 )) \
		&& { echo NEWSTATE :: Task selection dialog returned ${SELECTION[0]}. Exiting\!; EXIT 1; } \
		|| (( ${#SELECTION[*]} > 1 )) \
			&& echo SELECTED :: ${SELECTION[*]} \
			|| echo TIME_OUT :: Task selection dialog timed out\!

	# set default if next was selected without chooseing a tool
	(( ${#SELECTION[*]} > 1 )) && GET_SELECTION_DETAILS || SET_DEFAULT_SELECTION

	# prompt user to add seconadary device 
	if echo ${SELECTION[2]} | grep -qi "^diag"; then
		DEVICE[1]=$(zenity_choose_second)
	fi

	# prompt user to label task/vm
	IFS=: NAME=( $(zenity_name_task) )

	# exit if user chose cancel or closed dialog
	(( ${NAME[0]} == 1 )) \
		&& { echo CANCELED :: Task naming dialog for disk \"${DEVICE}\". Exiting\!; EXIT 1; }
	(( ${NAME[0]} != 5 )) \
		&& { echo NEWSTATE :: Task naming dialog returned ${NAME[0]}. Exiting\!; EXIT 1; } \
		|| (( ${#NAME[*]} > 1 )) \
			&& echo LAUNCHED :: Name - ${NAME[*]} \
			|| echo TIME_OUT :: Task naming dialog timed out\!


	# set default name if start vm was selected without entering a name
	(( ${#NAME[*]} > 1 )) || SET_DEFAULT_NAME

######### if selection is PXE then verify bridged ethernet default is OK


	# amend VRDEPORT and DEVICE to NAME[1]
	NAME[1]="${NAME[1]}-$(GET_VRDEPORT).${DEVICE}"

	# set path for vmdk files
	declare -A VMDK
	for DEV in ${DEVICE[*]}; do
		VMDK[${DEV}]="${DISPLAY_0_HOME}/.VirtualBox/udev.${DEV}.${NAME[1]}.vmdk"
	done

	# cleanup old primary vmdk files
	for DEV in ${DEVICE[*]}; do
		DETACH_VMDK_HDD ${DEV}
	done

	# cleanup conflicting stale virtual machines
	for DEV in ${DEVICE[*]}; do
		DELETE_VM ${DEV}
	done

	# unmount devices
	local TRIES=""
	local PART=""
	for DEV in ${DEVICE[*]}; do
		for PART in `ls /dev/${DEV}[0-9]`; do
			for TRIES in {1..2}; do
				umount ${PART} &>/dev/null
			done
			umount -v ${PART}
		done
	done

	# create virtualbox raw vmdk files
	for DEV in ${DEVICE[*]}; do
		which VBoxManage &>/dev/null || continue
		VBoxManage internalcommands createrawvmdk	\
			-filename "${VMDK[${DEV}]}"		\
			-rawdisk /dev/${DEV}
		chmod a+rw                        "${VMDK[${DEV}]}"
		chown ${DISPLAY_0_USER}.vboxusers "${VMDK[${DEV}]}"
		chmod a+rw                        /dev/${DEV}
		chown ${DISPLAY_0_USER}.vboxusers /dev/${DEV}
	done

	# create virtual machine
	SET_VM	

	# start virtual machine
	START_VM

	# dump var status to LOG
	echo	
	echo "      name :: "${NAME[*]}
	echo "  name err :: "${NAME[0]}
	echo " selection :: "${SELECTION[*]}
	echo "select err :: "${SELECTION[0]}
	echo "      path :: "$(GET_SELECTION_PATH)
	echo "       mem :: "$(GET_SELECTION_MEM)
	echo "      name :: "${NAME[1]}
	echo '        $@ :: '$@
	echo
}
function ACTION_REMOVE(){
	unset POPUP_LOG
	local DISPLAY_0_USER=$(GET_DISPLAY_0_USER)
	local DISPLAY_0_HOME=$(GET_DISPLAY_0_HOME)
	DEVICE=$(GET_DEVICE_LIST | head -1)
	DEVICE=${1:-${DEVICE}}

	# filter out root; system drive
	IS_DEVICE_ROOT # function exits if positive

	# LOG
	echo REMOVING :: ${DEVICE}
	# detach and delete vmdk 
	DETACH_VMDK_HDD ${DEVICE}

	# delete vm
	DELETE_VM ${DEVICE}

}
function SETUP_CONFIG_UDEV_RULE(){
	# Dependant on GLOBAL var; UDEV_RULE_CONFIG_FILE_NAME_DEFAULT
	local PROG_NAME=$(basename "${BASH_SRCNAME}" .sh)
	local RULE_FILE="/etc/udev/rules.d/${UDEV_RULE_CONFIG_FILE_NAME_DEFAULT}"
	# LOG Info
	LOG INFO :: ${FUNCNAME} :: UDEV_RULE_CONFIG_FILE_NAME_DEFAULT[${UDEV_RULE_CONFIG_FILE_NAME_DEFAULT}]
	# Find the most relavant udev rule config file template
	if [ -f "${BASH_SRCDIR}/${UDEV_RULE_CONFIG_FILE_NAME_DEFAULT}" ]; then
		local SOURCE_CONFIG="${BASH_SRCDIR}/${UDEV_RULE_CONFIG_FILE_NAME_DEFAULT}"
	elif [ -f "${BASH_SRCDIR}/../etc/${PROG_NAME}/${UDEV_RULE_CONFIG_FILE_NAME_DEFAULT}" ]; then
		local SOURCE_CONFIG="${BASH_SRCDIR}/../etc/${PROG_NAME}/${UDEV_RULE_CONFIG_FILE_NAME_DEFAULT}"
	else
		LOG ERROR :: ${FUNCNAME} :: Source udev rule template not found. UDEV_RULE_CONFIG_FILE_NAME_DEFAULT[${UDEV_RULE_CONFIG_FILE_NAME_DEFAULT}]
		EXIT 1
	fi
	# fix template file; ensure rules execute this script
	cat <<-SED | sed -i -f <(cat) "${SOURCE_CONFIG}"
		s|\(.*[[:space:]]RUN+="\)\([^[:space:]]\+\)\(.*\)|\1${BASH_SRCFQFN}\3|
	SED
	# test if template differs from install udev rule
	diff --suppress-common-lines "${SOURCE_CONFIG}" "${RULE_FILE}" | LOG INFO :: ${FUNCNAME} ::
	#
	(( ${PIPESTATUS[0]} )) && cat "${SOURCE_CONFIG}" > "${RULE_FILE}"
}
function ACTION_TRIGGER(){
	#udevadm trigger --action=add    --sysname-match="sdb"
	local DEV=$(GET_DEVICE_LIST | head -1)
	local DEV=${2:-${DEV}}
	unset POPUP_LOG

	IS_DEVICE_ROOT ${DEV}
	
	IS_DEVICE_REAL ${DEV}

	SETUP_CONFIG_IF_EMPTY "${UDEV_RULE_CONFIG_FILE_NAME_DEFAULT}" "/etc/udev/rules.d/${UDEV_RULE_CONFIG_FILE_NAME_DEFAULT}"

	SETUP_CONFIG_UDEV_RULE

	case "$1" in
		a*|A*)	udevadm trigger --action=add    --sysname-match="${DEV}";;
		r*|R*)	udevadm trigger --action=remove --sysname-match="${DEV}";;
		*)	ACTION_TRIGGER add "$@";;
	esac
}
function START_VM(){
	local DISPLAY_0_USER=$(GET_DISPLAY_0_USER)

	local VB=$(which VirtualBox 2>/dev/null)
	if [ -z "${VB}" ]; then
		echo ERROR :: ${FUNCNAME} :: VirtualBox not found. Skipping\! >> "${LOG}"
		return
	fi

	# start vm
	cat <<-SU | su - ${DISPLAY_0_USER} -s /bin/bash
		export DISPLAY=:0
		${VB} --startvm ${NAME[1]} &
	SU
}
function DETACH_VMDK_HDD(){
	local DISPLAY_0_USER=$(GET_DISPLAY_0_USER)
	local DEV=${1:-${DEVICE}}
	local TARGET_VM_MASK="$(GET_VRDEPORT ${DEV}).${DEV}.vmdk"
	cat <<-SU | su - ${DISPLAY_0_USER} -s /bin/bash
		# Only run command if VBoxManage exists and is in PATH
		which VBoxManage &>/dev/null &&\
		VBoxManage list hdds |\
		while read VAR DATA; do
			(( \${#VAR} )) || continue
			# create variables
			eval \${VAR%:}=\"\${DATA}\"
			# If the following are true...
			# Usage is the current VAR (also the last hdd detail)
			# Format equals VMDK
			# The Location name matches my mask
			if [ "\${VAR%:}" == "Usage" ] \
			&& [ "\${Format}" == "VMDK" ] \
			&& [[ "\${Location}" =~ ${TARGET_VM_MASK}\$ ]]; then
				echo DEL_DISK :: UUID = \${UUID}
				echo DEL_DISK :: PATH = \${Location}
				VBoxManage controlvm     "\${Usage% (*}" poweroff
				(( \$? )) || sleep 3
				VBoxManage storageattach "\${Usage% (*}"\
					--storagectl ${SCTL}		\
					--type hdd --port 0 --device 0	\
					--medium none
				(( \$? )) || sleep 2
				VBoxManage storageattach "\${Usage% (*}"\
					--storagectl ${SCTL}		\
					--type hdd --port 1 --device 0	\
					--medium none
				(( \$? )) || sleep 2
				VBoxManage closemedium disk "\${UUID}"
				(( \$? )) || sleep 2
				VBoxManage unregistervm "\${Usage% (*}" --delete
				(( \$? )) || sleep 2 
				VBoxManage unregistervm "\${Usage% (*}"
				(( \$? )) || sleep 2 
			fi
		done		
	SU
	# now remove the actual vmdk file
	rm -f "${DISPLAY_0_HOME}/.VirtualBox/udev.${DEV}."*.vmdk
}
function DELETE_VM(){
	local DISPLAY_0_USER=$(GET_DISPLAY_0_USER)
	local DEV=${1:-${DEVICE}}
	local TARGET_VM_MASK="$(GET_VRDEPORT ${DEV}).${DEV}"
	cat <<-SU | su - ${DISPLAY_0_USER} -s /bin/bash
		# Only run command if VBoxManage exists and is in PATH
		which VBoxManage &>/dev/null &&\
		VBoxManage list vms |\
		while read line; do
			eval words=( "\${line}" )
			vm_uuid=\${words[1]}
			# echo MACHINE :: \${words[*]}
			if [[ "\${words[0]}" =~ ${TARGET_VM_MASK}\$ ]]; then
				echo REMOVED :: \${words[*]}
				VBoxManage controlvm    \${vm_uuid} poweroff
				(( \$? )) || sleep 3
				VBoxManage unregistervm \${vm_uuid} --delete
				(( \$? )) || sleep 3
				VBoxManage unregistervm \${vm_uuid}
				(( \$? )) || sleep 3
			fi
		done
	SU
	# remove vm folder
	rm -rf "${DISPLAY_0_HOME}/VirtualBox VMs"/*${TARGET_VM_MASK}
}
function SET_VM(){
	local DISPLAY_0_USER=$(GET_DISPLAY_0_USER)
	local DISPLAY_0_HOME=$(GET_DISPLAY_0_HOME)
	local DISPLAY_0_TOOL_DIR="${DISPLAY_0_HOME}/${TOOL_DIR}"
	
	local VBM=$(which VBoxManage 2>/dev/null)
	if [ -z "${VBM}" ]; then
		echo ERROR :: ${FUNCNAME} :: VBoxManage not found. Skipping\! >> "${LOG}"
		return
	fi
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
					   --bridgeadapter1 ${BRIDGED_ETH} \
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
		${VBM} storagectl ${NAME[1]} --name ${SCTL}	\
					   --add ${SCTL}	\
					   --bootable on
		${VBM} storageattach ${NAME[1]} --storagectl ${SCTL} \
					   --port 0		\
					   --device 1		\
					   --type dvddrive	\
					   --medium "${DVD:-emptydrive}"
	SU
	# set disks
	for dev in ${DEVICE[*]}; do
	cat <<-SU | su - ${DISPLAY_0_USER} -s /bin/bash
		${VBM} storageattach ${NAME[1]} --storagectl ${SCTL}	\
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
	# sdb = 33890, sdc = 33891, sdd = 33892,,,
	echo $(( VRDEPORT + $(printf "%d\n" \'${DEV:2}) - 98 ))
}
function GET_MAC(){
	# dependant on global variables; MAC
	local DEV=${1:-${DEVICE}}
	# get mac; convert the sd disk letter to a number and add to mac base
	# sdb = 99, sdc = 98, sdd = 97,,,
	echo ${MAC}$(( 197 - $(printf "%d\n" \'${DEV:2}) ))
}
function zenity_name_task(){
	# dependant on global variables; DEVICE
	local DISPLAY_0_USER=$(GET_DISPLAY_0_USER)
	# get drive size
	local zenityTitle=$(GET_DEVICE_DETAIL)
	# naming instructions
	local zenityText=$(GET_CONFIG_SECTION "$(GET_DISPLAY_0_CONFIG_FQFN)" ${UCST_NAMING_INSTRUCTIONS})

	(
	cat <<-ZENITY | su - ${DISPLAY_0_USER} -s /bin/bash 2>/dev/null
		DISPLAY=:${TARGET_DISPLAY} zenity	\
			--timeout=${DIALOG_TIMEOUT:-25}	\
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
####################################################################################################
################################################################################# ASSOCIATIVE ARRAYS
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
	declare -A DEVICE_PRODUCT
	if ! (( ${#DEVICE_PRODUCT[${DEV}]} > 0 )); then
 		case "${DEVICE_INTERFACE[${DEV}]}" in
			ata|scsi)	DEVICE_PRODUCT[${DEV}]=$(GET_DEVICE_HDD_PRODUCT ${DEV});;
			usb)		DEVICE_PRODUCT[${DEV}]=$(GET_DEVICE_USB_PRODUCT ${DEVICE_USB_ID[${DEV}]});;
		esac
	fi
	echo ${DEVICE_PRODUCT[${DEV}]}
}
####################################################################################################
####################################################################################################
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
	IFS=$DIFS NAME=( ${NAME[0]} "${NAME[3]}${NAME[4]}" )
}
function zenity_choose_tool(){
	# dependant on global variables; DEVICE
	local DISPLAY_0_USER=$(GET_DISPLAY_0_USER)
	
	# get drive size
	local zenityTitle=$(GET_DEVICE_DETAIL)

	# get selection instructions
	local zenityText=$(GET_CONFIG_SECTION "$(GET_DISPLAY_0_CONFIG_FQFN)" ${UCST_TOOL_INSTRUCTIONS})

	# get column headers
	eval local column=( $(GET_CONFIG_SECTION "$(GET_DISPLAY_0_CONFIG_FQFN)" ${UCST_CONFIG_COLUMN_HEADERS}) )

	(
	cat <<-ZENITY | su - ${DISPLAY_0_USER} -s /bin/bash 2>/dev/null
		DISPLAY=:${TARGET_DISPLAY} zenity	\
			--width=250			\
			--height=400			\
			--timeout=${DIALOG_TIMEOUT:-25}	\
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
	GET_CONFIG_SECTION "$(GET_DISPLAY_0_CONFIG_FQFN)" ${UCST_TOOL_SELECTIONS} |\
	cat -n
}
function GET_CONFIG_SECTION(){
	# dependant on global variables; USER_TOOL_LIST_PATH
	local DISPLAY_0_HOME=$(GET_DISPLAY_0_HOME)
	local SECTION=$1
	#echo ${DISPLAY_0_HOME} ${SECTION} | LOG
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
	local DISPLAY_0_CONFIG_DIR=$(GET_DISPLAY_0_CONFIG_DIR)
	local ISO=${SELECTION[4]}
	if [[ "${ISO}" =~ ^\/ ]]; then
		if [ ! -f "${ISO}" ]; then
			if [ -f "${DISPLAY_0_CONFIG_DIR}${ISO}" ]; then
				local ISO="${DISPLAY_0_CONFIG_DIR}${ISO}"
			elif [ -f "${DISPLAY_0_HOME}${ISO}" ]; then
				local ISO="${DISPLAY_0_HOME}${ISO}"
			else
				unset ISO
			fi
		fi
	else
		if [ -f "${DISPLAY_0_CONFIG_DIR}/${ISO}" ]; then
			local ISO="${DISPLAY_0_CONFIG_DIR}/${ISO}"
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
function GET_DISPLAY_0_CONFIG_DIR(){
	# Dependant on GLOBAL vars; TARGET_DISPLAY
	# Deplendant on functions; GET_DISPLAY_USER, GET_USER_HOME_DIR
	local DISPLAY_0_USER=$(GET_DISPLAY_USER ${TARGET_DISPLAY:-0})
	local DISPLAY_0_HOME=$(GET_USER_HOME_DIR ${DISPLAY_0_USER})
	local DISPLAY_0_CONFIG_DIR="${DISPLAY_0_HOME}/${USER_CONFIG_DIR_RELATIVE}"
	[ -d "${DISPLAY_0_CONFIG_DIR}" ] \
		&& echo "${DISPLAY_0_CONFIG_DIR}" \
		|| echo "/dev/zreo"
}
function GET_DISPLAY_0_CONFIG_FQFN(){
	# Dependant on GLOBAL vars; TARGET_DISPLAY
	# Deplendant on functions; GET_DISPLAY_USER, GET_USER_HOME_DIR
	local DISPLAY_0_USER=$(GET_DISPLAY_USER ${TARGET_DISPLAY:-0})
	local DISPLAY_0_HOME=$(GET_USER_HOME_DIR ${DISPLAY_0_USER})
	local DISPLAY_0_CONFIG="${DISPLAY_0_HOME}/${USER_CONFIG_DIR_RELATIVE}/${USER_CONFIG_FILE_NAME}"
	[ -f "${DISPLAY_0_CONFIG}" ] \
		&& echo "${DISPLAY_0_CONFIG}" \
		|| echo "/dev/zero"
}
function GET_DISPLAY_0_USER(){
	GET_DISPLAY_USER ${TARGET_DISPLAY:-0}
}
function GET_DISPLAY_0_HOME(){
	GET_USER_HOME_DIR $(GET_DISPLAY_USER ${TARGET_DISPLAY:-0})
}
function OPEN_POPUP_LOG(){
	${POPUP_LOG:-false} || return
	local DISPLAY_0_USER=$(GET_DISPLAY_USER ${TARGET_DISPLAY:-0})
	cat <<-SU | su - ${DISPLAY_0_USER} -s /bin/bash &
		DISPLAY=:${TARGET_DISPLAY} terminator	\
			-m -b				\
			-T "$(GET_DEVICE_DETAIL)"	\
			-e "tail -f \"${LOG_}\""
	SU
	POPUP_LOG_PID=$!
	sleep 2
	POPUP_LOG_PID=$(FIND_PID ${POPUP_LOG_PID} tail)
	LOG INFO :: ${FUNCNAME} :: PID = ${POPUP_LOG_PID}
}
function EXIT(){
	# cleanup
	rm -rf "${TMP}"
	rm -rf "${SHM}"
	if ${POPUP_LOG:-false}; then
		echo INFO :: ${FUNCNAME} :: POPUP_LOG_PID = ${POPUP_LOG_PID} >> "${LOG}"
		eval "sleep ${POPUP_LOG_AUTOCLOSE_DELAY}; kill ${POPUP_LOG_PID};"
	fi
	exit ${1:- 0}
}
# SOURCE Dependant Functions
source "$(dirname "${BASH_SOURCE}")/../functions/functions.general.sh"
source "$(dirname "${BASH_SOURCE}")/../functions/functions.test.sh"

# GLOBAL vars; fully qualified script paths and names
BASH_SRCFQFN=$(canonicalpath "${BASH_SOURCE}")
BASH_SRCNAME=$(basename "${BASH_SRCFQFN}")
BASH_SRCDIR=$(dirname "${BASH_SRCFQFN}")

#
#LOG="/var/log/udev.vbox_launcher.log"
#DEBUG=true

# GLOBAL vars; source config file
SOURCE_CONFIG_GLOBAL_VARS "config"

# GLOBAL vars; LOG
if (( ${#LOG} > 0 )); then
	LOG=$(basename "${BASH_SRCNAME}" .sh)
	LOG="/var/log/${LOG}.log"
fi
touch     "${LOG}"
chmod 777 "${LOG}"

# Target DISPLAY to popup dialogs and create VM's
TARGET_DISPLAY=${TARGET_DISPLAY:-0}
TARGET_DISPLAY=${TARGET_DISPLAY//[^0-9.]/}

# udev rule file name
UDEV_RULE_CONFIG_FILE_NAME_DEFAULT=${UDEV_RULE_CONFIG_FILE_NAME_DEFAULT:-99-customUDEV.rules}

# GLOBAL vars; User Config Section Titles (UCST_) 
UCST_TOOL_COLUMN_HEADERS=${UCST_TOOL_COLUMN_HEADERS:-Task List Column Headers}
UCST_TOOL_SELECTIONS=${UCST_TOOL_SELECTIONS:-Task List Selections}
UCST_TOOL_INSTRUCTIONS=${UCST_TOOL_INSTRUCTIONS:-Task Selection Instructions}
UCST_NAMING_INSTRUCTIONS=${UCST_NAMING_INSTRUCTIONS:-Naming Instructions}
UCST_GLOBAL_VAR_DEFAULTS=${UCST_GLOBAL_VAR_DEFAULTS:-Global Defaults}

# User Task Managment Folder
USER_CONFIG_DIR_RELATIVE=${USER_CONFIG_DIR_RELATIVE:-ISO}
USER_CONFIG_FILE_NAME=${USER_CONFIG_FILE_NAME:-${USER_CONFIG_FILE_NAME_DEFAULT:-tool.list.txt}}
#USER_TOOL_DIR=${USER_TOOL_DIR:-ISO}				# OLD, REMOVE ASAP
#TOOl_LIST_FILE_NAME=${TOOl_LIST_FILE_NAME:-tool.list.txt} 	# OLD, REMOVE ASAP
#USER_TOOL_LIST_PATH=${USER_TOOL_DIR}/${TOOl_LIST_FILE_NAME}	# OLD, REMOVE ASAP
# Setup User Task Managment Folder
cat <<-SU | su - $(GET_DISPLAY_0_USER) -s /bin/bash
	mkdir -p ~/"${USER_CONFIG_DIR_RELATIVE}"
	rm    -f ~/"${USER_CONFIG_DIR_RELATIVE}/${USER_CONFIG_FILE_NAME}"
	touch    ~/"${USER_CONFIG_DIR_RELATIVE}/${USER_CONFIG_FILE_NAME}"
SU
SETUP_CONFIG_IF_EMPTY "${USER_CONFIG_FILE_NAME_DEFAULT}" "$(GET_DISPLAY_0_CONFIG_FQFN)"

# GLOBAL vars; source user config file
SOURCE_CONFIG_GLOBAL_VARS <(GET_CONFIG_SECTION "$(GET_DISPLAY_0_CONFIG_FQFN)" ${UCST_GLOBAL_VAR_DEFAULTS})

# GLOBAL vars; mac address base, vrdeport base, DIALOG_TIMEOUT
MAC=${MAC:-080027ABCD}
MAC=${MAC//:/}
MAC=${MAC:0:10}
VRDEPORT=${VRDEPORT:-33890}
DIALOG_TIMEOUT=${DIALOG_TIMEOUT:-25}
BRIDGED_ETH=${BRIDGED_ETH:-eth0}

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
DEBUG=${DEBUG:-false}

# Source git repo sudirectory
#http='https://raw.github.com/michaelsalisbury/builder/master/udev'

# Project NAME
#NAME='x11vnc'

# Get details of the latest version
#latest=`wget -O - -o /dev/null "${http}/LATEST.TXT"`

# GLOGAL vars; POPUP_LOG, POPUP_LOG_AUTOCLOSE_DELAY
POPUP_LOG=${POPUP_LOG:-false}
POPUP_LOG_AUTOCLOSE_DELAY=${POPUP_LOG_AUTOCLOSE_DELAY:-60}

# Display Help
[[ "$1" =~ ^(-h|--help)$ ]] && HELP

eval ATTRIB=( $(GET_DEVICE_HWINFO_ATTRIBUTE sda Serial ID:) )
echo ${ATTRIB[*]: -1}
eval ATTRIB=( $(GET_DEVICE_HWINFO_ATTRIBUTE sdb Device:) )
echo ${ATTRIB[*]: -1}
eval ATTRIB=( $(GET_DEVICE_HWINFO_ATTRIBUTE sdc Model:) )
echo ${ATTRIB[*]: -1}
EXIT 1
# main
main "$@" >> "${LOG}" 2>&1

EXIT

# simulation control
#
# trigger add and remove
#   udevadm trigger --action=remove --sysname-match="sdb"
#   udevadm trigger --action=add    --sysname-match="sdb"
#
# force re-read of linked udev rules
#   stop udev; sleep 1; start udev



