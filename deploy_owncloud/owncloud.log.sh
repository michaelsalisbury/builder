#!/bin/bash
log=/var/log/owncloud_mysql
mail="michael.salisbury@ucf.edu michael.salisbury@ucf.edu"

actions(){
	while read action data
		do
			case ${action} in
				user_added)
						echo "$(date) ::: User Added   [${data}]" >> ${log}
						email ${action} ${data}
						;;
				user_removed)
						echo "$(date) ::: User Removed [${data}]" >> ${log}
						email ${action} ${data}
						;;
			esac
		done
}
email(){
	for address in ${mail}
		do
			mail -s "$(hostname) ::: $1" ${address}  << END-OF-MESSAGE
$2
END-OF-MESSAGE
		done
}

if [[ "$1" = "/tmp/owncloud_log" ]]; then
	mv -f "$1" "$1$$"
	cat        "$1$$" | actions
	rm -f      "$1$$"
fi

