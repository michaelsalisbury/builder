#!/bin/bash
function main(){
	garbage_collection
        switches "$@" && exit 1
	while ! is_finished && ! is_rebooting; do
        	skip || sleep 1
		skip && nogo || eval_function ${step} || { stopping && return 1; }
		reboot_isset && reboot_mesg
		next
		reboot_start && sleep 3
	done
	is_rebooting && exit 1 || exit 0
}
function show_help(){
	cat << END_OF_HELP
  $(repc 89 _)
  -l   List all functions                |   -r   reset step to 1
  -i#  run function #                    |   -rr  reset step to 1 and run
  -da  dump all function code to stout   |   -rl  reset step to 1 and clear logs
  -d#  dump function # code to stout     |   -rc  reset step to 1, clear logs and run
                                       --|--
  -tl  tail mail log                     |   -s#  toggle function # to set/unset skip
  -t#  tail function # log               |   -sa  toggle enable/disable of function skippin
                                       --|--
  -wl  write main log to stout           |   -n   run current step and incrument step
  -w#  write function # log to stout     |   -c   run current step and stop
                                       --|--
  -e   edit script with vim              |   -jb  jump   up|back one step    (also -ju)
  -el  edit main log with vim            |   -jf  jump down|forward one step (also -jd,-j)
  -e#  edit function # log with vim      |   -mu  move function   up|back    (also -mb)
  -bk  make backup                       |   -md  move function down|forward (also -mf)
  -u   update from source                |
  $(repc 89 `printf "\257"`)
END_OF_HELP
}
###########################################################################################
###########################################################################################
function switches_verifier(){
	for x in `seq 0 1 9`; do
		eval echo $x :: ...\"\$$x\"...
	done
	echo @ :: ..."$@"...
}
function switch_set_default(){
	local X=$1
	local D=$2
	local Q=\"
	local S=\$
	echo eval [[ $Q$S*$Q =~ $Q-$X -$Q ]] \|\| [ $Q$S{@: -1}$Q == $Q-$X$Q ] \&\& set -- $Q$S{@/-$X/-$X$D}$Q
	return 0
	          [[ "$*"    =~ "-$X -"    ]] ||   [ "${@: -1}"    == "-$X"    ] &&   set -- "${@/-$X/-$X$D}"
}
function switches(){
	[ $# = 0 ] && set -- -h
	include "$@" && shift
	[ -z "$*" ] && return 1

	`switch_set_default b k`
	`switch_set_default d a`
	`switch_set_default e s`
	`switch_set_default j f`
	`switch_set_default r X`
	
	#switches_verifier "$@"

	while getopts "b:cd:e:hj:i:lm:nr:s:t:uw:" OPTION
               do
                case $OPTION in
			b)		[ "${OPTARG}" == k ] && make_backup || make_backup "$OPTARG";;
			c)		skip || eval_function $step; disp_functions; echo;;
			d)		[ $OPTARG == a ] && dump_functions || show_function $OPTARG;;
			e)		[ $OPTARG == s ] && vim "$scriptFQFN" && return 0;
					[ $OPTARG == l ] && vim "$scrLogFQFN" && return 0;
							    vim "`log_get_name $OPTARG`";;
                        h)              show_help; disp_functions; echo;;
			j)		[[ $OPTARG =~ (b|u) ]] && back || next;
					wrap; disp_functions; echo;;
                        i)              step=$OPTARG; eval_function $OPTARG;;
                        l)              disp_functions; echo;;
			m)		[[ $OPTARG =~ (b|u) ]] && move_up $step   && back
					[[ $OPTARG =~ (f|d) ]] && move_down $step && next
					disp_functions; echo;;
			n)		skip || eval_function $step; next; wrap; disp_functions; echo;;
                        s)              show_help; 
					[ $OPTARG == a ] && OPTARG=0;
					skip_function $OPTARG; disp_functions; echo;;
                        r)              rset;
					[ $OPTARG == r ] && return 1;
					[ $OPTARG == l ] && log_clear;
					[ $OPTARG == c ] && log_clear && return 1;
					disp_functions; echo;;
			t)		[ $OPTARG == l ] && log_tail_main || log_tail_func $OPTARG;;
			u)		make_backup; sync_source;;
                        w)              [ $OPTARG == l ] && cat "$scrLogFQFN" || log_to_stout $OPTARG;;
                        ?)              show_help; disp_functions; echo;;
                esac
        done
	return 0
}
###########################################################################################
###########################################################################################
function include(){
	if [ -f "$1" ]; then
		scriptFQFN="$(readlink -fn $1)"
		scriptName="$(basename $scriptFQFN)"
		scriptPath="$(dirname  $scriptFQFN)"
		
		if [ ! -f "/bin/$buildScriptName" ]; then
			ln "$buildScriptFQFN" "/bin/$buildScriptName"
			mesg 80 Hard link setup: $buildScriptFQFN \>\> /bin/$buildScriptName
		fi
		if [ -n "`sed \"1!d;/#!\/bin\/$buildScriptName/d\" \"$scriptFQFN\"`" ]; then
			sed -i "1{s|^[^ ]*|#!/bin/$buildScriptName|;}" "$scriptFQFN"
			mesg 80 Fixed script line 1 to read: \#\!/bin/$buildScriptName
			return 1
		fi
	
		scrLogPath="/var/log/${buildScriptName%.*}_${scriptName%.*}"
		if [ "`whoami`" != "root" ]; then
			sudo mkdir -p  "$scrLogPath"
			sudo chmod 777 "$scrLogPath"
		else
			mkdir -p  "$scrLogPath"
			chmod 777 "$scrLogPath"
		fi
		scrLogFQFN="$scrLogPath/${scriptName%.*}"
		. "$scriptFQFN"
		is_unset prefix	&& { prefix="setup"; sed -i "1aprefix=\"setup\""      "$scriptFQFN"; }
		is_unset step	&& { step=1;         sed -i "1astep=1"                "$scriptFQFN"; }
		is_unset skip	&& { skip=( 0 `seq $(last_function)` )
				     skip=( ${skip[*]/*/false} )
				                     sed -i "1askip=\( ${skip[*]} \)" "$scriptFQFN"; }
		if ! (( ${#skip[*]} > `last_function` )); then 
			for index in $(seq ${#skip[*]} `last_function`); do
				skip[$index]=false
			done
			fixs		
		fi
		return 0
	else
		return 1
	fi
}
###########################################################################################
###########################################################################################
function retr_version(){
	if [ -d "${scriptFQFN}.pv" ]; then
		local searchPATH=${scriptFQFN}.pv/${scriptName}.v
	else
		local searchPATH=${scriptFQFN}.v
	fi
	local cnt=`ls -1 "${searchPATH}"* 2> /dev/null		\
			| sed 's|.*\.v\([0-9]*\).*$|\1|'	\
			| sed 's|^[0]*||'			\
			| sort -n				\
			| tail -1`
	let cnt+=1
	cnt=00$cnt
	echo ${cnt: -3}
}
function fix_backups(){
	if [ -d "${scriptFQFN}.pv" ]; then
		local searchPATH=${scriptFQFN}.pv/${scriptName}.v
	else
		local searchPATH=${scriptFQFN}.v
	fi
	ls -1 "$searchPATH"* | while read file; do
		cnt=`basename "$file" | sed "s|\(.*\.v\)\([0-9]*\)\(.*$\)|\2|"`
		if [ ${#cnt} != 3 ]; then
			cnt=00$cnt
			new=`basename "$file" | sed "s|\(.*\.v\)\([0-9]*\)\(.*$\)|\1${cnt: -3}\3|"`
			dir=`dirname  "$file"`
			mv "$file" "$dir/$new"
		fi
	done
}
function make_backup(){
	fix_backups
	[ -n "$1" ] && local verName="$1"
	if [ -d "${scriptFQFN}.pv" ]; then
		mv -f "${scriptFQFN}.v"* "${scriptFQFN}.pv"/. 2> /dev/null
		local scriptBackup=${scriptFQFN}.pv/${scriptName}.v$(retr_version)${verName:+-}"${verName}"
	else
		local scriptBackup=${scriptFQFN}.v$(retr_version)${verName:+-}"${verName}"
	fi
	mesg 80 Make Backup :: `basename "$scriptBackup"`
	cp "$scriptFQFN" "$scriptBackup"
}

function test_source(){ wget -T 2 -t 2 --spider -v $1 |& egrep '^Remote file exists.$' &> /dev/null && return 0 || return 1; }
function sync_source(){
	if [ "${source:-UNSET}" != "UNSET" ] && test_source "$source"; then
		cd "$scriptPath"
		mesg 80 Syncing :: $source
		wget -q -O "${scriptName}.new"   "${source}"
		cat        "${scriptName}.new" > "$scriptName"
	else
		mesg 80 ERROR :: Script source for $scriptName broken or unset\!
	fi

	if [ "`whoami`" != "root" ]; then
		mesg 80 DENIED :: Your not root.  Use sudo to sync $buildScriptName!
	elif [ "${buildScriptSrc:-UNSET}" != "UNSET" ] \
	   && test_source "$buildScriptSrc"
	   then
		cd "$scriptPath"
		mesg 80 Syncing :: $buildScriptSrc
		wget -q -O "${buildScriptName}.new"   "$buildScriptSrc"
		cat        "${buildScriptName}.new" > "$buildScriptFQFN"
	else
		mesg 80 ERROR :: Build source for $buildScriptName broken or unset!
	fi
}
###########################################################################################
###########################################################################################
function move_ss_num(){ egrep -n "($1|$2)" | egrep -A1 "$1" | cut -f1 -d:; }
function move_retrive(){ sed "$1,$2!d"; }
function move_remove(){   sed "$1,$2d";  }
function move_down(){
	(( $1 < `last_function` )) || return 1
	touch /tmp/$$_func
	touch /tmp/$$_script
	move_name_src=`name_function $1`
	move_name_dst=`name_function $(( $1 + 1 ))`
	# Prepare  
	move_src_ss=( `cat "$scriptFQFN"  | move_ss_num "function $move_name_src()" '^}$'` )
	cat "$scriptFQFN" | move_retrive ${move_src_ss[*]} > /tmp/$$_func
	cat "$scriptFQFN" | move_remove  ${move_src_ss[*]} > /tmp/$$_script
	move_dst_ss=( `cat /tmp/$$_script | move_ss_num "function $move_name_dst()" '^}$'` )
	# Build Script
	cat /tmp/$$_script | sed "1,${move_dst_ss[1]}!d" > "$scriptFQFN"
	cat /tmp/$$_func				>> "$scriptFQFN"
	cat /tmp/$$_script | sed "1,${move_dst_ss[1]}d"	>> "$scriptFQFN"
	# Garbage Collection
	rm  /tmp/$$_func
	rm  /tmp/$$_script
}
function move_up(){
	(( $1 > 1 )) || return 1
	touch /tmp/$$_func
	touch /tmp/$$_script
	move_name_src=`name_function $1`
	move_name_dst=`name_function $(( $1 - 1 ))`
	# Prepare  
	move_src_ss=( `cat "$scriptFQFN"  | move_ss_num "function $move_name_src()" '^}$'` )
	cat "$scriptFQFN" | move_retrive ${move_src_ss[*]} > /tmp/$$_func
	cat "$scriptFQFN" | move_remove  ${move_src_ss[*]} > /tmp/$$_script
	move_dst_ss=( `cat /tmp/$$_script | move_ss_num "function $move_name_dst()" '^}$'` )
	# Build Script
	cat /tmp/$$_script | sed "${move_dst_ss[0]},\$d"   > "$scriptFQFN"
	cat /tmp/$$_func				  >> "$scriptFQFN"
	cat /tmp/$$_script | sed "${move_dst_ss[0]},\$!d" >> "$scriptFQFN"
	# Garbage Collection
	rm  /tmp/$$_func
	rm  /tmp/$$_script
}
###########################################################################################
###########################################################################################
function log_tail_main(){ [ -f "$scrLogFQFN" ] && tail -n +1 -f "$scrLogFQFN" || \
		          desc 50 Log \"$scrLogFQFN\" unavailable!; }
function log_tail_func(){ [ -f "`log_get_name $1`" ] && tail -n +1 -f "`log_get_name $1`" || \
			  desc 50 Log \"`log_get_name $1`\" per func [`name_function $1`] unavailable; }
function log_clear(){ rm -rf "$scrLogPath"; mkdir -p "$scrLogPath"; }
function log_to_stout(){ cat "`log_get_name $1`"; }
function log_output(){ tee -a "$scrLogFQFN" | tee -a "`log_get_name $1`"; }
function log_get_name(){ log_step="00$1"
			 log_step="${log_step:$(( ${#log_step} - 3 ))}"
			 log_subFQFN="$scrLogFQFN-$log_step-`name_function $1`"
			 echo "$log_subFQFN"; }
###########################################################################################
###########################################################################################
function stopping(){ derr Error, Stopping | log_output $step; }
function reboot(){ reboot_set; }
function reboot_set(){ touch /tmp/$$REBOOT; }
function reboot_mesg(){ desc REBOOTING | log_output $step; }
function reboot_isset(){ [ -f "/tmp/$$REBOOT" ] && return 0 || return 1; }
function reboot_start(){ reboot_isset && /sbin/reboot || return 1; }
###########################################################################################
###########################################################################################
function eval_function(){ cat "$buildScriptPipe" | log_output $1 &
			  eval `name_function $1` &> "$buildScriptPipe"; }
function name_function(){ list_functions | sed "$1!d"; }
function last_function(){ list_functions | wc -l; }
function show_function(){ type -a `name_function $1` | sed '1d;2s/^/function /'; }

function retr_function_mesg_opts(){ [ -z "$1" ] && index=$step || index=$1
				    show_function $index | grep "desc " | head -1 | \
				    while read retr_mesg_cmd retr_mesg_opts; do
					retr_mesg_opts=${retr_mesg_opts%?}
					retr_mesg_opts=${retr_mesg_opts//\"/}
					echo $retr_mesg_opts
				    done; }

function dump_functions(){ step=1
			   echo \#\!$buildScriptName
			   while ! is_finished; do
				dump
				let step++
			   done
}

function list_functions(){ sed "/^function $prefix/!d;s|.*\($prefix.*\)(.*|\1|" "$scriptFQFN"; }

function disp_functions(){
	disp_func_tabs="%-3s %-3s %-3s %-30s %-$(( `cols` - 43 ))s"
	echo
	padl `cols` \<\> Version `retr_version` of \"$scriptName\" \<\>\<\>\<\>\<\>
	#echo \<\> Version `retr_version` of \"$scriptName\" \<\>
	printf "$disp_func_tabs" Cur \# Skp "Function Name" "Description"
	echo
	echo $(repc `cols` -) 
	list_functions | sed '$aFINISHED; Reset to run again.' | tr _ \ | cat -n | \
        while read disp_func_index disp_func_prefix disp_func_name; do
		disp_func_o=( `retr_function_mesg_opts $disp_func_index` )
		[[ ${disp_func_o[0]} =~ ^[0-9]+ ]] && disp_func_o=( ${disp_func_o[*]:1} )
		${skip[0]} && { ${skip[$disp_func_index]} && disp_func_toggle=S || disp_func_toggle=-; } || unset disp_func_toggle
		(( $step == $disp_func_index )) && disp_func_marker='>>' || unset disp_func_marker
		(( $disp_func_index > `last_function` )) && unset disp_func_index disp_func_toggle && echo $(repc `cols` -)
		printf "$disp_func_tabs" "${disp_func_marker}"  "${disp_func_index}" "${disp_func_toggle}" "${disp_func_name}" "${disp_func_o[*]}"
		echo
	done
	unset ${!disp_func_*}
}

function skip_function(){ [[ $1 =~ ^[0-9]+$ ]] && (( $1 <= `last_function` )) || return
			  ${skip[$1]} && skip[$1]=false || skip[$1]=true; fixs; }


###########################################################################################
###########################################################################################
function is_rebooting(){ rl=(`who -r | awk '{print $2;}'`); (( $rl == 1 || $rl == 6 )); }
function is_finished(){	(( $step > `last_function` )) && return 0 || return 1; }
function is_unset(){ compgen -A variable | egrep ^$1$ > /dev/null && return 1 || return 0; }
###########################################################################################
###########################################################################################
function skip(){ ${skip[0]} && { ${skip[$step]} && return 0 || return 1; } || return 1; }
function wrap(){ (( $step > `last_function` )) && step=1               && fixs && return 0
		 (( $step < 1 ))               && step=`last_function` && fixs && return 0
		 return 1; }
function back(){ let step--; fixs; }
function next(){ let step++; fixs; }
function rset(){ step=1; fixs; }

function fixs(){ sed -i "/^step=/s/.*/step=${step}/;/^skip=/s/.*/skip=( ${skip[*]} )/" "$scriptFQFN"; }
###########################################################################################
###########################################################################################
function time_stamp(){ date +%m.%d\ %T.$(m=`date +%N`; echo ${m:0:2}); }
function stall(){ for s in `seq $1 -1 1`; do echo -n "$s "; sleep 1; done; echo; }
###########################################################################################
###########################################################################################
function cols(){ tput cols; }
function repc(){ local a=(`seq $1`);shift;a=${a[*]/*/#};a=${a// /};a=${a//#/"$@"};echo "$a"; }
function padl(){ [[ $1 =~ ^[0-9]+ ]] && { padl_width=$1 && shift; } || padl_width=100
		 padl_pattern="$1"
		 shift
		 padl_line=`repc $padl_width "$padl_pattern"`
		 padl_line+=" $@"
		 echo "${padl_line: -$padl_width}"
		 unset padl_line
		 unset padl_width
		 unset padl_pattern
}
function padr(){ [[ $1 =~ ^[0-9]+ ]] && { padr_width=$1 && shift; } || padr_width=100
		 padr_pattern="$1"
		 shift
		 padr_line="$@ "
		 padr_line+=`repc $padr_width "$padr_pattern"`
		 echo "${padr_line:0:$padr_width}"
		 unset padr_line
		 unset padr_width
		 unset padr_pattern
}
function mesg_base(){	[[ $1 =~ ^[0-9]+ ]] && { mesg_base_width=$1; shift; } || mesg_base_width=100
			mesg_base_desc=$1
			mesg_base_title_first=$2$2$2
			mesg_base_title_first=${mesg_base_title_first:0:3}
			mesg_base_title=${*:3:$#-3}
			mesg_base_title_last=${*:$#}
			echo -n \#; repc $mesg_base_width _
			echo -n \#; padr $mesg_base_width "$mesg_base_title_last" "$mesg_base_title_first" "$mesg_base_title" 
			echo -n \#; padl $mesg_base_width " " "$mesg_base_desc"
			echo -n \#; repc $mesg_base_width `printf "\257"`
			unset ${!mesg_base*}
}
function desc(){ desc_o=( `retr_function_mesg_opts` )
                 [[ ${desc_o[0]} =~ ^[0-9]+ ]] && { desc_width=${desc_o[0]} && desc_o=( ${desc_o[*]:1} ); } || desc_width=100
                 [[ $1 =~ ^[0-9]+ ]] && shift 
		 mesg_base $desc_width "$*" `printf "\273"` Step[$step]\(`name_function $step`\):$scriptFQFN \{`time_stamp`\} `printf "\253"`
		 unset ${!desc_*}
}
function derr(){ derr_o=( `retr_function_mesg_opts` )
		 [[ ${derr_o[0]} =~ ^[0-9]+ ]] && { derr_width=${derr_o[0]} && derr_o=( ${derr_o[*]:1} ); } || derr_width=100
		 mesg_base $derr_width "$* {`time_stamp`}" \! Error Step[$step]\(`name_function $step`\):$scriptFQFN \"${derr_o[*]}\" \!		
		 unset ${!derr_*}
}
function mesg(){ [[ $1 =~ ^[0-9]+ ]] && { mesg_width=$1; shift; } || mesg_width=100
		 mesg_base $mesg_width "$*" `printf "\253"` Message [$buildScriptName \<\< $scriptName] `printf "\273"`
                 unset ${!mesg_*}
}
function nogo(){ nogo_o=( `retr_function_mesg_opts` )
		 [[ ${nogo_o[0]} =~ ^[0-9]+ ]] && { nogo_width=${nogo_o[0]} && nogo_o=( ${nogo_o[*]:1} ); } || nogo_width=100
		 mesg_base $nogo_width "${nogo_o[*]}" `printf "\277?"` SKIPPING! Step[$step]\(`name_function $step`\):$scriptFQFN \{`time_stamp`\}  `printf "\277?"`
		 show_function $step
		 echo
		 unset ${!nogo_*}
}
function dump(){ dump_o=( `retr_function_mesg_opts` )
		 [[ ${dump_o[0]} =~ ^[0-9]+ ]] && { dump_width=${dump_o[0]} && dump_o=( ${dump_o[*]:1} ); } || dump_width=100
		 mesg_base $dump_width "${dump_o[*]}" ' ' Step[$step]\(`name_function $step`\) ' '
		 show_function $step
		 echo
		 unset ${!dump_*}
}
###########################################################################################
###########################################################################################
function waitAptgetUpdate(){
        lockTestFile="/var/lib/apt/lists/lock"
        timestamp=$(date +%s)
        pso="-o pid,user,ppid,pcpu,pmem,cmd"
        if [ -n "$(lsof -t ${lockTestFile})" ]; then
                desc "Waiting on apt-get to finish in another process"
        fi
        while [ -n "$(lsof -t ${lockTestFile})" ]; do
                ps ${pso}                                           -p $(lsof -t ${lockTestFile})
                ps ${pso} --no-heading -p $(ps --no-heading -o ppid -p $(lsof -t ${lockTestFile}))
                if (( $(date +%s) - ${timestamp} > 120 )); then break; fi
                sleep 1
                echo $(( $(date +%s) - ${timestamp} )) :: Seconds Elapsed
        done
}
function waitAptgetInstall(){
        lockTestFile="/var/lib/dpkg/lock"
        timestamp=$(date +%s)
        pso="-o pid,user,ppid,pcpu,pmem,cmd"
        if [ -n "$(lsof -t ${lockTestFile})" ]; then
                desc "Waiting on apt-get to finish in another process"
        fi
        while [ -n "$(lsof -t ${lockTestFile})" ]; do
                ps ${pso}                                           -p $(lsof -t ${lockTestFile})
                ps ${pso} --no-heading -p $(ps --no-heading -o ppid -p $(lsof -t ${lockTestFile}))
                if (( $(date +%s) - ${timestamp} > 120 )); then break; fi
                sleep 1
                echo $(( $(date +%s) - ${timestamp} )) :: Seconds Elapsed
        done
}
function waitForNetwork(){
	[[ "$1" =~ ^[0-9]+ ]] && wfn_timeout=$(( `date "+%s"` + $1 )) || wfn_timeout=$(( `date "+%s"` + 300 ))
	wfn_DNSS=( 10.171.92.40 8.8.8.8 10.171.92.41 8.8.4.4 )
	if [ ! -f `whereis -b nslookup | awk '{print $2}'`"" ]; then
		derr The command \"nslookup\" missing or not installed
		return 1
	fi
	wfn_cnt=0
	echo -n .
	while (( `date "+%s"` < $wfn_timeout )); do
		for wfn_ip in ${wfn_DNSS[*]}; do
			if `nslookup -timeout=1 amazon.com $wfn_ip \
			    |& egrep "^Non-authoritative answer:$" \
			    > /dev/null`; then
				let wfn_cnt++
				echo -n .
			else
				echo -n !
			fi
		done
		(( $wfn_cnt >= 2 )) && return 0
	done
	return 1
}
###########################################################################################
###########################################################################################
buildScriptFQFN="$(readlink -nf $BASH_SOURCE)"
buildScriptName="$(basename $buildScriptFQFN)"
buildScriptPath="$(dirname  $buildScriptFQFN)"
buildScriptPipe="/tmp/$$${buildScriptName}_Pipe"
mkfifo                 "${buildScriptPipe}"
buildScriptSrc="http://192.168.248.24/config/${buildScriptName}"

username=$(who -u | grep "(:" | head -1 | cut -f1 -d" ")
[ -z "$username" ] && username=root
userhome="$(cat /etc/passwd | grep $username | cut -f6 -d:)"
###########################################################################################
###########################################################################################
function garbage_collection(){ (
	while [ -n "`ps -p $$ --no-heading`" ]; do sleep 3; done
	rm -f "$buildScriptPipe"
) & }
###########################################################################################
###########################################################################################
main "$@"

