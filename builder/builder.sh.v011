#!/bin/bash
function builder_main(){
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
  -e   edit script with vim              |   -n   run current step and incrument step
  -el  edit main log with vim            |   -c   run current step and stop
  -e#  edit function # log with vim      |   -g   get current step; error if done
                                       --|--
  -tl  tail main log                     |   -s#  toggle function # to set/unset skip
  -t#  tail function # log               |   -sa  toggle enable/disable of function skippin
                                       --|--
  -wl  write main log to stout           |   -jb  jump   up|back one step    (also -ju)
  -w#  write function # log to stout     |   -jf  jump down|forward one step (also -jd,-j)
  -bk  make backup                       |   -mu  move function   up|back    (also -mb)
  -u   update from source                |   -md  move function down|forward (also -mf)
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
	`switch_set_default s a`
	
	#switches_verifier "$@"
	local OPTIND=
	local OPTARG=
	local OPTION=
	while getopts "b:cd:e:ghj:i:lm:nr:s:t:uw:" OPTION
               do
		local switches_last_option=$OPTION
		local switches_last_optarg=$OPTARG
                case $OPTION in
			b)		[ "${OPTARG}" == k ] && make_backup || make_backup "$OPTARG";;
			c)		skip || eval_function $step; disp_functions; echo;;
			d)		[ $OPTARG == a ] && dump_functions || show_function $OPTARG;;
			e)		[ $OPTARG == s ] && vim "$scriptFQFN" && return 0;
					[ $OPTARG == l ] && vim "$scrLogFQFN" && return 0;
							    vim "`log_get_name $OPTARG`";;
			g)		(( $step > `last_function` )) && exit 1 || echo $step; exit 0;; 
                        h)              show_help; disp_functions; echo;;
			j)		[[ $OPTARG =~ (b|u) ]] && back || next;
					wrap; disp_functions; echo;;
			i)		local index=`find_function $OPTARG`
					(( index )) && eval_function $index || disp_functions 
					(( index )) && log_is_empty  $index && disp_functions;;
                        l)              disp_functions; echo;;
			m)		[[ $OPTARG =~ (b|u) ]] && move_up $step   && back
					[[ $OPTARG =~ (f|d) ]] && move_down $step && next
					disp_functions; echo;;
			n)		skip || eval_function $step; next; wrap; disp_functions; echo;;
                        s)              skip_function $OPTARG || show_help
					disp_functions; echo;;
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
	
	# Shift to non parced command line arguments
	shift $(( OPTIND - 1 ))

	# If there are any extra cmd line arguments apply the last command switch
	(( ${#@} )) && for args in "$@"; do
		case ${switches_last_option:- null} in
			i|s)	$FUNCNAME -$switches_last_option "$args";;
		esac
	done

	# Test for piped extra cmd line arguments and apply to last cmd line switch
	if readlink /proc/$$/fd/0 | egrep -q "^pipe:"; then
		case ${switches_last_option:- null} in	
			i|s)	while read args; do
					$FUNCNAME -$switches_last_option "${args}"
				done < <(cat | sed 's/\(^"\|"$\)//g;s/ *" */\n/g;') # splits lines at quotes, removes leading and trailing spaces
				;;
		esac
	fi
	return 0
}
###########################################################################################
###########################################################################################
function include(){
	if [ -f "$1" ]; then
		scriptFQFN="$(readlink -fn $1)"
		scriptName="$(basename $scriptFQFN)"
		scriptPath="$(dirname  $scriptFQFN)"
		# Install builder script to /bin via hard link		
		if [ ! -f "/bin/$buildScriptName" ]; then
			ln "$buildScriptFQFN" "/bin/$buildScriptName"
			mesg 80 Hard link setup: $buildScriptFQFN \>\> /bin/$buildScriptName
		fi
		# Add #!/bin/builderScriptName to the head of the calling script
		if [ -n "`sed \"1!d;/#!\/bin\/$buildScriptName/d\" \"$scriptFQFN\"`" ]; then
			sed -i "1{s|^[^ ]*|#!/bin/$buildScriptName|;}" "$scriptFQFN"
			mesg 80 Fixed script line 1 to read: \#\!/bin/$buildScriptName
			return 1
		fi
		# Setup logs
		scrLogPath="/var/log/${buildScriptName%.*}_${scriptName%.*}"
		if [ "`whoami`" != "root" ]; then
			sudo mkdir -p  "$scrLogPath"
			sudo chmod 777 "$scrLogPath"
		else
			mkdir -p  "$scrLogPath"
			chmod 777 "$scrLogPath"
		fi
		scrLogFQFN="$scrLogPath/${scriptName%.*}"

		# Include control variables skip, step & prefix
		source <(sed "${scriptFQFN}"\
				-e '/^skip=/p'\
				-e '/^step=/p'\
				-e '/^prefix=/p'\
				-e '/^source=/p'\
				-e 'd')

		# Verify control variables exist and fix script if nessisary
		is_unset prefix	&& { prefix="setup"; sed -i "1aprefix=\"setup\""      "$scriptFQFN"; }
		is_unset step	&& { step=1;         sed -i "1astep=1"                "$scriptFQFN"; }
		is_unset skip	&& { skip=( 0 `seq $(last_function)` )
				     skip=( ${skip[*]/*/false} )
		                     sed -i "1askip=\( ${skip[*]} \)" "$scriptFQFN"; }
		
		# Fix skip array larger than the number of functions
		if ! (( ${#skip[*]} > `last_function` )); then 
			for index in $(seq ${#skip[*]} `last_function`); do
				skip[$index]=false
			done
			fixs		
		fi

		# Setup array to track sourced script
		declare -A includes

		# Include functions and global variables recursivelly
		include_file "${scriptFQFN}"
		return 0
	else
		return 1
	fi
}
function include_log(){
	# test for args
	(( ${#@} > 0 )) && echo "$@" >> "${scrLogFQFN}-includes"
	# test for incomming pipe
	#Use read -t 0 -N 0 to detect if data is available on stdin. 
	#Use test -t 0 or tty to try to detect if a pipe is connected to stdin.
	read -t 0 -N 0 && cat >> "${scrLogFQFN}-includes"
}
function include_file(){
	local include_file=$(readlink -nf "$1")
	local include_path=$(dirname "${include_file}")
	# Verify that include file has not already been processed
	if ${includes[${include_file}]:-false}; then
		echo Include file \"${include_file}\" has already been processed. | include_log
		return 0
	else
		includes[${include_file}]=true
	fi
	if sed "${include_file}" -e '1p;d' | grep -q "^#!/bin/builder"; then
		echo INCLUDE_BLDR :: ${include_file}
		# Parse functions to be sourced to ensure no duplicates
		include_functions "${include_file}"
		# Parse global variables
		include_variables "${include_file}"	
		# Parse includes
		include_dependencies "${include_file}"
	elif sed "${include_file}" -e '1p;d' | grep -q "^#!/bin/bash"; then
		echo INCLUDE_BASH :: ${include_file}
		# Parse functions to be sourced to ensure no duplicates
		include_functions "${include_file}"
		# Parse global variables
		include_variables_bash "${include_file}"	
	else
		echo INCLUDE_FILE :: ${include_file}
		source "${include_file}"
	fi
}
function include_variables_bash(){
	local include_file=$(readlink -nf "$1")
	local include_path=$(dirname "${include_file}")
	local variable_name=""
	local variable_is_available=""
	local source_variables=true
	# Parse all variable to ensure they have not been used
	while read variable_name; do
		variable_is_available=${!variable_name:+false}
		if ${variable_is_available:-true}; then
			echo variable_name :: $variable_name | include_log
		else
			echo variable_name :: $variable_name :: ALREADY TAKEN | include_log
			source_variables=false
		fi
	done < <(sed "${include_file}"\
			-e 's/[[:space:]]*//'\
			-e '/^#/d'\
			-e '/function[[:space:]]\+/,/^}/d'\
			-e '/.*read.*</s/.*read.*[[:space:]]\+\([a-Z0-9_]\+\)[[:space:]]\+<.*/\1/p'\
			-e '/^declare/s/.*[[:space:]]\+\([a-Z0-9_]\+\)\($\|=.*\)/\1/p'\
			-e '/^IFS[a-Z0-9_]*=/d'\
			-e '/[^[:space:]]\+=/s/=.*//p'\
			-e 'd')
	# If all variables names were free from conflict then include all
	if ${source_variables}; then
		local IFS_DEFAULT=${IFS}
		source <(include_function "${include_file}" global_variables | sed '1d;$d')
		IFS=${IFS_DEFAULT}
	else
		echo _ERROR_ :: Global variables from file \"${include_file}\" conflict. | tee >(while read line; do include_log "${line}"; done)
		exit 1
	fi
}
function include_variables(){
	local include_file=$(readlink -nf "$1")
	local include_path=$(dirname "${include_file}")
	local variable_name=""
	local variable_is_available=""
	local source_variables=true
	# Verify that function global_variables exists
	include_function "${include_file}" global_variables &> /dev/null || return 1
	# Parse all variable to ensure they have not been used
	while read variable_name; do
		variable_is_available=${!variable_name:+false}
		if ${variable_is_available:-true}; then
			echo variable_name :: $variable_name | include_log
		else
			echo variable_name :: $variable_name ALREADY TAKEN | include_log
			source_variables=false
		fi
	done < <(include_function "${include_file}" global_variables |\
		    sed -e '1d;$d'\
			-e 's/[[:space:]]*//'\
			-e '/^#/d'\
			-e '/.*read.*</s/.*read.*[[:space:]]\+\([a-Z0-9_]\+\)[[:space:]]\+<.*/\1/p'\
			-e '/^declare/s/.*[[:space:]]\+\([a-Z0-9_]\+\)\($\|=.*\)/\1/p'\
			-e '/^IFS[a-Z0-9_]*=/d'\
			-e '/[^[:space:]]\+=/s/=.*//p'\
			-e 'd')
	# If all variables names were free from conflict then include all
	if ${source_variables}; then
		local IFS_DEFAULT=${IFS}
		source <(include_function "${include_file}" global_variables | sed '1d;$d')
		IFS=${IFS_DEFAULT}
	else
		echo _ERROR_ :: Global variables from file \"${include_file}\" conflict. | tee >(while read line; do include_log "${line}"; done)
		exit 1
	fi
}
function include_function(){
	local include_file=$(readlink -nf "$1")
	local function_name=$2
	sed "${include_file}" -n -e "/^[[:space:]]*function[[:space:]]\+${function_name}[[:space:]]*()/,/^}/p" | grep ""
}
function include_functions(){
	local include_file=$(readlink -nf "$1")
	local include_path=$(dirname "${include_file}")
	local function_name=""

	while read function_name; do
		# verify function name is unique 
		if typeset -f | sed -e "/^{/,/^}/d" -e "s/[[:space:]].*//" | grep -q "^${function_name}$"; then
			if [ "${function_name}" == "main" ]; then
				echo WARNING :: File [${include_file}] sourced function ${function_name}\(\), but will be ignored. | include_log
			else	
				echo _ERROR_ :: File [${include_file}] needs to re-name function ${function_name}\(\), ignoring. | include_log
			fi
			continue
		fi
		# source function
		source <(include_function "${include_file}" ${function_name})
		# verify function has been sourced
		if typeset -f | sed -e "/^{/,/^}/d" -e "s/[[:space:]].*//" | grep -q "^${function_name}$"; then
			echo SUCCESS :: File [${include_file}] sourced function ${function_name}\(\). | include_log
		else
			echo _ERROR_ :: File [${include_file}] sourced function ${function_name}\(\) but verification failed. | include_log
		fi
	### LOOP A ##########################################################################################################
	done < <(sed "${include_file}"\
			-e "/^[[:space:]]*function[[:space:]]\+[^()[:space:]]\+[[:space:]]*()/!d"\
			-e "s/^[[:space:]]*function[[:space:]]\+\([^()[:space:]]\+\).*/\1/"\
			-e "/^includes$/d"\
			-e "/^global_variables$/d"
		)
}
function include_dependencies(){
	local include_file=$(readlink -nf "$1")
	local include_path=$(dirname "${include_file}")
	local include_line=""
	local include_target=""
	# Verify that function global_variables exists
	include_function "${include_file}" includes &> /dev/null || return 1
	### LOOP A ### parse the passed script file for a function called "includes"
	while read include_line; do
		# escape all spaces in include line; this keeps include entries clean and free of quotes
		include_line=${include_line// /\"\ \"}
		# if the include line does not start with a leading slash then it's relative to the location of the passed script file
		[ "${include_line:0:1}" != "/" ] && include_line=${include_path}/${include_line}
		### LOOP B ### use the find command to expand the include line and list all the matching files
		while read include_target; do
			include_file "${include_target}"
		### LOOP B ##########################################################################################################
		done < <(eval find "${include_line}" -type f -maxdepth 0 2> /dev/null)
	### LOOP A ##########################################################################################################
	done < <(include_function "${include_file}" includes | sed '1d;$d')
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
	# get source URL from script that called the update request
	eval `sed '/^source=/p;d' "${scriptFQFN}"`
	# Test and sync script
	if [ "${source:-UNSET}" != "UNSET" ] && test_source "${source}"; then
		cd "$scriptPath"
		mesg 80 Syncing :: $source
		wget -q -O "${scriptName}.new"   "${source}"
		cat        "${scriptName}.new" > "${scriptName}"
	else
		mesg 80 ERROR :: Script source \for $scriptName broken or unset\!
	fi
	# Test and sync builder.sh
	if [ "`whoami`" != "root" ]; then
		mesg 80 DENIED :: Your not root.  Use sudo to sync $buildScriptName\!
	elif [ "${buildScriptSrc:-UNSET}" != "UNSET" ] \
	   && test_source "$buildScriptSrc"
	   then
		cd "$scriptPath"
		mesg 80 Syncing :: $buildScriptSrc
		wget -q -O "${buildScriptName}.new"   "$buildScriptSrc"
		cat        "${buildScriptName}.new" > "$buildScriptFQFN"
	else
		mesg 80 ERROR :: Build source \for $buildScriptName broken or unset\!
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
function log_is_empty(){  local log=`log_get_name $1`
			  if [ -f "${log}" ]; then
				local size=`du -b "${log}" | cut -f1`
				if (( size )); then
					return 1
				else
					rm -f "${log}"
					return 0
				fi
			  fi
}
function log_tail_main(){ [ -f "$scrLogFQFN" ] && tail -n +1 -f "$scrLogFQFN" || \
		          desc 50 Log \"$scrLogFQFN\" unavailable!; }
function log_tail_func(){ [ -f "`log_get_name $1`" ] && tail -n +1 -f "`log_get_name $1`" || \
			  desc 50 Log \"`log_get_name $1`\" per func [`name_function $1`] unavailable; }
function log_clear(){ rm -rf "$scrLogPath"; mkdir -p "$scrLogPath"; }
function log_to_stout(){ cat "`log_get_name $1`"; }
function log_output(){ tee -a "$scrLogFQFN" | tee -a "`log_get_name $1`"; }
function log_get_name(){ log_step="00$1"
			 #log_step="${log_step:$(( ${#log_step} - 3 ))}"
			 log_step="${log_step: -3}"
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
function find_function(){
	local opts=$*
	local srch=${opts// /_}
	if [[ "${srch}" =~ ^[0-9]+$ ]]; then
		echo ${srch}
	else
		local O="-v P=${prefix} -v S=${srch} -v T=true -v F=false"
		local L="list_functions"
		# test case sensative exact match
		if   `$L | awk $O 'BEGIN{R="^"P"_"S"$"} $0~R {c++}END{print(c==1)?T:F}'`; then
		      $L | awk $O 'BEGIN{R="^"P"_"S"$"} $0~R {print NR}'
		# test case insensative exact match
		elif `$L | awk $O 'BEGIN{R="^"P"_"tolower(S)"$"} tolower($0)~R {c++}END{print(c==1)?T:F}'`; then
		      $L | awk $O 'BEGIN{R="^"P"_"tolower(S)"$"} tolower($0)~R {print NR}'
		# test case sensative search
		elif `$L | awk $O 'BEGIN{R="^"P"_.*"S} $0~R {c++}END{print(c==1)?T:F}'`; then
		      $L | awk $O 'BEGIN{R="^"P"_.*"S} $0~R {print NR}'
		# test case insensative search
		elif `$L | awk $O 'BEGIN{R="^"P"_.*"tolower(S)} tolower($0)~R {c++}END{print(c==1)?T:F}'`; then
		      $L | awk $O 'BEGIN{R="^"P"_.*"tolower(S)} tolower($0)~R {print NR}'
		# if no matches return zero
		else
			echo 0
		fi
	fi
}
function eval_function(){ cat "$buildScriptPipe" | log_output $1 &
			  eval `name_function $1` &> "$buildScriptPipe"; 
}
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

#function list_functions(){ sed "/^function $prefix/!d;s|.*\($prefix.*\)(.*|\1|" "$scriptFQFN"; }
function list_functions(){ sed "${scriptFQFN}" -n -e "s/^[[:space:]]*function[[:space:]]\+\(${prefix}[^()[:space:]]\+\).*/\1/p"; }

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

function skip_function(){
	case "$*" in
		a)	${skip[0]} && skip[0]=false || skip[0]=true
			fixs;;
		d)	skip=( ${skip[@]//*/true} )
			fixs;;
		e)	skip=( ${skip[@]//*/false} )
			fixs;;
		*)	local func=`find_function "$*"`
			[[ $func =~ ^[0-9]+$ ]] && (( $func <= `last_function` )) || return 1
			if (( func )); then
				! ${skip[0]} && skip[0]=true
				${skip[$func]} && skip[$func]=false || skip[$func]=true
				fixs
			fi;;
	esac	
}


###########################################################################################
###########################################################################################
function is_rebooting(){ rl=(`who -r | awk '{print $2;}'`); [[ "$rl" == 1 ||" $rl" == 6 ]]; }
function is_finished(){	(( $step > `last_function` )) && return 0 || return 1; }
function is_unset(){ compgen -A variable | egrep -q ^$1$ && return 1 || return 0; }
###########################################################################################
###########################################################################################
function skip(){ ${skip[0]} && { ${skip[$step]} && return 0 || return 1; } || return 1; }
function wrap(){ (( $step > `last_function` )) && step=1               && fixs && return 0
		 (( $step < 1 ))               && step=`last_function` && fixs && return 0
		 return 1; }
function back(){ let step--; fixs; }
function next(){ let step++; fixs; }
function rset(){ step=1; fixs; }

function fixs(){ sed -i -e "/^step=/cstep=${step}" -e "/^skip=/cskip=\( ${skip[*]} \)" "$scriptFQFN"; }
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
			let mesg_base_width-=1
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
	[[ "$1" =~ ^[0-9]+ ]]	&& local timeout=$(( `date "+%s"` +  $1 )) \
				|| local timeout=$(( `date "+%s"` + 300 ))
	# Lookup local path to command "host"
	local cmd=( `whereis -b host` )
	# If command "host" is missing throw error
	if (( ${#cmd[@]} == 1 )); then
		derr The command \"host\" missing or not installed
		return 1
	fi
	local cnt=0
	echo -n .
	# Loop for duration of timeout period
	while (( `date "+%s"` < $timeout )); do
		# Loop threw listed domains testing to see if they resolv
		while read dom; do
			if ${cmd[1]} -W 3 $dom |& grep "has address" &> /dev/null; then
				let cnt++
				echo -n .
			else
				echo -n !
			fi
		done << END-OF-DOMAIN-LIST
			amazon.com
			google.com
			ucf.edu
			wikipedia.org
			sourceforge.net
END-OF-DOMAIN-LIST
		# Exit with a positive return if we get 5 or more DNS responces
		(( $cnt >= 5 )) && return 0
	done
	return 1
}
###########################################################################################
###########################################################################################
buildScriptFQFN=$(readlink -nf "${BASH_SOURCE}")
buildScriptName=$(basename "${buildScriptFQFN}")
buildScriptPath=$(dirname  "${buildScriptFQFN}")
buildScriptPipe="/tmp/$$${buildScriptName}_Pipe"
mkfifo                 "${buildScriptPipe}"
buildScriptSrc="http://10.173.119.78/scripts/system-setup/${buildScriptName}"

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
builder_main "$@"

# nothing
