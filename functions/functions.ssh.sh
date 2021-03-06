#!/bin/bash

#source="https://raw.github.com/michaelsalisbury/builder/master/functions/${scriptName}"

function main(){
	local LOG="~/.logs/${scriptName}"
	local DOM='ucf.edu'

	echo ${FUNCNAME}
	return 0
	PUSH_KEYS
	return 0
	
	GET_HOSTNAME_SIMPLE 10.173.158.26 ${DOM}
	GET_HOSTNAME_DOM    10.173.158.26 ${DOM}

	SSH_COPY_ID $(whoami) 10.173.161.254 'xxxx'
	SSH_COPY_ID $(whoami) 10.173.161.50  'xxxx'
	SSH_COPY_ID $(whoami) 10.173.161.50  'xxxx' ~/.ssh/id_rsa.2945star

	SSH_COPY_ID root      10.173.161.50  'xxxx'
	SSH_COPY_ID root      10.173.161.50  'xxxx'      ~/.ssh/id_rsa.2945star 


	#IP_IS_UP ${IP}	&& echo "${IP}"
	#GET_HOSTNAME_SIMPLE ${IP} ${DOM}
	#GET_HOSTNAME_DOM    ${IP} ${DOM}
	#GET_HOST_ENTRY      ${IP} ${DOM}
}
function PUSH_KEYS(){
	local HOSTFILE=${1:- /etc/hosts}
	[ ! -f "${HOSTFILE}" ] && local HOSTFILE=/etc/hosts
	while read IP; do
		echo $IP
		#GET_HOST_ENTRY ${IP} ${DOM}
	done < <(cat /etc/hosts | awk '/^[0-9].*/{print $1}')

	local -A PASSWORDS=([root]='xxxx')
	PASSWORDS+=([localcosadmin]='xxxx')
	
	local IP=10.173.161.50
	for USERNAME in root localcosadmin; do
		echo password for ${USERNAME} is ${PASSWORDS[${USERNAME}]}
		SSH_VERIFY_PASSWORD ${USERNAME} ${IP} ${PASSWORDS[${USERNAME}]}\
			&& echo pass is good for ${USERNAME}\
			|| echo pass is broken for ${USERNAME}
		for KEY in ~/.ssh/id_rsa ~/.ssh/id_rsa.2945star /home/localcosadmin/.ssh/id_rsa  ; do
			echo $USERNAME $KEY

		done
	done
}
function SSH_COPY_ID_VIA_SUDO(){
	local USERNAME=$1
	local IP=$2
	local PASSWORD=$3
	local SUDOUSER=$4
	local KEY=${5:-$(find ~/.ssh/id_rsa.pub)}
	local KEY="${KEY%.pub}.pub"
	# verify that KEY file exists
	if [ ! -f "${KEY}" ]; then
		echo key \"${KEY}\" missing\!\! 1>&2
		echo _ERROR_ :: ${FUNCNAME} :: missing key${KEY:+[${KEY}]} for user[${USERNAME}] to [${IP}]
		return 1
	# verify that host is up via echo responce
	elif ! IP_IS_UP ${IP}; then
		echo _ERROR_ :: [${IP}] DOWN
		return 1
	# verify that host needs the ssh key in the first place
	elif ! HOST_NEEDS_SSHKEY ${USERNAME} ${IP} ${KEY:+"${KEY}"}; then
		echo SUCCESS :: user[${USERNAME}] has access @[${IP}] ${KEY:+ w-key[${KEY}]}
	# if the host grants access via the default key run ssh-copy-id without expect
	elif ! HOST_NEEDS_SSHKEY ${SUDOUSER} ${IP}; then
		cat <<-SSH-BASH-CMDS | ssh ${SUDOUSER}@${IP} "/bin/bash < <(cat)"
			USERHOME=\$(awk -F: '/^${USERNAME}:/{printf \$6}' /etc/passwd)
			echo '$(cat "${KEY}")' | /usr/bin/sudo tee -a "\${USERHOME}/.ssh/authorized_keys"
		SSH-BASH-CMDS
		HOST_NEEDS_SSHKEY ${USERNAME} ${IP} ${KEY:+"${KEY}"}\
			&& echo _ERROR_ :: ${FUNCNAME} :: failed adding key${KEY:+w-key[${KEY}]} for user[${USERNAME}]@[${IP}]\
			|| echo SUCCESS :: user[${USERNAME}] granted access @[${IP}] ${KEY:+ w-key[${KEY}]}
	# if the host requires a password for access via the SUDOUSER then verify password
	elif ! SSH_VERIFY_PASSWORD ${SUDOUSER} ${IP} ${PASSWORD}; then
		echo _ERROR_ :: ${FUNCNAME} :: user[${USERNAME}] failed password access @[${IP}]
	else
		echo
	fi
}
function SSH_COPY_ID(){
	local USERNAME=$1
	local IP=$2
	local PASSWORD=$3
	local KEY=${4:-$(find ~/.ssh/id_rsa.pub)}
	local KEY="${KEY%.pub}.pub"
	# verify that KEY file exists
	if [ ! -f "${KEY}" ]; then
		echo key \"${KEY}\" missing\!\! 1>&2
		echo _ERROR_ :: ${FUNCNAME} :: missing key${KEY:+[${KEY}]} for user[${USERNAME}] to [${IP}]
		return 1
	# verify that host is up via echo responce
	elif ! IP_IS_UP ${IP}; then
		echo "${IP}_DOWN"
		return 1
	# verify that host needs the ssh key in the first place
	elif ! HOST_NEEDS_SSHKEY ${USERNAME} ${IP} ${KEY:+"${KEY}"}; then
		echo SUCCESS :: user[${USERNAME}] has access @[${IP}] ${KEY:+ w-key[${KEY}]}
	# if the host grants access via the default key run ssh-copy-id without expect
	elif ! HOST_NEEDS_SSHKEY ${USERNAME} ${IP}; then
		ssh-copy-id ${KEY:+-i ${KEY}} ${USERNAME}@${IP} &> /dev/null\
                        && echo _ERROR_ :: ${FUNCNAME} :: failed adding key${KEY:+w-key[${KEY}]} for user[${USERNAME}]@[${IP}]\
                        || echo SUCCESS :: user[${USERNAME}] granted access @[${IP}] ${KEY:+ w-key[${KEY}]}
	# verify ssh username and password before running expect script
	elif ! SSH_VERIFY_PASSWORD ${USERNAME} ${IP} ${PASSWORD}; then
		echo _ERROR_ :: ${FUNCNAME} :: user[${USERNAME}] failed password access @[${IP}]
		return 1
	# copy ssh key via expect script
	else
		expect <(GET_EXPECT_SSH_COPY_ID ${USERNAME} ${IP} ${PASSWORD} ${KEY}) &> /dev/null\
                        && echo SUCCESS :: user[${USERNAME}] granted access @[${IP}] ${KEY:+ w-key[${KEY}]}\
                        || echo _ERROR_ :: ${FUNCNAME} :: failed adding key${KEY:+w-key[${KEY}]} for user[${USERNAME}]@[${IP}]
	fi
} 
function SSH_VERIFY_PASSWORD(){
	local USERNAME=$1
	local IP=$2
	local PASSWORD=$3
	! IP_IS_UP ${IP} && { echo IP \"${IP}\" is inaccesable\! 1>&2; return 1;}
	#expect <(GET_EXPECT_SSH_VERIFY_PASSWORD ${USERNAME} ${IP} ${PASSWORD})\
	expect <(GET_EXPECT_SSH_VERIFY_PASSWORD ${USERNAME} ${IP} ${PASSWORD}) &> /dev/null\
		&& return 0\
		|| { echo username[${USERNAME}] or password[${PASSWORD}] is incorrect\! 1>&2; return 1;}
}
function HOST_NEEDS_SSHKEY(){
	local USERNAME=$1
	local IP=$2
	local KEY=${3%.pub}
	[ -n "${KEY}" ] && [ ! -f "${KEY}" ] && { echo key \"${KEY}\" missing\!\! 1>&2; return 1;}
	ssh -n ${KEY:+-i "${KEY}"} -o passwordauthentication=no ${USERNAME}@${IP} 'who' &> /dev/null\
		&& return 1\
		|| return 0
}
function GET_HOST_ENTRY(){
	local IP=$1
	local DOM=$2
	if IP_IS_UP ${IP}; then
		local SIMPLE=$(GET_HOSTNAME_SIMPLE "${IP}" "${DOM}")
		local    DOM=$(GET_HOSTNAME_DOM    "${IP}" "${DOM}")
		echo "${IP}" "${DOM}" "${SIMPLE}"
	else
		echo -n ""
	fi
}
function IP_IS_UP(){ ping -A -w 3 -c 20 $1 &> /dev/null
	#ping -W 2 -c 1 $1 &> /dev/null	\
	#	&& return 0		\
	#	|| return 1
}
function GET_HOSTNAME_SIMPLE(){
	local IP=$1
	local DOM=$2
	local NAME=$(cat /etc/hosts		|\
		sed 's/[[:space:]]*#.*$//'	|\
		awk	-v IP="${IP}"		\
			-v DOM="${DOM}"		\
			'$0~"^"IP{for(i=2;i<=NF;i++)if(tolower($i)!~tolower(DOM))printf $i" "}')
	[ -n "${NAME}" ]\
		&& echo "${NAME}" \
		|| echo "-"
}
function GET_HOSTNAME_DOM(){
	local IP=$1
	local DOM=$2
	local NAME=$(cat /etc/hosts		|\
		sed 's/[[:space:]]*#.*$//'	|\
		awk	-v IP="${IP}"		\
			-v DOM="${DOM}"		\
			'$0~"^"IP{for(i=1;i<=NF;i++)if(tolower($i)~tolower(DOM))printf $i" "}')
	[ -n "${NAME}" ]\
		&& echo "${NAME}" \
		|| echo "-"
}
          #-o UserKnownHostsFile=/dev/null\
function GET_EXPECT_SSH_VERIFY_PASSWORD(){
	local USERNAME=$1
	local IP=$2
	local PASSWORD=$3
	cat <<-END-OF-EXPECT
		#!/usr/bin/expect -f
		set timeout -1
		spawn ssh -o NumberOfPasswordPrompts=1	\
		          -o PubkeyAuthentication=no	\
		          -o StrictHostKeyChecking=no	\
		          ${USERNAME}@${IP} exit
		match_max 100000
		expect *
		expect  -exact "password: "
		send -- "${PASSWORD}\r"
		expect eof
		catch wait result
		exit [lindex \$result 3]
	END-OF-EXPECT
#expect *
#send -- "exit\r"
}
function GET_EXPECT_SSH_COPY_ID(){
	local USERNAME=$1
	local IP=$2
	local PASSWORD=$3
	local KEY=${4:+"${4%.pub}.pub"}
	cat <<-END-OF-EXPECT
		#!/usr/bin/expect -f
		set timeout -1
		spawn ssh-copy-id ${KEY:+-i ${KEY}} ${USERNAME}@${IP}
		match_max 100000
		expect *
		expect  -exact "password: "
		send -- "${PASSWORD}\r"
		expect eof
		catch wait result
		exit [lindex \$result 3]
	END-OF-EXPECT
}

#main "$@"
