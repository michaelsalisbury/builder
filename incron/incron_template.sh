#!/bin/bash

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


# $$ - a dollar sign
# $@ - the watched filesystem path (see above)
# $# - the event-related file name
# $% - the event flags (textually)
# $& - the event flags (numerically)

function main(){
	# Set log file
	LOG="/var/log/incron_test.log"

	# Read switches for rapper script
	switches "$@"
	shift $?

	# main logic 
	if   ${echo_help:-false}; then
		echo_help
	fi

	# log
	cat << END-OF-LOG >> "${LOG}"
events :: ${events}
e_FQFN :: ${e_FQFN}
isdir  :: ${isdir}

END-OF-LOG

}
function escape_path(){
	ls -1 -d --quoting-style=escape "${1}"
}
function switches(){
        local OPTIND=
        local OPTARG=
        while getopts "e:f:hr:" OPTION
               do case $OPTION in
			e)	events=${OPTARG}
				[[ "${events}" =~ IN_ISDIR  ]] && isdir=true    || isdir=false
				[[ "${events}" =~ IN_CREATE ]] && e_create=true || e_create=false
				[[ "${events}" =~ IN_DELETE ]] && e_delete=true || e_delete=false
				[[ "${events}" =~ IN_MODIFY ]] && e_modify=true || e_modify=false
				;;
			f)	e_FQFN=${OPTARG}
				e_FQFNEscaped=$(escape_path "${e_FQFN}")
				e_path=$(dirname  "${e_FQFN}")
				e_name=$(basename "${e_FQFN}")
				;;
			h)	echo_help=true;;
			r)	rootPath=${OPTARG}
				rootPathEscaped=$(escape_path "${rootPath}")
				;;
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
 -e  [events (texual \$%)]
 -f  [absoluet event path (\$@/\$#)]
 -r  [absolute root path]

END-OF-HELP
}
main "$@"
