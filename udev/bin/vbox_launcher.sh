#!/bin/bash
###########################################################################################
############################################################################### GLOBAL VARS
# ARRAYS :: DEVICES, SELECTION, NAME, VMDK
# 
#
#
#
#
###########################################################################################
############################################################################## MAIN ACTIONS
function main(){
	case "${1}" in
		a*|A*)		shift; ACTION_ADD     "$@";;
		d*|D*)		shift; ACTION_DISOWN  "$@";;
		i*|I*)		       ACTION_INSTALL;;
		r*|R*)		shift; ACTION_REMOVE  "$@";;
		s*|S*)		       ACTION_SELECT;;
		t*|T*)		shift; ACTION_TRIGGER "$@";;
		*)		       ACTION_SELECT;;
	esac
}
function HELP(){
	cat <<-HELP
		Usage...
		 a [dev] run device add
		 r [dev] run device remove
		 t [dev] trigger udev device add action

		 LOG :: ${LOG}
	HELP
	EXIT 1
}
function ACTION_DISOWN(){
	/usr/bin/setsid "${BASH_SRCFQFN}" "$@" &
	EXIT 0
}
function ACTION_SELECT(){
	# select a disk manually
	ENABLE_WMCTRL=false
	zenity_choose_device
	# verify user selected disk otherwise exit
	if (( ${#DEVICE[*]} )) && IS_DEVICE_REAL ${DEVICE[0]}; then
		#ACTION_TRIGGER ${DEVICE[0]}
		ACTION_ADD     ${DEVICE[0]}
	else
		EXIT 1
	fi
}
function ACTION_ADD(){
	DEVICE=$(GET_DEVICE_LIST | head -1)
	DEVICE=${1:-${DEVICE}}
	declare -A VMDK
	for DEV in ${DEVICE[*]};	do VMDK[${DEV}]="${DEV}";		done

	# filter out root; system drive
	IS_DEVICE_ROOT # function exits if positive

	# filter out devices attached to running VMS
	for DEV in ${DEVICE[*]};	do IS_VBOX_USING_DEVICE ${DEV} && EXIT 1;	done

	# popup log
	OPEN_POPUP_LOG

	# prompt user to choose a tool
	zenity_choose_tool

	# prompt user to add seconadary device 
	IS_2ND_DEVICE_OPTIONAL && zenity_choose_device

	# prompt user to label task/vm
	zenity_name_task

######### if selection is PXE then verify bridged ethernet default is OK

	# cleanup old primary vmdk files
	for DEV in ${DEVICE[*]};	do DETACH_VMDK_HDD ${DEV};	done

	# cleanup conflicting stale virtual machines
	for DEV in ${DEVICE[*]};	do DELETE_VM ${DEV};		done

	# unmount devices
	UNMOUNT_DEVICES

	# create VMDK
	for DEV in ${DEVICE[*]};	do CREATE_VMDK ${DEV};		done

	# create virtual machine
	CREATE_VM	

	# one more time just to be safe
	UNMOUNT_DEVICES

	# start virtual machine
	START_VM

	# LOG VM start
	LOG INF :: VM started, NAME[${NAME[1]}] DEV0[${DEVICE[0]}] DEV1[${DEVICE[1]}]

	# Exit Cleanly
	EXIT 0
}
function ACTION_REMOVE(){
	unset POPUP_LOG
	local DEV=${1:-${DEVICE}}

	# filter out root; system drive
	IS_DEVICE_ROOT ${DEV} # function exits if positive

	IS_DEVICE_REAL ${DEV}

	# LOG
	LOG INF :: REMOVING DEV[${DEV}]

	# detach and delete vmdk 
	DETACH_VMDK_HDD ${DEV}

	# delete vm
	DELETE_VM ${DEV}

	# Exit Cleanly
	EXIT 0
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
	EXIT 0
}
function ACTION_INSTALL(){
	# verify root access
	# setup user groups vbox and disk
	# setup log
		touch     "${LOG}"
		chmod 777 "${LOG}"
	# setup etc
	# setup udev
	# setup User Task Managment Folder
		su - $(GET_DISPLAY_0_USER) -s /bin/bash <<-SU
			mkdir -p ~/"${USER_CONFIG_DIR_RELATIVE}"
		#	rm    -f ~/"${USER_CONFIG_DIR_RELATIVE}/${USER_CONFIG_FILE_NAME}"
			touch    ~/"${USER_CONFIG_DIR_RELATIVE}/${USER_CONFIG_FILE_NAME}"
		SU
		SETUP_CONFIG_IF_EMPTY "${USER_CONFIG_FILE_NAME_DEFAULT}"\
				      "$(GET_USER_CONFIG_FQFN)"

}
###########################################################################################
###########################################################################################
function START_VM(){
	if whoami | grep -q ^root$; then
		local DISPLAY=${DISPLAY:-${TARGET_DISPLAY:-0}}
		local USERNAME=$(GET_DISPLAY_USER ${DISPLAY})
		/usr/bin/setsid su - ${USERNAME} -s /bin/bash <<-SU
			export DISPLAY=:${DISPLAY}
			which VBoxManage && VBoxManage setextradata global GUI/SuppressMessages ${VBOX_SUPPRESS_MESSAGES}
			which VirtualBox && VirtualBox --startvm "${NAME[1]}"
		SU
	else
		which VBoxManage && VBoxManage setextradata global GUI/SuppressMessages ${VBOX_SUPPRESS_MESSAGES}
		which VirtualBox && VirtualBox --startvm "${NAME[1]}"
	fi
}
function CREATE_VMDK(){
	local DEV=${1:-${DEVICE}}
	# setup assocciative array
	(( ${#VMDK[*]} > 0 )) || declare -A VMDK
	# set path for vmdk files, used by function CREATE_VM
	VMDK[${DEV}]="$(GET_DEVICE_VMDK_FILE_FQFN ${DEV})"

	# create virtualbox raw vmdk files; user must be part of "disk" group
	IF_ROOT_SU <<-SU &> >(LOG - INF :: ${FUNCNAME} :: DEV[${DEV}] ::)
		# Only run command if VBoxManage exists and is in PATH
		which VBoxManage &>/dev/null &&\
		VBoxManage internalcommands createrawvmdk	\
			-filename "${VMDK[${DEV}]}"		\
			-rawdisk /dev/${DEV}
	SU
}
function DETACH_VMDK_HDD(){
	local DEV=${1:-${DEVICE}}

	local GET_DEVICE_VBOX_UUID=$(GET_DEVICE_VBOX_UUID ${DEV})
	local GET_DEVICE_VBOX_MACHINE_UUID=$(GET_DEVICE_VBOX_MACHINE_UUID ${DEV})

	# detach vmdk's
	if (( ${#GET_DEVICE_VBOX_MACHINE_UUID} > 0 )); then
		IF_ROOT_SU <<-SU &> >(LOG - INF :: ${FUNCNAME}[${DEV}] ::)
			if which VBoxManage &>/dev/null; then
				VBoxManage controlvm     "${GET_DEVICE_VBOX_MACHINE_UUID}" poweroff
				(( \$? )) || sleep 2
				VBoxManage storageattach "${GET_DEVICE_VBOX_MACHINE_UUID}"\
					--storagectl ${SCTL}		\
					--type hdd --port 0 --device 0	\
					--medium none
				(( \$? )) || sleep 2
				VBoxManage storageattach "${GET_DEVICE_VBOX_MACHINE_UUID}"\
					--storagectl ${SCTL}		\
					--type hdd --port 1 --device 0	\
					--medium none
				(( \$? )) || sleep 2
			fi
		SU
	fi

	# closemedium vmdk, and attempt delete
	if (( ${#GET_DEVICE_VBOX_UUID} > 0 )); then
		IF_ROOT_SU <<-SU &> >(LOG - INF :: ${FUNCNAME}[${DEV}] ::)
			if which VBoxManage &>/dev/null; then
				VBoxManage closemedium disk "${GET_DEVICE_VBOX_UUID}"
				(( \$? )) || sleep 2
				VBoxManage unregistervm     "${GET_DEVICE_VBOX_UUID}" --delete
				(( \$? )) || sleep 2 
				VBoxManage unregistervm     "${GET_DEVICE_VBOX_UUID}"
				(( \$? )) || sleep 2 
			fi
		SU
	fi

	# delete associated virtual machine
	if (( ${#GET_DEVICE_VBOX_MACHINE_UUID} > 0 )); then
		IF_ROOT_SU <<-SU &> >(LOG - INF :: ${FUNCNAME}[${DEV}] ::)
			if which VBoxManage &>/dev/null; then
				VBoxManage unregistervm "${GET_DEVICE_VBOX_MACHINE_UUID}" --delete
				(( \$? )) || sleep 3
				VBoxManage unregistervm "${GET_DEVICE_VBOX_MACHINE_UUID}"
				(( \$? )) || sleep 3
			fi
		SU
	fi

	# now remove the actual vmdk file
	rm -vf "$(GET_DEVICE_VMDK_FILE_FQFN ${DEV})" \
		1> >(LOG - STS :: ${FUNCNAME}[${DEV}] ::) \
		2> >(LOG - ERR :: ${FUNCNAME}[${DEV}] ::)
}
function DELETE_VM(){
	local DEV=${1:-${DEVICE}}
	local TARGET_VM_MASK="$(GET_VRDEPORT ${DEV}).${DEV}"
	local MACHINE_NAME=$(GET_VBOX_MACHINE_NAME ${DEV})

	if (( ${#MACHINE_NAME} > 0 )); then
		IF_ROOT_SU <<-SU &> >(LOG - INF :: ${FUNCNAME}[${DEV}] ::)
			if which VBoxManage &>/dev/null; then
				VBoxManage controlvm    "${MACHINE_NAME}" poweroff
				(( \$? )) || sleep 3
				VBoxManage unregistervm "${MACHINE_NAME}" --delete
				(( \$? )) || sleep 3
				VBoxManage unregistervm "${MACHINE_NAME}"
				(( \$? )) || sleep 3
			fi
		SU
	fi

	# remove vm folder
	rm -rvf "$(GET_HOME_DIR)/VirtualBox VMs"/*${TARGET_VM_MASK} \
		1> >(LOG - INF :: ${FUNCNAME}[${DEV}] ::) \
		2> >(LOG - ERR :: ${FUNCNAME}[${DEV}] ::)
}
function CREATE_VM(){
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
	# prep: determin if eth is bridged
	ENABLE_BRIDGED_ETH=true
	

	# create vm
	IF_ROOT_SU <<-SU &> >(LOG - INF :: ${FUNCNAME} ::)
		${VBM} createvm --name ${NAME[1]}	\
				--ostype Other		\
				--register
	SU
	# memory
	IF_ROOT_SU <<-SU &> >(LOG - INF :: ${FUNCNAME} ::)
		${VBM} modifyvm ${NAME[1]} --memory $(GET_SELECTION_MEM)
	SU
	# set boot device
	IF_ROOT_SU <<-SU &> >(LOG - INF :: ${FUNCNAME} ::)
		${VBM} modifyvm ${NAME[1]} --boot1 ${boot1} \
					   --boot2 none     \
					   --boot3 none     \
					   --boot4 none
	SU
	# set nic
	IF_ROOT_SU <<-SU &> >(LOG - INF :: ${FUNCNAME} ::)
		${VBM} modifyvm ${NAME[1]} --nic1 bridged        \
					   --cableconnected1 on  \
		     ${ENABLE_BRIDGED_ETH:+--bridgeadapter1 ${BRIDGED_ETH}} \
					   --nictype1 82540EM    \
					   --macaddress1 $(GET_MAC)
	SU
	# set VRDE
	IF_ROOT_SU <<-SU &> >(LOG - INF :: ${FUNCNAME} ::)
		${VBM} modifyvm ${NAME[1]} --vrde on                  \
					   --vrdeport $(GET_VRDEPORT) \
					   --vrdeauthtype null        \
					   --vrdemulticon on
	SU
	# set ide controler and dvd
	IF_ROOT_SU <<-SU &> >(LOG - INF :: ${FUNCNAME} ::)
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
	local DEV="" PORT_NUM=0
	for DEV in ${DEVICE[*]}; do
		LOG INF :: ${FUNCNAME} :: DEV[${DEV}] PORT_NUM[${PORT_NUM}] VMDK[${VMDK[${DEV}]}]
		IF_ROOT_SU <<-SU &> >(LOG - INF :: ${FUNCNAME} ::)
			${VBM} storageattach ${NAME[1]} --storagectl ${SCTL}	\
						   --port ${PORT_NUM}		\
						   --device 0			\
						   --type hdd			\
						   --medium "${VMDK[${DEV}]}"
		SU
		let PORT_NUM++
	done
}
###########################################################################################
###########################################################################################
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
###########################################################################################
###########################################################################################
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
	local MAC=$(ifconfig eth0 | awk '/HWaddr/{print $5}' | tr -d : | tr [a-z] [A-Z])
	# get mac; convert the sd disk letter to a number and add to mac base
	# sda = 99, sdb = 98, sdc = 97, sdd = 96,,,
	echo ${MAC:0:4}$(( 196 - $(printf "%d\n" \'${DEV:2}) ))${MAC:6} |\
	tee >(LOG - INF :: ${FUNCNAME} ::)
}
function GET_SELECTION_MEM(){
	# dependant on global variables; SELECTION
	echo ${SELECTION[5]} | sed 's/^$/128/'
}
function GET_SELECTION_PATH(){
	# dependant on global variables; SELECTION
	local HOME_DIR=$(GET_HOME_DIR)
	local USER_CONFIG_DIR=$(GET_USER_CONFIG_DIR)
	local ISO=${SELECTION[4]}
	if [[ "${ISO}" =~ ^\/ ]]; then
		if [ ! -f "${ISO}" ]; then
			if [ -f "${USER_CONFIG_DIR}${ISO}" ]; then
				local ISO="${USER_CONFIG_DIR}${ISO}"
			elif [ -f "${HOME_DIR}${ISO}" ]; then
				local ISO="${HOME_DIR}${ISO}"
			else
				unset ISO
			fi
		fi
	else
		if [ -f "${USER_CONFIG_DIR}/${ISO}" ]; then
			local ISO="${USER_CONFIG_DIR}/${ISO}"
		elif [ -f "${HOME_DIR}/${ISO}" ]; then
			local ISO="${HOME_DIR}/${ISO}"
		else
			unset ISO
		fi
	fi
	echo ${ISO}
}
###########################################################################################
########################################################################### SELECTION TASKS
function GET_SELECTIONS(){
	# dependant on global variables; CONFIG_TOOL_SELECTIONS
	GET_DEFAULT_SELECTION
	cat -n <(GET_CONFIG_SECTION "$(GET_USER_CONFIG_FQFN)" ${UCST_TOOL_SELECTIONS})
}
function GET_SELECTION_DETAILS(){
	# dependant on global variables; SELECTION
	local LINE=""
	eval IFS=${DIFS} SELECTION=(
		${SELECTION[0]}
		$(grep "^[[:space:]]*${SELECTION[1]}[[:space:]]" <(GET_SELECTIONS))
	)
}
function GET_DEFAULT_SELECTION(){
	echo - PXE  DEFAULT      none 512
	echo 0 DISK EXPERIMENTAL none 512
}
function SET_DEFAULT_SELECTION(){
	# dependant on global variables; SELECTION
	IFS=$DIFS SELECTION=( ${SELECTION[0]} $(GET_DEFAULT_SELECTION) )
	IFS=$DIFS SELECTION=( ${SELECTION[*]:0:6} )
}
function SET_DEFAULT_NAME(){
	# dependant on global variables; NAME
	local DEVICE_SIZE=$(FORMAT_TO_GB $(GET_DEVICE_HWI_SIZE ${DEVICE}) | tr -d ' ')
	local IFS=$DIFS
	NAME=( ${NAME[0]} ${DEVICE_SIZE} )
	#IFS=$DIFS NAME=( ${NAME[0]} $(GET_DEVICE_DETAIL) )
	#IFS=$DIFS NAME=( ${NAME[0]} "${NAME[3]}${NAME[4]}" )
}
function IS_2ND_DEVICE_OPTIONAL(){
	local TSGL=${1:-${SELECTION[2]:-task}}		# TOOL_SELECTION_GROUP_LABEL
	local D2PF=${DEVICE2PROMPT_FILTERS:-task}	# DEVICE2PROMPT_FILTERS
	local D2PD=${DEVICE2PROMPT_DEFAULT:-false}	# DEVICE2PROMPT_DEFAULT
	#DEVICE2PROMPT_FILTERS; comma delimited
	#DEVICE2PROMPT_DEFAULT; when false FILTER determines single disk VM,
	#			when true  FILTER determines dual disk optional
	if grep -qif <(echo "${D2PF}" | tr , $'\n') <(echo "${TSGL}") ; then
		  ${D2PD}
	else
		! ${D2PD}
	fi
}
###########################################################################################
#################################################################################### zenity
function zenity_cmd(){
	echo $(IF_ROOT_ECHO "DISPLAY=:${TARGET_DISPLAY:-0}") zenity
	#whoami | grep -q ^root$ \
	#	&& echo DISPLAY=:${TARGET_DISPLAY:-0} zenity \
	#	|| echo zenity
}
function zenity_default_title(){
	echo VBOX Auto Launcher
	return 0
	echo	$(GET_DEVICE_INTERFACE ${DEVICE} | tr a-z A-Z) :: \
		${DEVICE} :: \
		$(FORMAT_TO_GB $(GET_DEVICE_HWI_SIZE ${DEVICE}))
}
function zenity_device_info(){
	local IFS=${DIFS}
	local DEV=$(basename "${1:-${DEVICE}}")

	# retrieve into an array the field names returned from the Disk Selection Dialog
	eval local field=( $(GET_CONFIG_SECTION \
			   "$(GET_USER_CONFIG_FQFN)" \
			    ${UCST_DISK_COLUMN_HEADERS}) )

	# retieve into an array the values returned from the Disk Selection Dialog
	eval local value=( $(GET_DEVICE_INFO_ARRAY ${DEV}) )

	# prep vars
	local index=0
	local space=10
	local spaces=$(seq ${space} | sed 's/.*/ /g' | tr -d '\n')

	# write device info
	echo '<span color=\"blue\" face=\"courier new\">'
	while (( index < ${#field[*]} )); do
		field[${index}]="${spaces}${field[${index}]}"
		field[${index}]=${field[${index}]: -${space}}
		echo "${field[${index}]} <big>::</big> ${value[$(( index++ ))]}"
	done
	echo '</span>'
}
function zenity_device_info_list(){
	local DEV=""
	local DISK_NUM=""
	for DEV in ${DEVICE[*]}; do
		echo "<b><big><span color='purple'>-VM DISK $(( DISK_NUM++ ))-</span></big></b>"
		echo "$(zenity_device_info ${DEV})\n"
	done
}
function zenity_warning_inuse(){
	# https://developer.gnome.org/pygtk/stable/pango-markup-language.html
	local IFS=${DIFS}
	local DEV=$(basename "${1:-${DEVICE}}")
	# dependant on global variables; DEVICE

	# set window title
	local zenityTitle=$(zenity_default_title)
	# warning instructions
	local zenityText=$(GET_CONFIG_SECTION "$(GET_USER_CONFIG_FQFN)" ${UCST_WARNING_INSTRUCTIONS})

	# device info to assist confirmation
	zenityText+="$(zenity_device_info ${DEV})"

	# Set zenity window position
	MOV_WINDOW "${zenityTitle}" 100 50 &

	# launch zenity dialog
	#(
		IF_ROOT_SU <<-SU 2> >(LOG - ERR :: $(GET_FUNC_CHAIN) ::)
		$(zenity_cmd)				\
			--timeout=${DIALOG_TIMEOUT:-25}	\
			--title="${zenityTitle// /   }"	\
			--text="${zenityText}"		\
			--ok-label="Confirm"		\
			--cancel-label="GO BACK"	\
			--question
		SU
	echo $?
	#) | tac | tr -d '\n'
}
function zenity_name_task(){
	# prompt user to label task/vm
	local IFS=:
	NAME=( $(zenity_name_task_dialog) )

	# exit if user choose cancel or closed dialog
	local IFS=,
	case "${NAME[0]}.${#NAME[*]}" in
		1.*)	LOG CAN :: clk_X/CAN :: Task naming dialog\; EC[${NAME[0]}] NAME["${NAME[*]:1}"] DEVICE[${DEVICE}]. Exiting\!
			EXIT 1;;
		5.1)	LOG STS :: TIMED_OUT :: Task naming dialog\; EC[${NAME[0]}] NAME["${NAME[*]:1}"] DEVICE[${DEVICE}].;;
		5.*)	LOG STS :: _LAUNCHED :: Task naming dialog\; EC[${NAME[0]}] NAME["${NAME[*]:1}"] DEVICE[${DEVICE}].;;
		*)	LOG ERR :: NEW_STATE :: Task naming dialog\; EC[${NAME[0]}] NAME["${NAME[*]:1}"] DEVICE[${DEVICE}]. Exiting\!
			EXIT 1;;
	esac

	# set default name if start vm was selected without entering a name
	(( ${#NAME[*]} > 1 )) || SET_DEFAULT_NAME

	# amend VRDEPORT and DEVICE to NAME[1]
	local IFS=' '
	NAME[1]="${NAME[1]}-$(GET_VRDEPORT ${DEVICE[0]}).${DEVICE[0]}"
	LOG INF :: NAME["${NAME[*]}"]
}
function zenity_name_task_dialog(){
	# https://developer.gnome.org/pygtk/stable/pango-markup-language.html
	local IFS=${DIFS}
	# dependant on global variables; DEVICE

	# set window title
	local zenityTitle=$(zenity_default_title)

	# inform user which disks have been choosen
	local zenityText="$(zenity_device_info_list)"
	
	# naming instructions
	zenityText+=$(GET_CONFIG_SECTION "$(GET_USER_CONFIG_FQFN)" ${UCST_NAMING_INSTRUCTIONS})

	# Set zenity window position
	MOV_WINDOW "${zenityTitle}" 100 50 &
	# launch zenity dialog
	(
		IF_ROOT_SU <<-SU 2> >(LOG - ERR :: $(GET_FUNC_CHAIN) ::)
		$(zenity_cmd)				\
			--timeout=${DIALOG_TIMEOUT:-25}	\
			--ok-label="START VM"		\
			--cancel-label="CANCEL"		\
			--title="${zenityTitle// /   }"	\
			--text="${zenityText}"		\
			--add-entry="Name"		\
			--forms
		SU
	echo $?:
	) | tac | tr -d '\n'
}
function zenity_choose_device(){
	local MAX_TRIES=20
	while (( MAX_TRIES-- )); do
		# present device selection dialog
		local IFS=:
		local SELECTION=( $(zenity_choose_device_dialog) )
		# process device selection results; first field is error code
		local IFS=,
		case "${SELECTION[0]}.${#SELECTION[*]}" in
			0.*)	LOG STS :: dbl_CLICK :: Disk selection dialog\; EC[${SELECTION[0]}] SEL["${SELECTION[*]:1}"].;;
			1.*)	LOG CAN :: clk_X/CAN :: Disk selection dialog\; EC[${SELECTION[0]}].                          Skipping\!
				break;;
			5.1)	LOG STS :: TIMED_OUT :: Or no selection\!       EC[${SELECTION[0]}] SEL["${SELECTION[*]:1}"]. Skipping\!
				break;;
			5.*)	LOG STS :: clk_NEXT_ :: Disk selection dialog\; EC[${SELECTION[0]}] SEL["${SELECTION[*]:1}"].;;
			*)	LOG ERR :: NEW_STATE :: Disk selection dialog\; EC[${SELECTION[0]}] SEL["${SELECTION[*]:1}"]. Exiting\!
				EXIT 1;;
		esac

		# if the user made a selection but the device is inuse, WARN
		if (( ${#SELECTION[*]} > 1 )) && [[ "${SELECTION[4]}" =~ ^(local|VBOX)$ ]]; then
			if (( $(zenity_warning_inuse "${SELECTION[1]}") == 5 )); then
				LOG STS :: clk_CNFRM :: DEVICE[${SELECTION[1]}].
				DEVICE[${#DEVICE[*]}]=${SELECTION[1]}
				break
			else
				LOG CAN :: clk_GOBAK :: DEV=${SELECTION[1]}
			fi
		# if the user made a selection and the device is free, MOVE ON
		elif (( ${#SELECTION[*]} > 1 )); then
			DEVICE[${#DEVICE[*]}]=${SELECTION[1]}
			break
		fi
	done
}
function zenity_choose_device_dialog(){
	local IFS=${DIFS}
	# dependant on global variables; DEVICE

	# set window title
	local zenityTitle=$(zenity_default_title)

	# inform user which disks have been choosen
	local zenityText="$(zenity_device_info_list)"

	# get selection instructions
		zenityText+=$(GET_CONFIG_SECTION \
			   "$(GET_USER_CONFIG_FQFN)" \
			    ${UCST_DISK_INSTRUCTIONS})

	# get aditional selection instructions
	if (( ${#DEVICE[*]} )); then
		zenityText+=$(GET_CONFIG_SECTION \
			   "$(GET_USER_CONFIG_FQFN)" \
			    ${UCST_DISK_INSTRUCTIONS_2})
	fi

	# get column headers
	eval local column=( $(GET_CONFIG_SECTION \
			   "$(GET_USER_CONFIG_FQFN)" \
			    ${UCST_DISK_COLUMN_HEADERS}) )

	# Set zenity window position
	MOV_WINDOW "${zenityTitle}" 12 50 &

	# launch zenity dialog
	(
		IF_ROOT_SU <<-SU 2> >(LOG - ERR :: $(GET_FUNC_CHAIN) ::)
		$(zenity_cmd)				\
			--width=500			\
			--height=700			\
			--timeout=${DIALOG_TIMEOUT:-25}	\
			--ok-label="NEXT"		\
			--cancel-label="CANCEL"		\
			--title="${zenityTitle// /   }"	\
			--text="${zenityText}"		\
			--list				\
			--print-column=ALL		\
			--separator=:			\
			--column "${column[0]}"		\
			--column "${column[1]}"		\
			--column "${column[2]}"		\
			--column "${column[3]}"		\
			--column "${column[4]}"		\
			--column "${column[5]}"		\
			--column "${column[6]}"		\
			--column "${column[7]}"		\
			$(zenity_disk_list)
	SU
	echo $?:
	) | tac | tr -d '\n'
}
function zenity_disk_list(){
	local DEV=""
	while read DEV; do
		GET_DEVICE_INFO_ARRAY ${DEV}
	done < <(GET_DEVICE_LIST)
}
function zenity_selection_list(){
	local IFS=${DIFS}
	GET_SELECTIONS |\
	while read LINE; do
		eval ARGS=( ${LINE} )
		echo -n ${ARGS[0]} \"${ARGS[1]}\" \"${ARGS[2]}\" ""
	done
}
function zenity_choose_tool(){
	# prompt user to choose tool or disregard
	local IFS=:
	SELECTION=( $(zenity_choose_tool_dialog) )

	# exit if user chose cancel or closed dialog
	local IFS=,
	case "${SELECTION[0]}.${#SELECTION[*]}" in
		0.*)	LOG STS :: dbl_CLICK :: Task selection dialog\; EC[${SELECTION[0]}] SEL["${SELECTION[*]:1}"}].;;
		1.*)	LOG CAN :: clk_X/CAN :: Task selection dialog\; EC[${SELECTION[0]}] DEVICE[${DEVICE}].        Exiting\!
			EXIT 1;;
		5.1)	LOG STS :: TIMED_OUT :: Task selection dialog\; EC[${SELECTION[0]}] SEL["${SELECTION[*]:1}"}].;;
		5.*)	LOG STS :: clk_NEXT_ :: Task selection dialog\; EC[${SELECTION[0]}] SEL["${SELECTION[*]:1}"}].;;
		*)	LOG ERR :: NEW_STATE :: Task selection dialog\; EC[${SELECTION[0]}] SEL["${SELECTION[*]:1}"}]. Exiting\!
			EXIT 1;;
	esac

	# set default if next was selected without chooseing a tool
	(( ${#SELECTION[*]} > 1 )) && GET_SELECTION_DETAILS || SET_DEFAULT_SELECTION
}
function zenity_choose_tool_dialog(){
	# https://developer.gnome.org/pygtk/stable/pango-markup-language.html
	local IFS=${DIFS}
	# dependant on global variables; DEVICE
	
	# set window title
	local zenityTitle=$(zenity_default_title)

	# inform user which disks have been choosen
	local zenityText="$(zenity_device_info_list)"

	# get selection instructions
	zenityText+=$(GET_CONFIG_SECTION \
		   "$(GET_USER_CONFIG_FQFN)" \
		    ${UCST_TOOL_INSTRUCTIONS})

	# get column headers
	eval local column=( $(GET_CONFIG_SECTION \
			   "$(GET_USER_CONFIG_FQFN)" \
			    ${UCST_TOOL_COLUMN_HEADERS}) )

	# Set zenity window position
	MOV_WINDOW "${zenityTitle}" 100 50 &
	# launch zenity dialog
	(
		IF_ROOT_SU <<-SU 2> >(LOG - ERR :: $(GET_FUNC_CHAIN) ::)
		$(zenity_cmd)				\
			--width=300			\
			--height=700			\
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
		SU
	echo $?:
	) | tac | tr -d '\n'
}
###########################################################################################
######################################################################### device info array
function GET_DEVICE_INFO_ARRAY(){
	local DEV=$(basename "${1:-${DEVICE}}")
	if [ ! -f "/dev/shm/$$${FUNCNAME}_${DEV}" ]; then
		cat <<-SHMF > "/dev/shm/$$${FUNCNAME}_${DEV}"
			"${DEV}"
			"$(GET_DEVICE_INTERFACE			${DEV} | tr a-z A-Z)"
			"$(FORMAT_TO_GB $(GET_DEVICE_HWI_SIZE	${DEV}))"
			"$(GET_DEVICE_MOUNT			${DEV})"
			"$(GET_DEVICE_MOUNT_STATUS		${DEV})"
			"$(GET_DEVICE_MOUNT_LOCATION		${DEV})"
			"$(GET_DEVICE_HWI_MODEL			${DEV})"
			"$(GET_DEVICE_HWI_SERIAL		${DEV})"
		SHMF
	fi
	echo -n $(cat "/dev/shm/$$${FUNCNAME}_${DEV}" | tr '\n' \ ) \ 
}
function GET_DEVICE_MOUNT(){
	local DEV=$(basename "${1:-${DEVICE}}")

	# test for running VBOX
	if DOES_VBOX_DEVICE_VMDK_EXIST ${DEV} && IS_VBOX_MACHINE_RUNNING $(GET_DEVICE_VBOX_MACHINE_UUID ${DEV}); then
		echo VBOX
		return 0
	# test for mounted partition
	elif grep -q "^/dev/${DEV}[0-9]*[[:space:]]" /etc/mtab; then
		echo local
		return 0
	# test for off-line VBOX
	elif DOES_VBOX_DEVICE_VMDK_EXIST ${DEV}; then
		echo VBOX
		return 0
	else
		echo ...
		return 1
	fi


	# old code
	echo ...
	return 1
	
	# test mtab
	if grep -q "^/dev/${DEV}[0-9]*[[:space:]]" /etc/mtab; then
		echo local
		return 0
	fi

	# test vboxmanager list hdds
	if GET_VBOX_HDD_LIST | grep -q "^Location:[[:space:]].*/${DEVICE_VMDK_FILE_NAME}\$"; then
		echo VBOX
		return 0
	else
		echo ...
		return 1
	fi
}
function GET_DEVICE_MOUNT_STATUS(){
	local DEV=$(basename "${1:-${DEVICE}}")
	local DEVICE_MOUNT=$(GET_DEVICE_MOUNT ${DEV})

	case "${DEVICE_MOUNT}" in
		local)	echo browsable
			;;
		VBOX)	local DEVICE_VBOX_MACHINE_UUID=$(GET_DEVICE_VBOX_MACHINE_UUID ${DEV})
			IS_VBOX_MACHINE_RUNNING ${DEVICE_VBOX_MACHINE_UUID} \
				&& echo RUNNING \
				|| echo off-line
			;;
		*)	echo ...
			;;
	esac
}
function GET_DEVICE_MOUNT_LOCATION(){
	local DEV=$(basename "${1:-${DEVICE}}")
	local DEVICE_MOUNT=$(GET_DEVICE_MOUNT ${DEV})

	case "${DEVICE_MOUNT}" in
		local)	local _DEV="" MOUNT="" x="" CNT=1 IFS=${DIFS}
			while read _DEV MOUNT x; do
				echo [$(( CNT++ ))] ${_DEV##*/}..${MOUNT}
			done < <(grep "^/dev/${DEV}[0-9]*[[:space:]]" /etc/mtab)
			;;
		VBOX)	echo $(GET_DEVICE_VBOX_MACHINE ${DEV})
			;;
		*)	echo ...
			return 1
			;;
	esac
}
###########################################################################################
############################################################ vboxmanage list vms/runningvms
function GET_VBOX_LIST_VMS(){
	IF_ROOT_SU <<-SU 2> >(LOG - ERR :: $(GET_FUNC_CHAIN) ::)
		which vboxmanage && vboxmanage list vms
	SU
}
function GET_VBOX_LIST_RUNNINGVMS(){
	IF_ROOT_SU <<-SU 2> >(LOG - ERR :: $(GET_FUNC_CHAIN) ::)
		which vboxmanage && vboxmanage list runningvms
	SU
}
function IS_VBOX_MACHINE_RUNNING(){
	# provide vbox machine uuid or name (case insensative)
	local VBOX_MACHINE_ID=${1//[{\}]/}
	[ -z "${VBOX_MACHINE_ID}" ] && return 1
	local VBOX_MACHINE=""
	local IFS=${DIFS}
	local line=""
	while read line; do
		# split name and uuid into fields 0 and 1 of array
		eval VBOX_MACHINE=( $(echo "${line//[{\}]/}") )
		# test vbox machine name, partial OK
		echo "${VBOX_MACHINE[0]}" | grep -iq "${VBOX_MACHINE_ID}$"  && return 0
		# test vbox machine name, partial OK
		echo "${VBOX_MACHINE[0]}" | grep -iq "^${VBOX_MACHINE_ID}"  && return 0
		# test vbox machine uuid, compleate required for match
		echo "${VBOX_MACHINE[1]}" | grep -iq "^${VBOX_MACHINE_ID}$" && return 0
	done < <(GET_VBOX_LIST_RUNNINGVMS)
	return 1
}
function GET_VBOX_MACHINE_NAME(){
	local DEV=$(basename "${1:-${DEVICE}}")
	local TARGET_VM_MASK="$(GET_VRDEPORT ${DEV}).${DEV}"
	local IFS=${DIFS}
	eval local MACHINE=( "$(GET_VBOX_LIST_VMS | grep ${TARGET_VM_MASK})" )
	echo "${MACHINE[0]}"
}
function GET_VBOX_MACHINE_UUID(){
	local DEV=$(basename "${1:-${DEVICE}}")
	local TARGET_VM_MASK="$(GET_VRDEPORT ${DEV}).${DEV}"
	local IFS=${DIFS}
	eval local MACHINE=( "$(GET_VBOX_LIST_VMS | grep ${TARGET_VM_MASK})" )
	echo "${MACHINE[0]}" | sed 's/[{}]//g' 2> >(LOG - ERR :: ${FUNCNAME} ::)
}
function DOES_VBOX_DEVICE_VMDK_EXIST(){
	local DEV=$(basename "${1:-${DEVICE}}")
	local DEVICE_VMDK_FILE_NAME="$(GET_DEVICE_VMDK_FILE_NAME ${DEV})"
	
	# test
	GET_VBOX_HDD_LIST | grep -q "^Location:[[:space:]].*/${DEVICE_VMDK_FILE_NAME}\$"
}
function IS_VBOX_USING_DEVICE(){
	local DEV=$(basename "${1:-${DEVICE}}")

	DOES_VBOX_DEVICE_VMDK_EXIST ${DEV} &&\
	IS_VBOX_MACHINE_RUNNING $(GET_DEVICE_VBOX_MACHINE_UUID ${DEV})
}
###########################################################################################
###################################################################### vboxmanage list hdds
function GET_VBOX_HDD_LIST(){
	IF_ROOT_SU <<-SU 2> >(LOG - ERR :: $(GET_FUNC_CHAIN) ::)
		which vboxmanage && vboxmanage list hdds
	SU
}
function SET_VBOX_HDDS_LIST_SHMF(){
	local SHMF=$1
	cat <<-SED | sed -n -f <(cat) <(GET_VBOX_HDD_LIST) \
	1> "${SHMF}" 2> >(LOG - ERR :: $(GET_FUNC_CHAIN) ::)
		/^UUID:/,/^$/{
			/^UUID:/{h;d}
			/^$/d
			G
			s/\(.*\)\nUUID:[[:space:]]\+\(.*\)/\2\ \1/p
		}
	SED
}
function GET_VBOX_HDD_ATTRIBUTE(){
	local rEGEX=$1
	shift
	local ATTRIB=$*

	[ -f "/dev/shm/$$${FUNCNAME}" ] || SET_VBOX_HDDS_LIST_SHMF "/dev/shm/$$${FUNCNAME}"

	cat <<-SED | sed -n -f <(cat) "/dev/shm/$$${FUNCNAME}" 2> >(LOG - ERR :: ${FUNCNAME} ::)
		/[[:space:]]${ATTRIB}[[:space:]]/{
			\|${rEGEX}|p
		}
	SED
}
function GET_DEVICE_VBOX_UUID(){
	local DEV=$(basename "${1:-${DEVICE}}")
	local DEVICE_VMDK_FILE_NAME="$(GET_DEVICE_VMDK_FILE_NAME ${DEV})"
	
	local IFS=${DIFS}
	local DATA=( $(GET_VBOX_HDD_ATTRIBUTE "/${DEVICE_VMDK_FILE_NAME}\$" Location:) )
	if [ -n "${DATA[0]}" ]; then
		echo "${DATA[0]}"
	else
		echo ---
	fi
}
function GET_DEVICE_VBOX_LOCATION(){
	local DEV=$(basename "${1:-${DEVICE}}")
	local DEVICE_VMDK_FILE_NAME="$(GET_DEVICE_VMDK_FILE_NAME ${DEV})"

	local IFS=${DIFS}
	local DATA=( $(GET_VBOX_HDD_ATTRIBUTE "/${DEVICE_VMDK_FILE_NAME}\$" Location:) )
	echo "${DATA[*]:2}"
}
function GET_DEVICE_VBOX_MACHINE_UUID(){
	local DEV=$(basename "${1:-${DEVICE}}")
	local VBOX_UUID=$(GET_DEVICE_VBOX_UUID ${DEV})

	local IFS=${DIFS}
	local DATA=( $(GET_VBOX_HDD_ATTRIBUTE "^${VBOX_UUID}" Usage:) )
	echo "${DATA[*]: -1}" | sed 's/)$//' 2> >(LOG - ERR :: ${FUNCNAME} ::)
}
function GET_DEVICE_VBOX_MACHINE(){
	local DEV=$(basename "${1:-${DEVICE}}")
	local VBOX_UUID=$(GET_DEVICE_VBOX_UUID ${DEV})

	local IFS=${DIFS}
	local DATA=( $(GET_VBOX_HDD_ATTRIBUTE "^${VBOX_UUID}" Usage:) )
	echo "${DATA[*]:2:${#DATA[*]}-4}"
}
###########################################################################################
########################################################## user-names, file-names and paths
function IF_ROOT_ECHO(){
	local IFS=${DIFS}
	whoami | grep -q ^root$ && echo "$@"
}
function IF_ROOT_SU(){
	if whoami | grep -q ^root$; then
		cat | su - $(GET_DISPLAY_USER ${DISPLAY:-${TARGET_DISPLAY:-0}}) -s /bin/bash
	else
		cat | /bin/bash
	fi
}
function GET_USERNAME(){
	IF_ROOT_SU <<-SU
		whoami
	SU
}
function GET_HOME_DIR(){
	GET_USER_HOME_DIR $(GET_USERNAME)
}
function GET_DEVICE_VMDK_FILE_NAME(){
	echo udev.$(basename "${1:-${DEVICE}}").vmdk
}
function GET_DEVICE_VMDK_FILE_FQFN(){
	local DEVICE_VMDK_FILE_NAME=$(GET_DEVICE_VMDK_FILE_NAME "$1")
	echo "$(GET_HOME_DIR)/.VirtualBox/${DEVICE_VMDK_FILE_NAME}"
}
function GET_PROGRAM_NAME(){
	if (( ${#PROGRAM_NAME} > 0 )); then
		echo "${PROGRAM_NAME}"
	else
		PROGRAM_NAME=$(basename "${BASH_SOURCE}" .sh)
		GET_PROGRAM_NAME
	fi
}
function GET_ETC_CONFIG_DIR(){
	local PROGRAM_NAME=$(GET_PROGRAM_NAME)
	echo "/etc/${PROGRAM_NAME// /_}"
}
function GET_INSTALL_CONFIG_DIR(){
	local PROGRAM_NAME=$(GET_PROGRAM_NAME)
	if [      -d "${BASH_SRCDIR}/..$(GET_ETC_CONFIG_DIR)" ]; then
		echo "${BASH_SRCDIR}/..$(GET_ETC_CONFIG_DIR)"
	elif [    -d "${BASH_SRCDIR}/../etc/${PROGRAM_NAME// /_}" ]; then
		echo "${BASH_SRCDIR}/../etc/${PROGRAM_NAME// /_}"
	elif [    -d "${BASH_SRCDIR}/${PROGRAM_NAME// /_}" ]; then
		echo "${BASH_SRCDIR}/${PROGRAM_NAME// /_}"
	elif [    -d "${BASH_SRCDIR}/../${PROGRAM_NAME// /_}" ]; then
		echo "${BASH_SRCDIR}/../${PROGRAM_NAME// /_}"
	else
		echo "${BASH_SRCDIR}"
	fi
}
function GET_USER_CONFIG_DIR(){
	local USER_CONFIG_DIR="$(GET_HOME_DIR)/${USER_CONFIG_DIR_RELATIVE}"
	[ -d "${USER_CONFIG_DIR}" ] \
		&& echo "${USER_CONFIG_DIR}" \
		|| echo "/tmp/$$"
}
function GET_USER_CONFIG_FQFN(){
	local USER_CONFIG_FQFN="$(GET_USER_CONFIG_DIR)/${USER_CONFIG_FILE_NAME}"
	local ETC_CONFIG_FQFN="$(GET_ETC_CONFIG_DIR)/${USER_CONFIG_FILE_NAME}"
	local INSTALL_CONFIG_FQFN="$(GET_INSTALL_CONFIG_DIR)/${USER_CONFIG_FILE_NAME}"
	if [ -f "${USER_CONFIG_FQFN}" ]; then
		echo "${USER_CONFIG_FQFN}"
		return 0
	elif [ -f "${ETC_CONFIG_FQFN}" ]; then
		LOG ERR :: $(GET_FUNC_CHAIN) :: File \"${USER_CONFIG_FQFN}\" not found.  Using \"${ETC_CONFIG_FQFN}\".
		echo "${ETC_CONFIG_FQFN}"
		return 1
	elif [ -f "${INSTALL_CONFIG_FQFN}" ]; then
		LOG ERR :: $(GET_FUNC_CHAIN) :: File \"${USER_CONFIG_FQFN}\" not found.  Using \"${INSTALL_CONFIG_FQFN}\".
		echo "${INSTALL_CONFIG_FQFN}"
		return 1
	else
		LOG ERR :: $(GET_FUNC_CHAIN) :: All alternate config files missing\!  Exiting.
		EXIT 1
	fi
}
###########################################################################################
############################################################################# miscellaneous
function OPEN_POPUP_LOG(){
	${POPUP_LOG:-false} || return
	# background launch terminator 
	IF_ROOT_SU <<-SU &> >(LOG - INF :: ${FUNCNAME} ::) &
		$(IF_ROOT_ECHO "DISPLAY=:${TARGET_DISPLAY:-0}") terminator	\
			-m -b							\
			-T "$(zenity_default_title)"				\
			-e "tail -f \"${LOG}\""
	SU
	POPUP_LOG_PID=$!
	sleep 2
	POPUP_LOG_PID=$(FIND_PID ${POPUP_LOG_PID} tail)
	LOG INF :: ${FUNCNAME} :: PID[${POPUP_LOG_PID}]
}
function UNMOUNT_DEVICES(){
	local TRIES=""
	local PART=""
	local DEV=""
	for DEV in ${DEVICE[*]}; do
		for PART in `ls /dev/${DEV}[0-9]`; do
			for TRIES in {1..2}; do
				sudo -n umount ${PART} &>/dev/null
			done
			sudo -n umount -v ${PART} \
				1> >(LOG - STS :: ${FUNCNAME} ::) \
				2> >(LOG - ERR :: ${FUNCNAME} ::)
		done
	done
}
function EXIT(){
	# cleanup
	rm -rf "${TMP}"
	rm -rf "${SHM}"
	rm -rf "/dev/shm/$$"*
	if ${POPUP_LOG:-false}; then
		echo INFO :: ${FUNCNAME} :: POPUP_LOG_PID = ${POPUP_LOG_PID} >> "${LOG}"
		eval "sleep ${POPUP_LOG_AUTOCLOSE_DELAY}; kill ${POPUP_LOG_PID};"
	fi
	exit ${1:- 0}
}
###########################################################################################
###########################################################################################
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

# GLOBAL vars; LOG file must exist 
if (( ${#LOG} == 0 )) || [ ! -f "${LOG}" ]; then
	LOG=$(basename "${BASH_SRCNAME}" .sh)
	LOG="/var/log/${LOG}.log"
fi

# Target DISPLAY to popup dialogs and create VM's
TARGET_DISPLAY=${TARGET_DISPLAY:-0}
TARGET_DISPLAY=${TARGET_DISPLAY//[^0-9.]/}

# udev rule file name
UDEV_RULE_CONFIG_FILE_NAME_DEFAULT=${UDEV_RULE_CONFIG_FILE_NAME_DEFAULT:-99-customUDEV.rules}

# GLOBAL vars; User Config Section Titles (UCST_) 
UCST_TOOL_SELECTIONS=${UCST_TOOL_SELECTIONS:-Task List Selections}
UCST_TOOL_INSTRUCTIONS=${UCST_TOOL_INSTRUCTIONS:-Task Selection Instructions}
UCST_TOOL_COLUMN_HEADERS=${UCST_TOOL_COLUMN_HEADERS:-Task List Column Headers}
UCST_DISK_INSTRUCTIONS=${UCST_DISK_INSTRUCTIONS:-Disk Selection Instructions}
UCST_DISK_COLUMN_HEADERS=${UCST_DISK_COLUMN_HEADERS:-Disk List Column Headers}
UCST_NAMING_INSTRUCTIONS=${UCST_NAMING_INSTRUCTIONS:-Naming Instructions}
UCST_WARNING_INSTRUCTIONS=${UCST_WARNING_INSTRUCTIONS:-Warning Instructions}
UCST_GLOBAL_VAR_DEFAULTS=${UCST_GLOBAL_VAR_DEFAULTS:-Global Defaults}

# User Task Managment Folder
USER_CONFIG_DIR_RELATIVE=${USER_CONFIG_DIR_RELATIVE:-ISO}
USER_CONFIG_FILE_NAME=${USER_CONFIG_FILE_NAME:-${USER_CONFIG_FILE_NAME_DEFAULT:-tool.list.txt}}


# GLOBAL vars; source user config file
if whoami | grep -q ^root$; then
	SOURCE_CONFIG_GLOBAL_VARS <(GET_CONFIG_SECTION "$(GET_USER_CONFIG_FQFN)" ${UCST_GLOBAL_VAR_DEFAULTS})
else
	SOURCE_CONFIG_GLOBAL_VARS <(GET_CONFIG_SECTION "$(GET_USER_CONFIG_FQFN)" ${UCST_GLOBAL_VAR_DEFAULTS})
fi

# GLOBAL vars; source kernel boot line
KERNEL_CMD_LINE_VAR=${KERNEL_CMD_LINE_VAR:-${KERNEL_CMD_LINE_VAR_DEFAULT:-DISABLE}}
KERNEL_BOOT_PREFIX=${KERNEL_BOOT_PREFIX:-${KERNEL_BOOT_PREFIX_DEFAULT:-DISABLE}}
KERNEL_CMD_LINE=${!KERNEL_CMD_LINE}
if (( ${#KERNEL_CMD_LINE} )); then
	eval $(echo ${KERNE_CMD_LINE} | tr \  \\n | sed -n "s/^${KERNEL_BOOT_PREFIX}//p")
fi

# GLOBAL vars; mac address base, vrdeport base, DIALOG_TIMEOUT
MAC=${MAC:-080027ABCD}
MAC=${MAC//:/}
MAC=${MAC:0:10}
VRDEPORT=${VRDEPORT:-33890}
DIALOG_TIMEOUT=${DIALOG_TIMEOUT:-25}
BRIDGED_ETH=${BRIDGED_ETH:-eth0}
DISABLE_BRIDGED_ETH=${DISABLE_BRIDGED_ETH:-${DISABLE_BRIDGED_ETH_DEFAULT:-false}}
#DEVICE2PROMPT_FILTERS; comma delimited
#DEVICE2PROMPT_DEFAULT; when false FILTER determines single disk VM,
#			when true  FILTER determines dual disk optional
DEVICE2PROMPT_FILTERS=${DEVICE2PROMPT_FILTERS:-task}
DEVICE2PROMPT_DEFAULT=${DEVICE2PROMPT_DEFAULT:-false}
VBOX_SUPPRESS_MESSAGES=${VBOX_SUPPRESS_MESSAGES:-remindAboutAutoCapture,confirmInputCapture,remindAboutMouseIntegrationOn,remindAboutWrongColorDepth,confirmGoingFullscreen,remindAboutMouseIntegrationOff}

# GLOBAL vars; VirtualBox
SCTL='ide'

# GLOBAL vars; TMP
TMP="/tmp/$$_${BASH_SRCNAME}_$$"
mkdir    "${TMP}"
chmod +t "${TMP}"
SHM="/dev/shm/$$_${BASH_SRCNAME}_$$"
mkdir    "${SHM}"
chmod +t "${SHM}"

# GLOBAL vars; DIFS = default array delimiter
#DIFS=${IFS}
DIFS=' '

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

#for DEV in `GET_DEVICE_LIST`; do
#	echo $DEV	:: `GET_DEVICE_HWI_MODEL  ${DEV}`\
#			:: `GET_DEVICE_HWI_SERIAL ${DEV}`\
#			:: `FORMAT_TO_GB $(GET_DEVICE_HWI_SIZE ${DEV})`
#done

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



