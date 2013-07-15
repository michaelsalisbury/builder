#!/bin/bash

function main(){
	local my_var && set_var my_var
	#set_var my_var
	echo my_var :: ${my_var}




}
function set_var(){
	eval $1=hello



}


main

	echo my_var :: ${my_var}


exit





function switch_set_default2(){
	local ARG=-${1//-/}	# switch/arg
	local VALUE=$2		# default value for switch/arg
	# echo command for eval with calling function
	cat <<-EVAL
		eval [[ "\$*" =~ ${ARG}[[:space:]]- ]]	\
		|| [ "\${@: -1}" == "${ARG}" ]		\
		&& set -- "\${@/${ARG}/${ARG}${VALUE}}"
	EVAL
}
function switch_set_default(){
	local ARG=
	cat <<-CODE
		eval [ "${ARG}" == "-r" ] && echo hello
	CODE
}



echo -1 :: "${@: -1}"
echo BEFORE :: "$@"
`switch_set_default a 5`
`switch_set_default b 4`
`switch_set_default c 3`

echo AFTER :: "$@"
