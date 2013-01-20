#!/bin/bash

function setup() {
        srcHTTP=${1}
        filter=${2%_}_
        indexList=indexList.${filter%_}
        rm -f ${indexList}
        wget -O ${indexList} ${srcHTTP}
        sed 's/.*href=\"'${filter}'\([^\"]*\)\".*/\1/p;d' ${indexList} | while read file
                do
			echo ${scrFile} --- ${dstFile}
                        srcFile=${filter}${file}
                        dstFile=${file//@/\/}
                        mkdir -p ${dstFile%/*}
                        wget -O ${dstFile} ${srcHTTP}/${srcFile}
                done
}

function writeFile() {
cat << EOF >> /root/testFile
1234
ABCD
EOF
}

function setupRunOnce() {
echo Adding rc.run_once to rc.local
cat << EOF >> /etc/rc.d/rc.local
/etc/rc.d/rc.run_once >> /var/log/rc.run_once &
EOF
}
