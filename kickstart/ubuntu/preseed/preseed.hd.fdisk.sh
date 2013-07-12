#!/bin/sh

to_K () { local size=$1; echo $(( size *  1000 )); }
in_K () { local size=$1; echo $(( size /  1000 )); }
to_M () { local size=$1; echo $(( size * (1000 * 1000) )); }
in_M () { local size=$1; echo $(( size / (1000 * 1000) )); }
to_G () { local size=$1; echo $(( size * (1000 * 1000 * 1000) )); }
in_G () { local size=$1; echo $(( size / (1000 * 1000 * 1000) )); }

stall () {
	local delay=${1:- 5}
	for i in `seq $delay -1 1`; do
		echo -n ${i}..
		sleep 1
	done
	echo
	return 0
}
get_primary_disk () {
	#echo /dev/sda
	list-devices disk | sed '\|^/dev/|p;d' | head -1 
}
has_extended_part () {
	local dev=$1
	local cnt=$(fdisk -l $dev | sed "\|${dev}[1-4][ \t].*Extended|p;d" | wc -l)
	[ "${cnt}" -gt "0" ] \
		&& return 0 \
		|| return 1
}
get_units () {
	local dev=$1
	fdisk -lu $dev 2> /dev/null | sed '/^Units/{ s/.*=//; s/[^0-9]//g p};d'
}
get_part_list () {
	local dev=$1
	fdisk -l | sed "\|^${dev}| s/ .*// p; d"
}
get_primary_part_list () {
	local dev=$1
	fdisk -l | sed "\|^${dev}[1-4][ \t]| s/ .*// p ; d"
}
get_disk_size () {
	local dev=$1
	fdisk -lu $dev 2> /dev/null | sed '/Disk.*bytes/ { s/[:, ][:, ]*/:/g;   p };d' | cut -d: -f5
}
get_part_size () {
	local dev=$1
	get_disk_size $dev
}
get_disk_used () {
	local dev=$1
	local parts=$(get_part_list $dev)
	for part in $parts; do
		local size=$(get_part_size $part)
		local total=$(( total + size ))
	done
	echo ${total:- 0}
}
get_disk_free () {
	local dev=$1
	local size=$(get_disk_size $dev)
	local used=$(get_disk_used $dev)
	local diff=$(( size - used ))
	echo $diff
}
has_free_space () {
	local dev=$1
	local min=${2:- $(to_G 10)} # 1 gig
	local free=$(get_disk_free $dev)
	[ "${free}" -gt "${min}" ] \
		&& return 0 \
		|| return 1
}
get_primary_part_free_cnt () {
	local dev=$1
	local cnt=$(get_primary_part_cnt $dev)
	local cnt=$(( 4 - cnt ))
	echo $cnt
}
has_primary_part_free () {
	local dev=$1
	local parts=${2:- 1}
	local cnt=$(get_primary_part_free_cnt $dev)
	[ "${cnt}" -ge "${parts}" ] \
		&& return 0 \
		|| return 1
}
get_primary_part_cnt () {
	local dev=$1
	local cnt=$(get_primary_part_list $dev | wc -l)
	echo $cnt
}
has_primary_parts () {
	local dev=$1
	local parts=${2:- 1}
	local cnt=$(get_primary_part_cnt $dev)
	[ "${cnt}" -ge "${parts}" ] \
		&& return 0 \
		|| return 1
}
cmd () {
	cat << END-OF-MSG > /tmp/preseed/preseed.cmd.sh
	# jump to tty6 to display message
	exec < /dev/tty6 > /dev/tty6 2> /dev/tty6
	chvt 6
	# Welcome to your early preseed interactive shell.
	echo
	/bin/sh
	# jump back to anaconda and preseed
	chvt 1
	exec < /dev/tty1 > /dev/tty1 2> /dev/tty1
	exit 0
END-OF-MSG
	# execute script
	/bin/sh /tmp/preseed/preseed.cmd.sh
}
msg () {
	# write long messages to /tmp/preseed/preseed.txt before calling this function
	# get delay
	if echo "$1" | egrep -q '^[0-9]+$'; then
		local delay=$(echo $(seq $1 -1 1))
		shift
	else
		local delay=$(echo $(seq 10 -1 1))
	fi
	# get message after shift if delay specified
	local message="$@"
	# build script
	cat << END-OF-MSG > /tmp/preseed/preseed.msg.sh
	# jump to tty6 to display message
	exec < /dev/tty6 > /dev/tty6 2> /dev/tty6
	chvt 6
	# display short message
	echo
	echo "${message}"
	echo
	# display long message
	touch  /tmp/preseed/preseed.txt
	cat    /tmp/preseed/preseed.txt
	rm -f  /tmp/preseed/preseed.txt
	echo
	# delay
	for i in ${delay}; do
		echo -n \${i}..
		sleep 1
	done
	echo
	#/bin/sh
	# jump back to anaconda and preseed
	chvt 1
	exec < /dev/tty1 > /dev/tty1 2> /dev/tty1
	exit 0
END-OF-MSG
	# execute script
	/bin/sh /tmp/preseed/preseed.msg.sh
}
msg_basic_layout () {
	local message=$@
		cat << END-OF-MESSAGE >> /tmp/preseed/preseed.txt
$(fdisk -lu $dev | sed -n '\|[Dd]ev|p;\|^$|p')

_________________________________________________________________________
The BASIC layout has been selected for hard drive partitioning scheme.
This will wipe out all data on hard drive "${dev}".
_________________________________________________________________________
We are dumping to an interactive command line so you can effect changes.

- Type   "exit"   when done and deploy will proceed.
- Type  "reboot"  to start.
- Type "poweroff" to shutdown.
END-OF-MESSAGE
	msg ${message}
}
analyze () {
	local dev=$(get_primary_disk)
	# Set hard drive to configure
	msg 5 Free Space on \"${dev}\" :: $(in_M $(get_disk_free $dev))M
	echo d-i partman-auto/disk string $dev > /tmp/preseed/preseed.hd.disk.cfg
	debconf-set-selections                   /tmp/preseed/preseed.hd.disk.cfg

	if ! has_free_space $dev $(to_G 10); then
		debconf-set-selections /tmp/preseed/preseed.hd.basic.cfg
		debconf-set-selections /tmp/preseed/preseed.hd.partman_prompt.cfg
		msg_basic_layout 7 ERROR\! :: Not enough free space\!
		cmd 
	elif has_primary_parts $dev 4; then
		debconf-set-selections /tmp/preseed/preseed.hd.basic.cfg
		debconf-set-selections /tmp/preseed/preseed.hd.partman_prompt.cfg
		msg_basic_layout 7 ERROR\! :: No free primary partitions\!
		cmd
	elif has_primary_part_free $dev 4; then
		debconf-set-selections /tmp/preseed/preseed.hd.basic.cfg
		debconf-set-selections /tmp/preseed/preseed.hd.partman_no-prompt.cfg
		msg 20 Drive empty\; Basic layout will be used on hard drive \"${dev}\".
	elif has_primary_part_free $dev 3; then
		debconf-set-selections /tmp/preseed/preseed.hd.free_extended.cfg
		msg 30 3 Free Primary Partitions\; Extended partition layout will be used on hard drive \"${dev}\".
	elif has_primary_part_free $dev 2; then
		if has_extended_part $dev; then
			debconf-set-selections /tmp/preseed/preseed.hd.free_wo-extended.cfg
			debconf-set-selections /tmp/preseed/preseed.hd.partman_no-prompt.cfg
			msg 7 2 Free Primary Partitions\; Layout without /boot or extended partition will be used on hard drive \"${dev}\".
			cmd
		else
			debconf-set-selections /tmp/preseed/preseed.hd.free_extended.cfg
			msg 30 2 Free Primary Partitions\; Extended partition layout will be used on hard drive \"${dev}\".
		fi
	elif has_primary_part_free $dev 1; then
		debconf-set-selections /tmp/preseed/preseed.hd.free_wo-swap.cfg
		debconf-set-selections /tmp/preseed/preseed.hd.partman_no-prompt.cfg
		msg 20 1 Free Primary Partition\; Layout without /boot, extended partition or swap will be used on hard drive \"${dev}\".
		cmd
	fi
}
analyze $@
cat /tmp/preseed/preseed.hd.fdisk.sh | sed '/^analyze \$/,$d' > /tmp/preseed/test.fdisk.sh
