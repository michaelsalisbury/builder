#!/bin/builder.sh
#!/bin/env /bin/builder.sh
skip=( true true false true true false )
step=1
prefix="run"
source="https://raw.github.com/michaelsalisbury/builder/master/reports/${scriptName}"

function includes(){
	#functions.*.sh
	#../functions/functions.*.sh
	functions.format.sh
}

# GLOBAL VARIABLES
function global_variables(){
	#TITLE_LENGTH=80
	#TITLE_OFFSET=0
	MAX_WIDTH=80
	SEP_WIDTH=50
}
function run_File_System_Usage_Report(){
	SET_MAX_WIDTH_BY_COLS
	REPC     \#
	PAD_CNTR \# Overall File System Usage
	echo
	cat <<-SED | sed -f <(cat) <(df -h) | column -t | sed 's/^/\t/'
		s/[[:space:]]*on$/-on/
		s/[^ ][^ ]*/& ::/
		s/[^ ]*$/:: &/
	SED
	echo
	echo
}
function run_Home_Directory_Usage_Report(){
	SET_MAX_WIDTH_BY_COLS	
	REPC     \#
	PAD_CNTR \# Home Directory Usage

	#du -cksh /home/* |\
	du -cksh /export/home/* |\
	sed -f <(cat <<-SED
			s/^\([0-9.]*\)\([[:space:]]\)/\1\tbytes\t/
			s/^\([0-9.]*\)\([MKGT]\)/\1\t\2B/
			s/\([[:space:]]\)\(bytes\)\([[:space:]]\)/\14\2\3/
			s/\([[:space:]]\)\(KB\)\([[:space:]]\)/\13\2\3/
			s/\([[:space:]]\)\(MB\)\([[:space:]]\)/\12\2\3/
			s/\([[:space:]]\)\(GB\)\([[:space:]]\)/\11\2\3/
			s/\([[:space:]]\)\(TB\)\([[:space:]]\)/\10\2\3/
		SED
	) |\
	sort -r -k2,2 -k1,1n |\
	sed -f <(cat <<-SED
			s/\([[:space:]]\)\([0-4]\)\([^[:space:]]*[[:space:]]\)/\1\3/
 			0,/[[:space:]]KB[[:space:]]/{
				/[[:space:]]KB[[:space:]]/i
			}
 			0,/[[:space:]]MB[[:space:]]/{
				/[[:space:]]MB[[:space:]]/i
			}
 			0,/[[:space:]]GB[[:space:]]/{
				/[[:space:]]GB[[:space:]]/i
			}
 			0,/[[:space:]]TB[[:space:]]/{
				/[[:space:]]TB[[:space:]]/i
			}
			\$i$(REPC ${SEP_WIDTH} -)
		SED
	) |\
	sed 's/^/\t/'
	echo
	echo
}
function run_Software_RAID_Device_Status(){
	SET_MAX_WIDTH_BY_COLS	
	REPC     \#
	PAD_CNTR \# Software Raid Device Status
	echo
	ls /dev/md[0-9] 2>/dev/null |\
	while read DEV; do
		DETAIL=$(grep "${DEV}" /etc/mtab | awk '{print $2}')
		DETAIL=${DETAIL:-not-mounted}
		echo -e 'DEVICE ::' ${DEV} ${DETAIL}
	done |\
	column -t |\
	sed 's/^/\t/'

	ls /dev/md[0-9] 2>/dev/null |\
	while read DEV; do
		cat <<-SED | sed -n -f <(cat) <(mdadm --detail "${DEV}")
		1{
			i$(REPC 63 -u)
			p
		}
		/Raid Level :/p
		/State :/p
		/Persistence :/p
		/Number/,\${
			/Number/i\    $(REPC 41 -)
			p
		}
		SED
	done
	echo
	echo
}
function run_Hard_Disk_Smart_Reports(){
	SET_MAX_WIDTH_BY_COLS	
	REPC     \#
	PAD_CNTR \# Hard Disk Smart Reports
	echo
	/bin/bash <(smart_report_script)
}
function run_Node_Hard_Disk_Smart_Reports(){
	SET_MAX_WIDTH_BY_COLS	
	REPC     \#
	PAD_CNTR \# Node Hard Disk Smart Reports

	local hostname
	rocks list host 			|\
		awk -F: '{print $1}'		|\
		tail -n +3			|\
		while read hostname; do
			smart_report_script	|\
			ssh ${hostname} "/bin/bash <(cat)"
		done

}
function smart_report_script(){
	cat <<-CMDS
		hostname
		ls /dev/sd[a-z] |\
		while read DEV; do
			fdisk -l \${DEV}	|\
				grep ^Disk	|\
				sed 's/,.*\$//' |\
				sed 's/^/\t/'

			hdparm -i \${DEV}	|\
				grep Model	|\
				tr , '\n'	|\
				tr -d ' '	|\
				sed 's/^/\t\t/'

			smartctl -H \${DEV}	|\
				grep '^SMART'	|\
				sed 's/^/\t\t/'
			
			smartctl -H \${DEV}	|\
				sed -n '/Please.note.*marginal/,/:\$/p'		 |\
				awk '/^[0-9]/{print "SMART marginall event: "\$2}'|\
				sed 's/^/\t\t/'
		done
	CMDS
}

