#!/bin/builder.sh
skip=( false false false false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/system-setup/$scriptName

while read import; do
	. "${import}"
done < <(ls -1              "${scriptPath}"/functions.*.sh 2> /dev/null
	 ls -1 "${scriptPath}"/../functions/functions.*.sh 2> /dev/null)


function setup_make_Config()
	desc Setting up default config
	
	cat << END-OF-




	cat << END-OF-ALIASES > /etc/profile.d/cifs.sh
alias    mount.d='\${HOME}/.scripts/mount.domain_cifs.sh'
alias  mount.dom='\${HOME}/.scripts/mount.domain_cifs.sh'
alias domain.mnt='\${HOME}/.scripts/mount.domain_cifs.sh'
END-OF-ALIASES
	for domain in $g_domains; do
		cat << END-OF-CONF > /etc/skel/.cifs-${domain}-cred
username=[NID]
password=[***]
domain=${domain}
END-OF-CONF
	done
	cat << END-OF-SUDOERS > /etc/sudoers.d/cifs
# cifs
%cifs ALL=(root) NOPASSWD:/sbin/mount.cifs
%cifs ALL=(root) NOPASSWD:/bin/umount -t cifs -v /home/*
END-OF-SUDOERS
	cat << END-OF-DESKTOP > /etc/xdg/autostart/mount.domain_cifs.desktop
[Desktop Entry]
Type=Application
Exec=/bin/bash -c \\\${HOME}/.scripts/mount.domain_cifs.sh
Hidden=false
NoDisplay=true
Terminal=true
X-GNOME-Autostart-enabled=true
Name[en_US]=CIFS Automount
Name=CIFS Automount
Comment[en_US]=
Comment=
END-OF-DESKTOP
	# Modify /etc/adduser.conf to include new group openconnect
	add_default_group cifs
}
function setup_distribute_Config(){
	desc setting up default config \for existing users
	local scriptBase=$(basename "${scriptName}" .sh)
	get_user_details all | while read user uid gid home; do
		usermod -a -G cifs ${user}
		su -m ${user} < <(cat << END-OF-CMDS
			mkdir -p  "${home}/.scripts
			chmod 750 "${home}/.scripts
			mkdir -p  "${home}/.logs
			chmod 750 "${home}/.logs
			cp "/etc/skel/.scripts/mount.domain_cifs.sh" "${home}/.scripts/.
			chmod 750                                    "${home}/.scripts/mount.domain_cifs.sh"
			cp "/etc/skel/.cifs-*"                       "${home}/."
			chmod 600                                    "${home}/.cifs-*
END-OF-CMDS
)
	done
}

