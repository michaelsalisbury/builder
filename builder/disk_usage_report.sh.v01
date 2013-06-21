#!/bin/bash

source functions.format.sh
SET_MAX_WIDTH_BY_COLS 80

echo "XXX$(PAD_CNTR 10 " " \##)XXX"
REPC 16 \#
echo
PAD_ANCHOR_CNTR_SPLIT -,-e 10 I am a monkey - This is so cool
PAD_CNTR \# "0123456789"
PAD_ANCHOR_CNTR_SPLIT \#,-p 1,25% I am a monkey - This is so cool
PAD_CNTR \# "0123456789"
echo
echo "XXX$(PAD_CNTR 4 ' ' '=')XXX"
echo "XXX$(PAD_CNTR 3 ' ' '=')XXX"
echo "XXX$(PAD_CNTR 2 ' ' '=')XXX"
echo "XXX$(PAD_CNTR 1 ' ' '=')XXX"


exit


PAD_CNTR \# one

echo $MAX_WIDTH
echo $COLUMNS

REPC \Q

PAD_ANCHOR_CNTR_R - Cat man doooo
PAD_ANCHOR_CNTR_L - Cat man doooo
PAD_CNTR - Cat man doooo

echo

REPC _

PAD_SPLIT : I am a monster - so what
PAD_SPLIT : -: I am a monster - so what
PAD_SPLIT : -: I am a monster : so what

exit



PAD_ANCHOR_L 50 \# hello1
PAD_ANCHOR_L 50 \# hello2
PAD_ANCHOR_L 50 \# hello3\#
PAD_ANCHOR_L \# hello1
PAD_ANCHOR_L \# hello2
PAD_ANCHOR_L \# hello3\#
MAX_WIDTH=75
PAD_ANCHOR_L \# hello1
PAD_ANCHOR_L \# hello2
PAD_ANCHOR_L \# \#hello3
PAD_ANCHOR_R 50 \# hello1
PAD_ANCHOR_R 50 \# hello2
PAD_ANCHOR_R 50 \# \#hello3
PAD_ANCHOR_R \# hello1
PAD_ANCHOR_R \# hello2
PAD_ANCHOR_R \# \#hello3
MAX_WIDTH=30
PAD_ANCHOR_R \# hello1
PAD_ANCHOR_R \# hello2
PAD_ANCHOR_R \# \#hello3
exit



TITLE_LENGTH=80
TITLE_OFFSET=0
CNTR '#' ${TITLE_LENGTH} "$(REPC ${TITLE_OFFSET} '#') Overall File System Usage"
echo
	cat <<-SED | sed -f <(cat) <(df -h) | column -t | sed 's/^/\t/'
		s/[[:space:]]*on$/-on/
		s/[^ ][^ ]*/& ::/
		s/[^ ]*$/:: &/
	SED

echo
echo
CNTR '#' ${TITLE_LENGTH} "$(REPC ${TITLE_OFFSET} '#') Home Directory Usage"

	du -cksh /export/home/* |\
	sed -f <(cat <<-SED
			s/^\([0-9.]*\)\([[:space:]]\)/\1\tbytes\t/
			s/^\([0-9.]*\)\([MKG]\)/\1\t\2B/
			s/\([[:space:]]\)\(bytes\)\([[:space:]]\)/\13\2\3/
			s/\([[:space:]]\)\(KB\)\([[:space:]]\)/\12\2\3/
			s/\([[:space:]]\)\(MB\)\([[:space:]]\)/\11\2\3/
			s/\([[:space:]]\)\(GB\)\([[:space:]]\)/\10\2\3/
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
			\$i\---------------------------------------------
		SED
	) |\
	sed 's/^/\t/'

echo
echo
CNTR '#' ${TITLE_LENGTH} "$(REPC ${TITLE_OFFSET} '#') Software Raid Devices"
echo
	ls /dev/md[0-9] |\
	while read DEV; do
		DETAIL=$(grep "${DEV}" /etc/mtab | awk '{print $2}')
		DETAIL=${DETAIL:-not-mounted}
		echo -e 'DEVICE ::' ${DEV} ${DETAIL}
	done |\
	column -t |\
	sed 's/^/\t/'

	ls /dev/md[0-9] |\
	while read DEV; do
		cat <<-SED | sed -n -f <(cat) <(mdadm --detail "${DEV}")
		#1s/\$/ _____________________________________________________/p
		1{
			i\_______________________________________________________________
			p
		}
		/Raid Level :/p
		/State :/p
		/Persistence :/p
		/Number/,\${
			/Number/i\    -----------------------------------------
			p
		}
		SED
	done


echo
echo
CNTR '#' ${TITLE_LENGTH} "$(REPC ${TITLE_OFFSET} '#') Hard Disk Smart Reports"
echo
	ls /dev/sd[a-z] |\
	while read DEV; do
		DETAIL=$(lshw -class disk -short |\
			grep "${DEV}" |\
			awk '$1="";$3="";{print}')
		echo 'DEVICE ::' "${DETAIL}"
		echo
		smartctl -H ${DEV} | tail -n +5 | sed 's/^/\t/'
		echo
	done

