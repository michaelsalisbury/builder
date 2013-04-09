#!/bin/bash

# Depends on cifs-utils and winbind
# Ubuntu 12.10 does not support options; forceuid, forcegid

read -d $'' awk << END-OF-AWK
	{if ((\$1 == "$(whoami)")||(\$3 == "$(whoami)"))
		{print \$1" "\$3" "\$4" "\$6;}
	}
END-OF-AWK
read username uid gid home < <(awk -F: "${awk}" /etc/passwd)

# These options worked with Ubuntu 11.10 and 12.04
opt=(
iocharset=utf8
file_mode=0750
dir_mode=0750
uid=${uid}
forceuid=${uid}
gid=${gid}
forcegid=${gid}
sec=ntlmssp
)

# changes made for compatability with Ubuntu 12.10
opt=(
iocharset=utf8
file_mode=0750
dir_mode=0750
uid=${uid}
gid=${gid}
sec=ntlmssp
noperm
nounix
)
opt=${opt[*]}
opt=${opt// /,}

while read cred; do
	echo '######################################################################'
	echo
	cred=${cred##*/}
	fldr=${cred%-*}
	fldr=${fldr#*-}
	cred="credentials=${home}/${cred}"
	while read share; do
		[[ "${share}" =~ ^\ ?#+ ]] && continue
                 name=${share##*/}
                  mnt="${home}/${fldr}/${name}"
                match="(has been unmounted|not mounted)"
                for t in {0..10}; do
                        sudo umount -t cifs -v "${mnt}" 2>&1 | egrep "${match}" &> /dev/null && break
                        echo ERROR :: umount loop \#$t
                done
                mkdir -pv "${mnt}"

                sudo mount.cifs "${share}" "${mnt}" -o ${opt},${cred} 2>&1
                ! (( $? )) && task="SUCCESSFUL" || task="FAILED"

                echo "      SHARE = ${share}"
                echo "      MOUNT = ${mnt}"
                echo "    OPTIONS = ${opt}"
                echo "CREDENTIALS = ${cred}"
                echo "       TASK = ${task}"
                echo

	done < <(cat ${home}/.cifs-${fldr}-shares)
done < <(ls ${home}/.cifs-*-cred)
