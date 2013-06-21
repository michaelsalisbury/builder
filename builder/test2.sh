#!/bin/bash

function switch_set_default(){
	local ARG=-${1//-/}	# switch/arg
	local VALUE=$2		# default value for switch/arg
	# echo command for eval with calling function
	cat <<-EVAL
		eval [[ "\$*" =~ ${ARG}[[:space:]]- ]]	\
		|| [ "\${@: -1}" == "${ARG}" ]		\
		&& set -- "\${@/${ARG}/${ARG}${VALUE}}"
	EVAL
}

echo -1 :: "${@: -1}"
echo BEFORE :: "$@"
`switch_set_default a 5`
`switch_set_default b 4`
`switch_set_default c 3`

echo AFTER :: "$@"
