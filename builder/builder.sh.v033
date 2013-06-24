#!/bin/bash
###########################################################################################
#################################################################### GLOBAL VARS DEFINED ##
# step skip prefix source
#
# buildScriptFQFN buildScriptName buildScriptPath
#      scriptFQFN      scriptName      scriptPath 
#      srcLogFQFN                      srcLogPath
#
#   MAX_WIDTH   MAX_WIDTH_DEFAULT
# SPLIT_DELIM SPLIT_DELIM_DEFAULT
#
###########################################################################################
###########################################################################################
function builder_main(){
	#SET_MAX_WIDTH_BY_COLS 80

	garbage_collection

	verify_wrapper			|| EXIT 1 # verify and or fix builder install (wrapper)
	verify_script "$1"		|| EXIT 1 # verify script and set scriptFQFN global vars.
	verify_shebang			|| EXIT 1 # verify and or fix script and shebang line
	verify_logs			|| EXIT 1
	source_global_control_vars	&& shift\
					|| EXIT 1 # source; step, skip, prefix, source.
	process_switches "$@"		|| EXIT 1 # process all command line and piped args

	# main execution loop
	while ! is_finished && ! is_rebooting; do
        	skip || sleep 1
		skip && nogo || eval_function ${step} || { stopping && return 1; }
		reboot_isset && reboot_mesg
		next
		reboot_start && sleep 3
	done
	is_rebooting && exit 1 || exit 0
}
function source_global_control_vars(){
	# Include control GLOBAL variables skip, step & prefix
	for exit_counter in {10..1}; do
		# source control vars
		cat <<-SED | sed -n -f <(cat) "${scriptFQFN}" > /dev/shm/$$$FUNCNAME
			/^skip=/p
			/^step=/p
			/^prefix=/p
			/^source=/p
		SED
		source /dev/shm/$$$FUNCNAME
		rm  -f /dev/shm/$$$FUNCNAME
		# verify GLOBAL var: prefix
		if (( ${#prefix} == 0 )); then
			cat <<-SED | sed -i -f <(cat) "${scriptFQFN}"
				/^prefix=/d
				1aprefix="setup"
			SED
		fi
		# verify GLOBAL var: step
		if (( ${#step} == 0 )); then
			cat <<-SED | sed -i -f <(cat) "${scriptFQFN}"
				/^step=/d
				1astep=1
			SED
		fi
		# verify GLOBAL array: skip
		local last_function=`last_function`
		if (( ${#skip[*]} != last_function + 1 )); then
			skip=( ${skip[*]} $(list_functions | sed 's/.*/false/;$p') )
			cat <<-SED | sed -i -f <(cat) "${scriptFQFN}"
				/^skip=(/d
				1askip=( ${skip[*]:0:$(( last_function + 1 ))} )
			SED
		fi
		# if all control vars exist then return and proceed
		if (( ${#prefix} ))	\
		&& (( ${#step} ))	\
		&& (( ${#skip[*]} == last_function + 1 )); then return 0; fi
	done
	derr 80 Problem sourceing GLOBAL control vars
	return 1
}
function verify_wrapper(){
	if [ "${buildScriptExpectedFQFN}" != "${buildScriptFQFN}" ]; then
		if [ -f "${buildScriptExpectedFQFN}" ]; then
			mesg 80 Old wrapper exits\! Please rectify and \then try again.
			return 1
		else
			ln "${buildScriptFQFN}" "${buildScriptExpectedFQFN}"
			mesg 80 Hard link setup: ${buildScriptFQFN} \>\> ${buildScriptFQFN}
			return 1
		fi  
	fi
}
function verify_script(){
	if [ -f "$1" ]; then
		scriptFQFN=$(readlink -fn "$1")
		scriptName=$(basename "${scriptFQFN}")
		scriptPath=$(dirname  "${scriptFQFN}")
	else
		show_help
		mesg 80 Wrapper \"${buildScriptFQFN}\" call with script to process'!'
		return 1
	fi
}
function verify_shebang(){
	# Add #!${buildScriptFQFN} to the head of the calling script
	if is_bash_version_atleast 4; then
		#!/bin/builder.sh
		if sed -n '1p' "${scriptFQFN}" |\
		   grep -v ^'\#!'${buildScriptExpectedFQFN}; then
			sed -i "1i#\!${buildScriptExpectedFQFN}" "${scriptFQFN}"
			mesg 80 Fixed script line 1 to read: $(sed -n '1p' "${scriptFQFN}")
			return 1
		fi
	else
		#!/usr/bin/env /bin/builder.sh
		local env=$(which env 2>/dev/null)
		if sed -n '1p' "${scriptFQFN}" |\
		   grep -v ^'\#!'${env}[[:space:]]*${buildScriptExpectedFQFN}; then
			sed -i "1i#\!${env} ${buildScriptExpectedFQFN}" "${scriptFQFN}"
			mesg 80 Fixed script line 1 to read: $(sed -n '1p' "${scriptFQFN}")
			return 1
		fi
	fi
}
function verify_logs(){
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
}
function show_help(){
	cat << END_OF_HELP
  $(REPC 89 _)
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
  -wl  write main log to stout           |   -jb  jump  up |  back  one step (also -ju)
  -w#  write function # log to stout     |   -jf  jump down|forward one step (also -jd,-j)
  -bk  make backup                       |   -mu  move function   up|back    (also -mb)
  -u   update from source                |   -md  move function down|forward (also -mf)
  $(REPC 89 `printf "\257"`)
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
	local ARG=\-${1//-/}	# switch/arg
	local VALUE=$2		# default value for switch/arg
	# echo command for eval with calling function
	cat <<-EVAL
		eval [[ "\$*" =~ ${ARG}[[:space:]]- ]]	\
		|| [ "${ARG}" == "\${@: -1}" ]		\
		&& set -- "\${@/${ARG}/${ARG}${VALUE}}"
	EVAL
}
function process_switches(){
	# If no switches pressent then process functions in order
	if [ -z "$*" ]; then
		# source all dependances first
		include_file "${scriptFQFN}"
		return 0
	fi

	# set switch/arg defaults
	`switch_set_default b k`
	`switch_set_default d a`
	`switch_set_default e s`
	`switch_set_default j f`
	`switch_set_default r X`
	`switch_set_default s a`
	`switch_set_default i 0`
	
	#switches_verifier "$@"
	local OPTIND=
	local OPTARG=
	local OPTION=
	local OPTERR=1
	while getopts "b:cd:e:ghj:i:lm:nr:s:t:uw:" OPTION; do
		local switches_last_option=$OPTION
		local switches_last_optarg=$OPTARG

		# soucre dependancies if nessisary
               	case $OPTION in
			c|i|n)	include_file         "${scriptFQFN}";;
			r)	[[ "${OPTARG}" =~ r|c ]]		\
				&& include_file      "${scriptFQFN}"	\
				|| include_functions "${scriptFQFN}";;
			e)	;;
			?)	include_functions    "${scriptFQFN}";;
		esac

		# process switches
                case $OPTION in
			# make backup
			b)	[ "${OPTARG}" == k ] && make_backup || make_backup "$OPTARG";;
			# run current step and stop 
			c)	skip || eval_function $step; disp_functions; echo;;
			# dump function code to screen
			d)	[ $OPTARG == a ] && dump_functions || show_function $OPTARG;;
			# edit script with vim
			e)	[ $OPTARG == s ] && vim "$scriptFQFN" && return 1;
				[ $OPTARG == l ] && vim "$scrLogFQFN" && return 1;
				vim "`log_get_name $OPTARG`";;
			# get current step, error if done
			g)	(( $step > `last_function` )) && EXIT 1 || echo $step; EXIT 0;; 
			# display help
                        h)	show_help; disp_functions; echo;;
			# jump up or down (back or forward) a step
			j)	[[ $OPTARG =~ (b|u) ]] && back || next;
				wrap; disp_functions; echo;;
			# execute function by index or name (unique match)
			i)	local index=`find_function $OPTARG`
				(( index )) && eval_function $index || disp_functions 
				(( index )) && log_is_empty  $index && disp_functions;;
			# display function list
                        l)	disp_functions; echo;;
			# reorganize functions (modify script, experimental)
			m)	[[ $OPTARG =~ (b|u) ]] && move_up $step   && back
				[[ $OPTARG =~ (f|d) ]] && move_down $step && next
				disp_functions; echo;;
			# run current step and increment
			n)	skip || eval_function $step; next; wrap; disp_functions; echo;;
			# toggle function skip on/off; toggle skip feature on/off
			s)	skip_function $OPTARG || show_help
				disp_functions; echo;;
			# reset step back to 1
			r)	rset;
				[ $OPTARG == r ] && return 0;
				[ $OPTARG == l ] && log_clear;
				[ $OPTARG == c ] && log_clear && return 0;
				disp_functions; echo;;
			# tail the main log or function log
			t)	[ $OPTARG == l ] && log_tail_main || log_tail_func $OPTARG;;
			# update from source after backup
			u)	make_backup; sync_source;;
			# cat the main log of function log
			w)	[ $OPTARG == l ] && cat "$scrLogFQFN" || log_to_stout $OPTARG;;
			?)	show_help; disp_functions; echo;;
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
				# splits lines at commas and double quotes
				# removes leading and trailing spaces 
				done < <(cat | tr "," "\n" | sed -f <(cat <<-SED
					s/^[[:space:]\"]*//
					s/[[:space:]\"]*$//
					s/[\"][[:space:]]\+[\"]/\n/
					s/[[:space:]]*[\"][[:space:]]/\n/
				SED
				));;
		esac
	fi
	return 1
}
###########################################################################################
###########################################################################################
function get_bash_version(){
	cat <<-SED | sed -n -f <(cat) <(bash --version | tr [:space:] '\n')
		/release/s/\([0-9]\+\.[0-9]\+\).*/\1/p
	SED
}
function is_bash_version_atleast(){
	(( `echo $(get_bash_version) \>= ${1:- 4} | bc` ))
}
function include_log(){
	# test for args
	(( ${#@} > 0 )) && echo "$@" >> "${scrLogFQFN}-includes"
	# test for incomming pipe
	#Use read -t 0 -N 0 to detect if data is available on stdin. 
	#Use test -t 0 or tty to try to detect if a pipe is connected to stdin.
	#read -t 0 -N 0 && cat >> "${scrLogFQFN}-includes"
	if readlink /proc/$$/fd/0 | egrep -q "^pipe:"; then
		cat >> "${scrLogFQFN}-includes"
	fi
}
function include_file(){
	include=${include:- $'\n'}
	local include_file=$(readlink -nf "$1")
	local include_path=$(dirname "${include_file}")
	# Verify that include file has not already been processed
	#if ${includes[${include_file}]:-false}; then
	#includes[${include_file}]=true
	if [[ "${includes}" =~ $'\n'"${include_file}"$'\n' ]]; then
		echo Include file \"${include_file}\" has already been processed. | include_log
		return 0
	else
		includes+="${include_file}"$'\n'
	fi
	if sed "${include_file}" -n -e '1p' | grep -q '^#!.*'${buildScriptFQFN}; then
		echo INCLUDE_BLDR :: ${include_file}
		# Parse functions to be sourced to ensure no duplicates
		include_functions "${include_file}"
		# Parse global variables
		include_variables "${include_file}"	
		# Parse includes
		include_dependencies "${include_file}"
	elif sed "${include_file}" -n -e '1p' | grep -q '^#!/bin/bash'; then
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
		include_function "${include_file}" global_variables |\
		sed '1d;$d' > /dev/shm/$$$FUNCNAME
		source        /dev/shm/$$$FUNCNAME
		rm  -f        /dev/shm/$$$FUNCNAME
		#source <(include_function "${include_file}" global_variables | sed '1d;$d')
		IFS=${IFS_DEFAULT}
	else
		echo _ERROR_ :: Global variables from file \"${include_file}\" conflict. |\
			tee >(while read line; do include_log "${line}"; done)
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
		include_function "${include_file}" global_variables |\
		sed '1d;$d' > /dev/shm/$$$FUNCNAME
		source        /dev/shm/$$$FUNCNAME
		rm  -f        /dev/shm/$$$FUNCNAME
		#source <(include_function "${include_file}" global_variables | sed '1d;$d')
		IFS=${IFS_DEFAULT}
	else
		echo _ERROR_ :: Global variables from file \"${include_file}\" conflict. |\
			tee >(while read line; do include_log "${line}"; done)
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
		include_function "${include_file}" ${function_name} > /dev/shm/$$$FUNCNAME
		source /dev/shm/$$$FUNCNAME
		rm  -f /dev/shm/$$$FUNCNAME
		#source <(include_function "${include_file}" ${function_name})
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
			-e "/^global_variables$/d")
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

function test_source(){ wget -T 2 -t 2 --spider -v $1 2>&1 | egrep '^Remote file exists.$' &> /dev/null && return 0 || return 1; }
function sync_source(){
	# get source URL from script that called the update request
	eval `sed '/^source=/p;d' "${scriptFQFN}"`
	# Test and sync script
	if [ "${source:-UNSET}" != "UNSET" ] && test_source "${source}"; then
		cd "$scriptPath"
		mesg 80 Syncing :: $source
		wget -q --no-check-certificate \
			-O "${scriptName}.new"   "${source}"
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
		wget -q --no-check-certificate \
			-O "${buildScriptName}.new"   "$buildScriptSrc"
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
function list_functions(){
	cat <<-SED | sed -n -f <(cat) "${scriptFQFN}"
		s/^[[:space:]]*function[[:space:]]\+\(${prefix}[^()[:space:]]\+\).*/\1/p
	SED
}

function disp_functions(){
	SET_MAX_WIDTH_BY_COLS
	# setup printf format
	local printf_format="%-3s %-3s %-3s %-30s %-$(( ${MAX_WIDTH} - 43 ))s"
	echo
	# print header
	PAD_ANCHOR_R \<\> Version `retr_version` of \"$scriptName\" \<\>\<\>\<\>\<\>
	# print column headers
	printf "${printf_format}" Cur $'#' Skp "Function Name" "Description"
	echo
	# print dashed line
	REPC -
	# parse functions
	local name index desc toggle marker
	while read name; do
		name=${name#${prefix}_}
		name=${name//_/ }
		index=$(find_function "${name}")
		# get function discription
		desc=$(retr_function_mesg_opts ${index} | sed 's/^[0-9[:space:]]*//')
		# set skip toggle
		if ${skip[0]}; then
			${skip[${index}]}	\
				&& toggle=S	\
				|| toggle=-
		else
			unset toggle
		fi
		# set step marker
		(( step == index ))	\
			&& marker='>>'	\
			|| unset marker
		# print
		printf "${printf_format}" "${marker}" "${index}" "${toggle}" "${name}" "${desc}"
	done < <(list_functions)
	# print dashed line
	REPC -
	# setup FINISHED
	is_finished		\
		&& marker='>>'	\
		|| unset marker
	# clear unused vars
	unset index toggle desc
	name='Reset to run again'
	# print FINISHED
	printf "${printf_format}" "${marker}" "${index}" "${toggle}" "${name}" "${desc}"
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
##################################################################### functions.format.sh #
function SET_MAX_WIDTH_BY_COLS(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT:- 90}}
	# set GLOBAL vars; COLUMNS, LINES
	resize > /dev/shm/$$$FUNCNAME
	source   /dev/shm/$$$FUNCNAME
	rm  -f   /dev/shm/$$$FUNCNAME
	MAX_WIDTH=`tput cols 2>/dev/null`
	MAX_WIDTH=${MAX_WIDTH:-${width}}
}
function REPC(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT:- 90}}
	# manditory pad character
	local pad_chr=$(PAD_CHR_TR "$1")
	# return
	cat <<-SED | sed -n -f <(cat) <(seq ${width})
		s/.*/${pad_chr}/			# swap count for pad_chr 
		H					# append pad_chr to hold buffer
		\${					# at last line do
			x				# swap hold buffer to pattern space
			s/\n//g				# remove all new-line chars
			s/\(.\{${width}\}\).*/\1/	# capture the correct num od chars
			p				# print
		}
	SED
}
function PAD_CHR_TR(){
	case "$1" in
		-u)     	echo $'_';;
		-s)     	echo $' ';;
		-E)		echo $'!';;
		-e)     	echo $'=';;
		-P)     	echo $'|';;
		-p)     	echo $'#';;
		-t)     	echo $'~';;
		-[0-9]*)	eval printf \"\\${1:1}\";;
		*)      	echo "$1";;
	esac
}
function PAD_ANCHOR_R(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT:- 90}}
	# manditory pad character
	local pad_chr=$(PAD_CHR_TR "$1")
	shift
	# text to anchor right
	local line="$@"
	# add buffer space between text and pad chars if first text char is diff
	[ "${pad_chr}" != "${line:0:1}" ] && line=" ${line}"
	# setup pad_char string
	pad_chr=$(REPC ${width} "${pad_chr}")
	# pre-pend pad chars
	line="${pad_chr}${line}"
	# return
	echo "${line: -${width}}"
}
function PAD_ANCHOR_L(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT:- 90}}
	# manditory pad character
	local pad_chr=$(PAD_CHR_TR "$1")
	shift
	# text to anchor right
	local line="$@"
	# add buffer space between text and pad chars if last text char is diff
	[ "${pad_chr}" != "${line: -1}" ] && line="${line} "
	# setup pad_char string
	pad_chr=$(REPC ${width} "${pad_chr}")
	# apend pad chars
	line="${line}${pad_chr}"
	# return
	echo "${line:0:${width}}"
}
function PAD_CNTR(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT:- 90}}
	# manditory pad character
	local pad_chr=$(PAD_CHR_TR "$1")
	shift
	# text to center
	local line="$@"

	# add leading or trailing spaces
	[ "${pad_chr}" != "${line: -1}" ] && (( width > ${#line} )) && line="${line} "
	[ "${pad_chr}" != "${line:0:1}" ] && (( width > ${#line} )) && line=" ${line}"

	# determine if integers are even or odd
	local width_is_odd=$(( width == width / 2 * 2 ))
	local line_is_odd=$(( ${#line} == ${#line} / 2 * 2 ))

	# add trailing fillchar if nessisary
	(( width_is_odd != line_is_odd )) && (( width > ${#line} )) && line+=${pad_chr}

	# calculate pad_chr wing length
	width=$(( ( width - ${#line} ) / 2 ))

	# fill with repeating chars
	pad_chr=$(REPC ${width} "${pad_chr}")

	# return
	echo "${pad_chr}${line}${pad_chr}"
}
function PAD_SPLIT(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT:- 90}}
	# manditory pad character
	local pad_chr=$(PAD_CHR_TR "$1")
	shift
	
	# set split_chr; optional
	local split_delim="${1}"
	(( ${#split_delim} == 2 )) && [ "${split_delim:0:1}" == "${SPLIT_DELIM_DEFAULT:--}" ] \
		&& split_delim=${split_delim:1:1} && shift\
		|| split_delim=${SPLIT_DELIM_DEFAULT:--}

	# set right and left text entries
	local  left=$(echo "$@" | sed "s/\(.*\)[[:space:]]${split_delim}[[:space:]].*/\1/")
	local right=$(echo "$@" | sed "s/.*[[:space:]]${split_delim}[[:space:]]\(.*\)/\1/")

	# add leading or trailing spaces
	[ "${pad_chr}" != "${right:0:1}" ] && right=" ${right}"
	[ "${pad_chr}" != "${left: -1}" ] && left="${left} "
	
	# fill with repeating chars
	pad_chr=$(REPC $(( width - ${#left} - ${#right} )) "${pad_chr}")

	# prep return
	local line="${left}${pad_chr}${right}"

	# return
	echo "${line:0:${width}}"
}
###########################################################################################
###########################################################################################
function mesg_base(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT:- 90}}
	local desc=$1				# 1st  argument
	local title_left=$2$2$2$2		# 2nd  argument 
	local title_left=$'#'${title_left:0:3}	# only display the first four chars
	local title_right=${@:$#}		# last argument
	local title=${@:3:$#}			# 3rd-2nd_to_last argument
	# assemble mesg
	REPC         ${width} -u
	PAD_ANCHOR_L ${width} "${title_right}" "${title_left} ${title}"	| sed 's/./#/'
	PAD_ANCHOR_R ${width} -s "${desc}"				| sed 's/./#/'
	REPC         ${width} -257					| sed 's/./#/'
}
function desc(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT:- 90}}
	mesg_base		\
		${width}	\
		"$*"		\
		`printf "\273"` \
		Step[$step]\(`name_function $step`\):./$scriptName \{`time_stamp`\} \
		`printf "\253"`
}
function derr(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT:- 90}}
	local funcname=$(name_function $step | sed "s/^${prefix}_//;s/_/ /g")
	mesg_base		\
		${width}	\
		"$*"		\
		$'!'		\
		ERROR Step[$step]\(${funcname}\):./$scriptName \{`time_stamp`\} \
		$'!'
}
function mesg(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT:- 90}}
	mesg_base		\
		${width}	\
		"$*"		\
		`printf "\253"`	\
		Message [$buildScriptName \<\< $scriptName] \
		`printf "\273"`
}
function nogo(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT:- 90}}
	local funcname=$(name_function $step | sed "s/^${prefix}_//;s/_/ /g")
	mesg_base				\
		${width}			\
		"`retr_function_mesg_opts`"	\
		`printf "\277?"`		\
		SKIPPING! Step[$step]\(${funcname}\):./$scriptName \{`time_stamp`\} \
		`printf "\277?"`
		#show_function $step
		echo
}
function dump(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT:- 90}}
	local funcname=$(name_function $step | sed "s/^${prefix}_//;s/_/ /g")
	mesg_base				\
		${width}			\
		"`retr_function_mesg_opts`"	\
		' '				\
		Step[$step]\(${funcname}\)	\
		' '
		show_function $step
		echo
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
			if ${cmd[1]} -W 3 $dom 2>&1 | grep "has address" &> /dev/null; then
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

buildScriptExpectedFQFN="/bin/${buildScriptName}"

buildScriptSrc="https://raw.github.com/michaelsalisbury/builder/master/builder/${buildScriptName}"
#buildScriptSrc="http://10.173.119.78/scripts/system-setup/${buildScriptName}"

username=$(who -u | grep "(:" | head -1 | cut -f1 -d" ")
[ -z "$username" ] && username=root
userhome="$(cat /etc/passwd | grep $username | cut -f6 -d:)"
###########################################################################################
###########################################################################################
function garbage_collection(){ (
	while [ -n "`ps -p $$ --no-heading`" ]; do sleep 3; done
	rm -f "$buildScriptPipe"
) & }
function EXIT(){
	exit ${1:- 0}
}
###########################################################################################
###########################################################################################
builder_main "$@"
# nothing
