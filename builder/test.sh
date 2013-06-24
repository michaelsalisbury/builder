#!/bin/builder.sh
echo start
skip=( true true true false false true false )
step=7
prefix="setup"

function includes(){
	functions*.sh
	../functions/functions.sh
	../functions/functions*.sh
	../tmp/folder*
	../tmp/folder01/file03 03
	../tmp/fo*er 2/one
	../tmp/fo*er 2/*
}
function global_variables(){
	var_1=one
	var_2=two
	var_3=three
	var_4=$(echo 123\
		456\
		789)

	IFS=$'\n' read -d $'' -a var_5 < /etc/passwd
	IFS=${IFS_TMP}

	declare -a simpleArray=( )
	declare -A assocArray=( )
	declare -i integerVar=0

	read var_6 < <(echo "hello")

}
function main(){
	echo 1234


}
function setup_A_alpha(){
	echo $FUNCNAME
}
function setup_B_beta(){
	echo $FUNCNAME
}
function setup_C_charly(){
	echo $FUNCNAME
}
function setup_D_david(){
	echo $FUNCNAME
}
function setup_E(){
	echo $FUNCNAME
	echo var_1 :: $var_1
	echo var_2 :: $var_2
	echo var_3 :: $var_3
}
function setup_E_epsilon(){
	echo $FUNCNAME
}
