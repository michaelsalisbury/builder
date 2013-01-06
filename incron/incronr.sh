#!/bin/bash

function main(){
	# Set log file
	LOG="/var/log/incron-recursive.log"

	# Read switches for rapper script
	switches "$@"
	shift $?

	# Set global variables
	incronRapperFQFN=$(readlink -nf "$BASH_SOURCE")
	incronRapperEscaped=$(ls -1 -d --quoting-style=escape "${incronRapperFQFN}")
	incronRapperName=$(basename "$incronRapperFQFN")
	incronRapperPath=$(dirname  "$incronRapperFQFN")

	if   ${echo_help:-false}; then
		echo_help

	elif ${recursive:-false}; then
		process_recursive_tree_event "$@"

	elif ${disable:-false}; then
		disable_recursive_tree_confs

	elif ${build:-false}; then
		build_recursive_tree_confs "$@"

	fi
}
###########################################################################################
###########################################################################################
function escape_path(){
	ls -1 -d --quoting-style=escape "${1}"
}
function set_recursive_conf_paths(){
	recursiveMON="${incronPath}/${incronConf}-recursiveMON.conf"
	recursiveCMD="${incronPath}/${incronConf}-recursiveCMD.conf"
}
function del_MON_Entry(){
	sed -i "\|^${recursiveTreePathEscaped//\\/$'\\\\\\\\'} IN_|d" "${recursiveMON}"
}
function del_CMD_Entry(){
	sed -i "\|^${recursiveTreePathEscaped//\\/$'\\\\\\\\'} IN_|d" "${recursiveCMD}"
}
function add_MON_Entry(){
	echo	"${recursiveTreePathEscaped}"	\
		IN_CREATE,IN_DELETE		\
		"${incronRapperEscaped}"	\
		-r				\
		-c "${incronFQFNEscaped}"	\
		\$% \$@/\$#			\
	>> "${recursiveMON}"
	tail -1 "${recursiveMON}" >> "${LOG}"
}
function add_CMD_Entry(){
	while read rootPath; do
		# verify that the event path exists
		[ -d "${rootPath}" ] || continue
		rootPathEscaped=$(escape_path "${rootPath}")
		# test if event path is a parent directory to the recursiveTreePath, skip event rule otherwise
		[[ "${recursiveTreePathEscaped}"/ =~ ^"${rootPathEscaped}"/  ]] || continue
		# test if event path matches the recursiveTestPath, skip if true, rule exists in source config
		[[ "${recursiveTreePathEscaped}"/ =~ ^"${rootPathEscaped}"/$ ]] && continue

		# double the forward slashes in prep for the sed command
		local rpsp=${rootPathEscaped//\\/$'\\\\'}
		local rtsp=${recursiveTreePathEscaped//\\/$'\\\\'}
		
		# replace event rule target directory with the recursiveTreePath
		# write the rule to the recursive CMD config file
		# drop event rules that arn't a perent directory
		sed "s|^${rpsp}\([\ \t]*IN_\)|${rtsp}\1|p;d" "${incronFQFN}" >> "${recursiveCMD}"

	# List the event paths skipping empty or commented out lines
	done < <(	sed '/^\(#\|$\)/d;s/[\ \t]*IN_.*//' "${incronFQFN}" | \
			sort -r
		)
	tail -1 "${recursiveCMD}" >> "${LOG}"
#	cat << END-OF-LOG >> /var/log/incron_test.log
#recursiveTreePathEscaped :: ${recursiveTreePathEscaped}
#END-OF-LOG
}
function disable_recursive_tree_confs(){
	[ -f "${incronFQFN}" ] || exit 1

	rm -f "${recursiveMON}"
	rm -f "${recursiveCMD}"
}
function   build_recursive_tree_confs(){
	[ -f "${incronFQFN}" ] || exit 1

	rm -f "${recursiveMON}"
	rm -f "${recursiveCMD}"

	touch "${recursiveMON}"
	touch "${recursiveCMD}"

	while read rootPath; do
		# verify that the event path exists
		[ -d "${rootPath}" ] || continue
		rootPathEscaped=$(escape_path "${rootPath}")
		# test if the event path is a subdirectory of previos path and skip if true
		[[ ${rootPathEscaped}/ =~ ^${lastPathEscaped:-/dev/null}/ ]] && continue
		# record rootPath for subdirectory test in next iteration
		lastPathEscaped=${rootPathEscaped}

		while read recursiveTreePathEscaped; do
			add_MON_Entry
			add_CMD_Entry
		# list directory tree with all special characters escaped
		# use sed to double forward slashed so they servive variable assignment
		done < <(	find "${rootPath}" -type d -exec	  \
				ls -1 -d --quoting-style=escape {} \;	| \
				sed 's/\\/\\\\/g'			| \
				sort
			)
	# List the event paths skipping empty or commented out lines
	done < <(	sed '/^\(#\|$\)/d;s/[\ \t]*IN_.*//' "${incronFQFN}" | \
			sort -r
		)
}
function process_recursive_tree_event(){
	[[ "$1" =~ IN_ISDIR ]] || return 0

	# Process input passed from calling function
	local recursiveTreeEvent=$1
	shift
	recursiveTreePath=$@
	recursiveTreePathEscaped=$(escape_path "${recursiveTreePath}")

	del_MON_Entry
	del_CMD_Entry

	if [[ "${recursiveTreeEvent}" =~ IN_CREATE ]]; then
		add_MON_Entry
		add_CMD_Entry
	fi
}

###########################################################################################
###########################################################################################
function switches(){
        local OPTIND=
        local OPTARG=
        while getopts "bc:de:f:hr" OPTION
               do case $OPTION in
			b)	build=true;;
			c)	incronFQFN=$OPTARG
				incronConf=$(basename "${incronFQFN}")
				incronPath=$(dirname  "${incronFQFN}")
				incronFQFNEscaped=$(escape_path "${incronFQFN}")
				set_recursive_conf_paths;;
			d)	disable=true;;
			e)	events=${OPTARG}
				[[ "${events}" =~ IN_ISDIR       ]] && isdir=true      || isdir=false
				[[ "${events}" =~ IN_CREATE      ]] && e_create=true   || e_create=false
				[[ "${events}" =~ IN_DELETE      ]] && e_delete=true   || e_delete=false
				[[ "${events}" =~ IN_MODIFY      ]] && e_modify=true   || e_modify=false
				[[ "${events}" =~ IN_CLOSE_WRITE ]] && e_modified=true || e_modified=false
				;;
			f)	e_FQFN=${OPTARG}
				e_FQFNEscaped=$(escape_path "${e_FQFN}")
				e_path=$(dirname  "${e_FQFN}")
				e_name=$(basename "${e_FQFN}")
				;;
			h)	echo_help=true;;
			r)	recursive=true;;
                        ?)      ;;
                esac
        done
        return $(($OPTIND - 1))
}
function echo_help(){
	cat << END-OF-HELP
---------------------------------------------------------------
# IN_ACCESS        File was accessed (read) (*)
# IN_ATTRIB        Metadata changed (permissions, timestamps, extended attributes, etc.) (*)
# IN_CLOSE_WRITE   File opened for writing was closed (*)
# IN_CLOSE_NOWRITE File not opened for writing was closed (*)
# IN_CREATE        File/directory created in watched directory (*)
# IN_DELETE        File/directory deleted from watched directory (*)
# IN_DELETE_SELF   Watched file/directory was itself deleted
# IN_MODIFY        File was modified (*)
# IN_MOVE_SELF     Watched file/directory was itself moved
# IN_MOVED_FROM    File moved out of watched directory (*)
# IN_MOVED_TO      File moved into watched directory (*)
# IN_OPEN          File was opened (*)

# \$$ - a dollar sign
# \$@ - the watched filesystem path (see above)
# \$# - the event-related file name
# \$% - the event flags (textually)
# \$& - the event flags (numerically)
---------------------------------------------------------------
SWITCHES

 -h  this help message
 -b  rebuild the recursive config files (requires -c)
 -c  [full path to incron config file]
 -r  process a recursive event (requires -c & event type & path)

USAGE (ENABLE)
${incronRapperName} -b -c [full path to incron config file]

USAGE (DISABLE)
${incronRapperName} -d -c [full path to incron config file]

END-OF-HELP
}
###########################################################################################
###########################################################################################
main "$@"
