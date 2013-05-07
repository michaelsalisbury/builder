#!/bin/bash

while read import; do
	echo $import
	. "${import}"
done < <(ls -1              "${scriptPath}"/functions.*.sh 2> /dev/null
	 ls -1 "${scriptPath}"/../functions/functions.*.sh 2> /dev/null)

foldername=$(dirname "$(readlink -f ${BASH_SOURCE})")
packagename=$(basename "${foldername}")

# create tgz
tar -zcvf "${packagename}.tgz" *

# folder list to copy package to
while read path; do
	[ -d "${path}" ] && cp "${packagename}.tgz" "${path}/."
done << PATH-LIST
	/var/www/packages/Apps_Linux

PATH-LIST


USERNAME=localcosadmin
PASSWORD='COSTech2010\!'

# host list to rsync updates to
while read IP HOST OTHER; do
	echo -n $IP
	SSH_VERIFY_PASSWORD ${USERNAME} ${IP} ${PASSWORD} && echo ::GOOD 

done << HOST-LIST
	10.171.252.38	dr-richardson-ch0	vnmrs500	BTMZRW1.cos.ucf.edu
	10.171.252.95	dr-richardson-ch1	mercury300	5T2TNC1.cos.ucf.edu
	10.173.152.119	dr-richardson-ps	avance400	BTN0SW1.cos.ucf.edu
	10.173.156.190	dr-jameshopper-nmr	Agilent-NMR	2UA20814VX.cos.ucf.edu
	10.173.152.117	dr-bochen-nmr		SSNMR
HOST-LIST

