#!/bin/builder.sh
skip=( false false false false )
step=1
prefix="setup"
source="https://raw.github.com/michaelsalisbury/builder/master/defaults/${scriptName}"
#source=http://10.173.119.78/scripts/system-setup/$scriptName

# IMPORTANT: Includes must be placed before global variables like "skip" & "step"
function includes(){
	functions.*.sh
	../functions/functions.*.sh
}
function global_variables(){
	echo
	read -d $'' g_domains <<-END-OF-DOMAINS
		cos.ucf.edu
		net.ucf.edu
		mydomain.org
	END-OF-DOMAINS
}

function setup_skel_Structure(){
	desc Build skel directory structure
	touch      /etc/sudoers.d/cifs
	chmod 440  /etc/sudoers.d/cifs
	touch      /etc/xdg/autostart/mount.domain_cifs.desktop
        ln         /etc/xdg/autostart/mount.domain_cifs.desktop /etc/xdg/xdg-xubuntu/autostart/. 2>/dev/null
        ln         /etc/xdg/autostart/mount.domain_cifs.desktop /etc/xdg/xdg-kubuntu/autostart/. 2>/dev/null
	mkdir -p   /etc/skel/.scripts
	chmod 700  /etc/skel/.scripts
	mkdir -p   /etc/skel/.logs
	chmod 700  /etc/skel/.logs
	local scriptBase=$(basename "${scriptName}" .sh)
	cp "${scriptPath}/${scriptBase}.mount.sh" /etc/skel/.scripts/mount.domain_cifs.sh
	chmod u+x                                 /etc/skel/.scripts/mount.domain_cifs.sh
	for domain in $g_domains; do
		touch     /etc/skel/.cifs-${domain}-cred
		chmod 600 /etc/skel/.cifs-${domain}-cred
		touch     /etc/skel/.cifs-${domain}-shares
		chmod 600 /etc/skel/.cifs-${domain}-shares
	done
	mkdir -p   /etc/skel/.config/xfce4/autostart
	chmod 700  /etc/skel/.config/xfce4
	mkdir -p   /etc/skel/.kde/Autostart
	chmod 700  /etc/skel/.kde
	groupadd -g $(free_ID_pair 100) cifs
}
function setup_make_Config(){
	desc Setting up default config
	cat <<-END-OF-ALIASES > /etc/profile.d/cifs.sh
		alias    mount.d='\${HOME}/.scripts/mount.domain_cifs.sh'
		alias  mount.dom='\${HOME}/.scripts/mount.domain_cifs.sh'
		alias domain.mnt='\${HOME}/.scripts/mount.domain_cifs.sh'
	END-OF-ALIASES
	for domain in $g_domains; do
		cat <<-END-OF-CONF > /etc/skel/.cifs-${domain}-cred
			username=[NID]
			password=[***]
			domain=${domain}
		END-OF-CONF
	done
	cat <<-END-OF-SUDOERS > /etc/sudoers.d/cifs
		# cifs
		%cifs ALL=(root) NOPASSWD:/sbin/mount.cifs
		%cifs ALL=(root) NOPASSWD:/bin/umount -t cifs -v /home/*
	END-OF-SUDOERS
	cat <<-END-OF-DESKTOP > /etc/xdg/autostart/mount.domain_cifs.desktop
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
	##############################################################
	get_user_details all | while read user uid gid home; do
		usermod -a -G cifs ${user}
		cat <<-END-OF-CMDS | su - ${user} -s /bin/bash
			mkdir -p  "\${HOME}/.scripts"
			chmod 750 "\${HOME}/.scripts"
			mkdir -p  "\${HOME}/.logs"
			chmod 750 "\${HOME}/.logs"
			touch     "\${HOME}/.scripts/mount.domain_cifs.sh"
			chmod 550 "\${HOME}/.scripts/mount.domain_cifs.sh"
		END-OF-CMDS
		while read file; do
			[      -f "${home}/${file}" ]		&&\
			! (( `cat "${home}/${file}" | wc -c` ))	&&\
			cat "/etc/skel/${file}" > "${home}/${file}"
		done <<-WHILE
			.scripts/mount.domain_cifs.sh
		WHILE

		for domain in $g_domains; do
			cat <<-END-OF-CMDS | su - ${user} -s /bin/bash
		                touch     "\${HOME}/.cifs-${domain}-cred"
				chmod 600 "\${HOME}/.cifs-${domain}-cred"
				touch     "\${HOME}/.cifs-${domain}-shares"
				chmod 600 "\${HOME}/.cifs-${domain}-shares"
			END-OF-CMDS
			while read file; do
				[      -f "${home}/${file}" ]		&&\
				! (( `cat "${home}/${file}" | wc -c` ))	&&\
				cat "/etc/skel/${file}" > "${home}/${file}"
			done <<-WHILE
				.cifs-${domain}-cred
				.cifs-${domain}-shares
			WHILE
		done
	done
}

