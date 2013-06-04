#!/bin/builder.sh
skip=( false false false false false )
step=1
prefix="setup"
source="https://raw.github.com/michaelsalisbury/builder/master/functions/${scriptName}"
#source=http://10.173.119.78/scripts/system-setup/$scriptName


function get_primary_disk(){
	echo /dev/sda
	#list-devices disk | head -1 
}
function has_extended_part(){
	local dev=$1
	local cnt=$(fdisk -l $dev | sed "\|${dev}[1-4][ \t].*Extended|p;d" | wc -l)
	echo $cnt
	(( cnt )) \
		&& return 0 \
		|| return 1
}
function in_M(){
	local size=$1
	echo $(( size / (1000 * 1000) ))
}
function in_K(){
	local size=$1
	echo $(( size / 1000 ))
}
function in_G(){
	local size=$1
	echo $(( size / (1000 * 1000 * 1000) ))
}
function get_units(){
	local dev=$1
	fdisk -lu $dev  | sed '/^Units/{ s/.*=//; s/[^0-9]//g p};d'
}
function get_primary_part_list(){
	local dev=$1
	fdisk -l | sed "\|^${dev}[1-4][ \t]|{ s/ .*// p }; d"
}
function get_disk_size(){
	local dev=$1
	fdisk -lu $dev | sed '/Disk.*bytes/ { s/[:, ][:, ]*/:/g;   p };d' | cut -d: -f5
}
function get_part_size(){
	local dev=$1
	get_disk_size $dev
}
function get_disk_used(){
	local dev=$1
	while read part; do
		local size=$(get_part_size $part)
		local total=$(( total + size ))
	done < <(get_primary_part_list $dev)
	echo $total
}
function get_disk_free(){
	local dev=$1
	local size=$(get_disk_size $dev)
	local used=$(get_disk_used $dev)
	local diff=$(( size - used ))
	echo $diff
}
function has_free_space(){
	local dev=$1
	#local min=${2:- $(( 1000 * 1000 * 1000 ))} # 1 gig
	local min=${2:- $(in_G 1)} # 1 gig
	local free=$(get_disk_free $dev)
	(( free > min )) \
		&& return 0 \
		|| return 1
}
function get_primary_part_free_cnt(){
	local dev=$1
	local cnt=$(get_primary_part_cnt $dev)
	local cnt=$(( 4 - cnt ))
	echo $cnt
}
function has_primary_part_free(){
	local dev=$1
	local parts=${2:- 1}
	local cnt=$(get_primary_part_free_cnt $dev)
	(( cnt >= ${parts} )) \
		&& return 0 \
		|| return 1
}
function get_primary_part_cnt(){
	local dev=$1
	local cnt=$(get_primary_part_list $dev | wc -l)
	echo $cnt
}
function has_primary_parts(){
	local dev=$1
	local parts=${2:- 1}
	local cnt=$(get_primary_part_cnt $dev)
	(( cnt >= ${parts} )) \
		&& return 0 \
		|| return 1
}

function analyze(){
	local dev=$(get_primary_disk)
	has_free_space        $dev $(in_G 10) || { echo ERROR! :: Not enough free space.           ; return 1; }
	has_primary_parts     $dev            || { echo No Partitions, standard deploy.            ; return 0; }
	has_primary_part_free $dev 3          && { echo 1 part used :: deploy with extended        ; return 0; }
	has_primary_part_free $dev 2          && { echo 2 part used :: detect extendedd            ; return 0; }
	has_primary_part_free $dev 1          && { echo 3 part used :: deploy without swap or boot ; return 0; }
}


function setup_test(){
	echo
	echo has_extended_part
	has_extended_part /dev/sda
	echo
	echo get_primary_part_cnt
	get_primary_part_cnt /dev/sda
	echo
	echo get_primary_part_free_cnt
	get_primary_part_free_cnt /dev/sda
	echo
	echo has_primary_part_free
	has_primary_part_free /dev/sda 1 && echo free || echo full
	echo
	echo get_part_size
	get_part_size /dev/sda2
	echo
	echo get_disk_used
	get_disk_used /dev/sda
	echo
	echo get_disk_size
	get_disk_size /dev/sda
	echo
	echo get_disk_free
	get_disk_free /dev/sda
	echo
	echo get_disk_free in KB
	in_K $(get_disk_free /dev/sda)
	echo
	echo has_free_space
	has_free_space /dev/sda && echo free || echo full
	echo
	echo analyze
	analyze

	echo
	echo
	echo
}

