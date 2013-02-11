#!/bin/bash
function main(){
	# Read switches for rapper script
	switches "$@"
	shift $?

	# main logic 
	if   ${echo_help:-false}; then
		echo_help
		exit 1
	fi

	# update local database 
	git_fetch

	# if remote commits exits; LOG details then PULL
	if ! git_no_new_remote_commits; then
		git_list_remote_commits | git_commit_detail >> "${LOG}"
		git_pull
	fi

	return 0
}
function git_list_remote_commit(){
	git	--work-tree="${rootPath}"	\
		--git-dir="${rootPath}/.git"	\
		ls-remote			\
		origin				\
		-h HEAD				|\
	awk '{print $1}'
}
function git_list_remote_commits(){
	local until=`git_list_remote_commit`
	local since=`git_list_local_commit`
	git	--work-tree="${rootPath}"	\
		--git-dir="${rootPath}/.git"	\
		log				\
		--pretty="format:%H"		\
		${since}..${until}		|\
	uniq
}
function git_no_new_remote_commits(){
	(( `git_list_remote_commits | wc -l` )) && return 1 || return 0
}
function git_list_local_commit(){
	git_list_local_commits 1
}
function git_list_local_commits(){
	git	--work-tree="${rootPath}"	\
		--git-dir="${rootPath}/.git"	\
		rev-list			\
		--max-count=${1-10}		\
		HEAD
}
function git_commit_detail(){
	if [ -n "$1" ]; then
		echo $1 | ${FUNCNAME}
		return $?	
	fi
	while read commit; do
		local date=`git_commit_date ${commit}`
		local file=`git_commit_file ${commit}`
		echo $commit $date $file
	done
}
function git_commit_date(){
	if [ -n "$1" ]; then
		echo $1 | ${FUNCNAME}
		return $?	
	fi
	while read commit; do
		git	--work-tree="${rootPath}"	\
			--git-dir="${rootPath}/.git"	\
			log				\
			--pretty="format:%ai"		\
			-n 1				\
			${commit}
	done
}
function git_commit_file(){
	if [ -n "$1" ]; then
		echo $1 | ${FUNCNAME}
		return $?	
	fi
	while read commit; do
		git	--work-tree="${rootPath}"	\
			--git-dir="${rootPath}/.git"	\
			log				\
			--name-only			\
			--pretty="format:"		\
			-n 1				\
			${commit}			|\
		sed '/^$/d'
	done
}
function git_fetch(){
	lockout
	read -d $'' results < <(
		echo _____________________________________________________________________FETCH
		git	--work-tree="${rootPath}"	\
			--git-dir="${rootPath}/.git"	\
			fetch				\
			-a				\
			--progress 2>&1
		echo ---------------------------------------------------------------------DONE
	)
	if (( `echo "${results}" | wc -l` > 2 )); then
		info && echo "${results}" >> "${LOG}"
	fi
	unlock
}
function git_pull(){
	lockout
	read -d $'' results < <(
		echo _____________________________________________________________________PULL
		git	--work-tree="${rootPath}"       \
			--git-dir="${rootPath}/.git"    \
			pull 2>&1
		echo ---------------------------------------------------------------------DONE
	)
	info && echo "${results}" >> "${LOG}"
	unlock
}
function lockout(){
	local lockoutPath=${rootLockoutPath}\[${FUNCNAME[1]}\]
	sleep `random .5 .1`
	while [ -e "${lockoutPath}" ]; do
		case ${FUNCNAME[1]} in
			*)	;;
		esac
		local pid=$(cat "${lockoutPath}")
		local cmd=$(cat "${lockoutPath}" | xargs --no-run-if-empty -i@ ps --no-heading -o cmd -p @)
		if [ -n "${cmd}" ]; then
			debug && echo DEBUG\ \[$$\] ${e_name} holding for for action \"${FUNCNAME[1]}\" \[${pid}\] :: ${cmd:0:49} >> "${LOG}"
		else
			echo ERROR\ \[$$\] Found stale lockout file. Removing\! >> "${LOG}"
			rm -f "${lockoutPath}"
		fi
		sleep `random .5 .1`
	done
	read -d $'' results < <(echo $$ | tee "${lockoutPath}")
	debug && echo touched \`"${lockoutPath}"\' ::  ${results} >> "${LOG}"
}
function unlock(){
	local lockoutPath=${rootLockoutPath}\[${FUNCNAME[1]}\]
	read -d $'' results < <(rm -vf "${lockoutPath}")
	debug && echo "${results} :: $$" >> "${LOG}"
}
function random(){
	[ -z "$2" ] && local min='.25' || local min=$2
	[ -z "$1" ] && local max='1.0' || local max=$1
	echo scale=4 \; \( $max - $min \) \* $RANDOM / \( 2 ^ 15 \) + $min | bc
}
function debug(){
	${debug} && return 0 || return 1
}
function info(){
	${info} && return 0 || return 1
}
function escape_path(){
	ls -1 -d --quoting-style=escape "${1}"
}
function switches(){
        local OPTIND=
        local OPTARG=
        while getopts "hr:" OPTION
               do case $OPTION in
			h)	echo_help=true;;
			r)	rootPath=${OPTARG}
				rootPathEscaped=$(escape_path "${rootPath}")

				if read -a results < <(df -T | grep tmpfs.*lock); then
					rootLockoutPath=${results[@]: -1}
				elif read -a results < <(df -T | grep tmpfs.*shm); then
					rootLockoutPath=${results[@]: -1}
				elif read -a results < <(df -T | grep tmpfs.*user); then
					rootLockoutPath=${results[@]: -1}/$(whoami)
				else
					rootLockoutPath=/tmp
				fi
				rootLockoutPath+=/$(basename "${BASH_SOURCE}")
				[ ! -d "${rootLockoutPath}" ] && mkdir "${rootLockoutPath}"
				rootLockoutPath+=/_${rootPath//\//$'\\'}
				case `whoami` in
					root)	rootLOGPath="/var/log/"$(basename "${BASH_SOURCE}");;
					*)	rootLOGPath="~/log/"$(basename "${BASH_SOURCE}");;
				esac
				[ ! -d "${rootLOGPath}" ] && mkdir -p "${rootLOGPath}"
				rootLOGPath+=/_${rootPath//\//$'\\'}
				;;
                        ?)      ;;
                esac
        done
	# Minimum delay after git command
	gitCommandSleep=.5

	# Debug|info messages; true for on, false for off
	debug=false
	info=true

	# Set log file
	#LOG="/var/log/incron_test.log"
	LOG="${rootLOGPath}"

	return $(($OPTIND - 1))
}
main "$@"
#main -r '/var/www/repos/github/michaelsalisbury_builder'
