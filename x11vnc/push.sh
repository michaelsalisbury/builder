#!/bin/builder.sh
skip=( false false false false )
step=1
prefix="push"

function includes(){
	functions.*.sh
	../functions/functions.*.sh
}
function global_variables(){
	SSH_USERNAME='localcosadmin'
	SSH_PASSWORD='xxxx'
	push_packagename=$(basename "${scriptPath}")
}
function host_list(){
	cat << HOST-LIST
		#10.171.252.38	dr-richardson-ch0	vnmrs500	BTMZRW1.cos.ucf.edu
		10.171.252.95	dr-richardson-ch1	mercury300	5T2TNC1.cos.ucf.edu
		#10.173.152.119	dr-richardson-ps	avance400	BTN0SW1.cos.ucf.edu
		#10.173.156.190	dr-jameshopper-nmr	Agilent-NMR	2UA20814VX.cos.ucf.edu
		#10.173.152.117	dr-bochen-nmr		SSNMR
HOST-LIST
}
function push_main(){
	desc main
	cd "${scriptPath}"
	# create tgz
	rm     -f "${push_packagename}.tgz" 
	tar -zcvf "${push_packagename}.tgz"	\
		aliases				\
		tigervnc*			\
		install.*			\
		allowed.*			\
		xinetd.*			\
		Xcommon-functions.sh		\
		x11vnc.sh			\
		Xvnc-dynamic.sh			\
		xstartup
		

	# folder list to copy package to
	while read path; do
		[ -d "${path}" ] && cp "${push_packagename}.tgz" "${path}/."
	done << PATH-LIST
		/var/www/packages/Apps_Linux

PATH-LIST
}
function push_test(){
	desc \test

	# host list to rsync updates to
	while read IP HOST OTHER; do
		echo -n $IP
		SSH_VERIFY_PASSWORD  ${SSH_USERNAME} ${IP} ${SSH_PASSWORD} && echo ::GOOD[$HOST]
		SSH_COPY_ID_VIA_SUDO "root" ${IP} ${SSH_PASSWORD} ${SSH_USERNAME} "/root/.ssh/id_rsa"
		#SSH_COPY_ID         ${SSH_USERNAME} ${IP} ${SSH_PASSWORD} "/root/.ssh/id_rsa"
		#SSH_COPY_ID         ${SSH_USERNAME} ${IP} ${SSH_PASSWORD} "/home/localcosadmin/.ssh/id_rsa"
		#SSH_COPY_ID         ${SSH_USERNAME} ${IP} ${SSH_PASSWORD} "/home/localcosadmin/.ssh/id_rsa.2945star"
	
	done < <(host_list | sed '/^[[:space:]]*#/d')
}


