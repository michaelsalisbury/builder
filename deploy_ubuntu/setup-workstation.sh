#!/bin/builder.sh

# IMPORTANT: Includes must be placed before global variables like "skip" & "step"
while read import; do
        source <(sed '1,/^function/{/^function/p;d}' "${import}")
done < <(
	ls -1                           /etc/lsb-release 2> /dev/null
	ls -1              "${scriptPath}"/functions*.sh 2> /dev/null
	ls -1 "${scriptPath}"/../functions/functions*.sh 2> /dev/null
)

# GLOBAL VARIABLES
skip=( false false false false false false false false false false false false false false false false false false false false false false false false false false false false false false false false false false false false false false false false false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/system-setup/$scriptName
subScriptBase="/root/system-setup/`basename ${source}`"
#source=http://192.168.253.1/kickstart/ubuntu/s.xubuntu/deploys/$scriptName


aptopt="-y -q"
autoLoginUser="localcosadmin"
#autoLoginShell="ubuntu"
#autoLoginShell="gnome-session-fallback"
autoLoginShell="xfce4-session"

function networkUpMsg(){ echo Network UP\!; } 

###########################################################################################
###########################################################################################
function setup_Prep_Add_sudo(){
	desc Prep: Enable sudo wihout password \(2 prompts\)
	while read username; do
		[[ "`whoami`" != "root" ]] && local sudo='sudo' || unset sudo
		echo "${username} ALL=(ALL) NOPASSWD: ALL" | ${sudo} tee       /etc/sudoers.d/admin
		                                             ${sudo} chmod 440 /etc/sudoers.d/admin
		for group in adm admin sudo syslog; do
			${sudo} usermod -a -G $group ${username}
		done
	done < <(awk -F : '/:1000:/{print $1}' /etc/passwd)
}
function setup_Prep_Basic_Firewall(){
	desc Prep: Enable basic firewall
	# To enable or disable modify /etc/ufw/ufw.conf
	# Rules are stored in /lib/ufw/user.rules and /lib/ufw/user6.rules
	# Custom rules like masquerade can be added to /etc/
	waitAptgetInstall
        apt-get ${aptopt} install gufw
	local ufw='/usr/sbin/ufw'
	$ufw enable
	$ufw status verbose
	$ufw allow ssh
	$ufw allow from 10.173.119.64/26 to any port ssh	# COSIT Service Desk
	$ufw allow from 10.173.152.0/24  to any port ssh	# PS 1st Floor
	$ufw allow from 10.173.153.0/24  to any port ssh	# PS 2nd Floor Cluster
	$ufw allow from 10.173.154.0/24  to any port ssh	# PS 2nd Floor
	$ufw allow from 10.173.156.0/24  to any port ssh	# PS 3rd Floor
	$ufw allow from 10.173.161.0/24  to any port ssh	# PS 3rd Floor Cluster
	$ufw allow from 10.173.158.0/24  to any port ssh	# PS 4th Floor
	$ufw allow from 10.173.117.0/24  to any port ssh	# MAP
	$ufw allow from 10.173.160.0/24  to any port ssh	# MAP Cluster
	$ufw allow from 10.173.252.0/24  to any port ssh	# Chemistry
	$ufw allow from 10.173.252.0/24  to any port ssh	# Chemistry
	$ufw allow from 10.36.0.0/18     to any port ssh	# WiFi
	$ufw allow from 10.173.252.0/24  to any port ssh	# VPN
	#$ufw allow http
	#$ufw allow https
	#$ufw allow nfs		#ufw allow from 0.0.0.0/0 to any port 2049
	#$ufw allow sunrpc	#ufw allow from 0.0.0.0/0 to any port 111
	#$ufw allow 13025	#ufw allow from 0.0.0.0/0 to any port 13025
	$ufw --force reload
}
function setup_Prep_Policy_Changes(){
	desc Prep: Make system wide Policy changes
	# Command      Policy File     Action  Old              New
	policy_change  NetworkManager  system  auth_admin_keep  yes
}
function setup_Prep_UCF(){
	desc Prep: openconnect, cifs
	# setup defaults for the following applications
		read -d $'' apps << EOL
			openconnect-ucf.edu
			cifs-ucf.edu
			UCF_WPA2-ucf.edu
EOL
	# locate and run installers
		for app in $apps; do
        		ls -1             "${scriptPath}"/defaults.${app}.sh 2> /dev/null
        		ls -1 "${scriptPath}"/../defaults/defaults.${app}.sh 2> /dev/null
		done | while read script; do
			"${script:-false}" -rr
		done
}
function setup_Prep_Add_SSH_Keys(){
	desc Prep: Add SSH Keys to root \& users: uid \>= 1000
	set_ssh_authorized_keys	all
}
function setup_Prep_Disable_Guest(){
	desc disable guest login
	sed -i.bk`date "+%s"` '/^allow-guest=/d'                     /etc/lightdm/lightdm.conf
	sed -i.bk`date "+%s"` '/\[SeatDefaults\]/aallow-guest=false' /etc/lightdm/lightdm.conf
}
function setup_Prep_Tweak_Apt_Cacher(){
	desc append options to apt cacher client config
        waitForNetwork || return 1
	# Find apt cacher client config and append changes
	read -d $'' new_entries << END-OF-ENTRIES
Acquire::http::Timeout "2";
END-OF-ENTRIES
	new_entries=${new_entries//$'\n'/\\\n} ### prep variable for multi-line sed append ###
	egrep -l -R "^Acquire::http::Proxy " /etc/apt |\
	xargs -i@ sed -i.bk`date "+%s"` "/^Acquire::http::Proxy /a${new_entries}" @
	# Refresh apt cache and update
	waitAptgetUpdate
	apt-get clean
	waitAptgetUpdate
	apt-get autoclean
	waitAptgetUpdate
	apt-get update
}
function setup_Prep_Disable_Apt_Cacher(){
	desc disconect from apt-cacher
        waitForNetwork || return 1
	# Backup and comment out all entries
	egrep -l -R '^Acquire' /etc/apt |\
	xargs -i@ sed -i.bk`date "+%s"` '/^Acquire/ s/^/#/' @
	# Refresh apt cache and update
	waitAptgetUpdate
	apt-get clean
	waitAptgetUpdate
	apt-get autoclean
	waitAptgetUpdate
	apt-get update
}
function setup_Prep_Enable_Autologin(){
	desc Auto logon sys admin
	# setup autologin user
	/usr/lib/lightdm/lightdm-set-defaults --autologin ${autoLoginUser}
	# setup autologin timeout
	cp /etc/lightdm/lightdm.conf                          /etc/lightdm/lightdm.bk`date "+%s"`
	sed -i '/^autologin-user-timeout=/d'                  /etc/lightdm/lightdm.conf
	sed -i '/^\[SeatDefaults\]/aautologin-user-timeout=3' /etc/lightdm/lightdm.conf
}
function setup_Prep_Config_Autostart(){
	desc Tail logs and sys resouces at logon
	# asume that the first user created is the system admin
	read user uid gid home < <(get_user_details 1000)
	local desktop='.config/autostart/terminator-deploy.desktop'
	# setup autostart directory for Unity/GNOME, XFCE (Xubuntu) and KDE (Kubuntu)
	su ${user} << END-OF-MKDIR
	mkdir ${home}/.config/autostart
	touch ${home}/${desktop}
	mkdir -p ${home}/.config/xfce4/autostart
	mkdir -p ${home}/.kde/Autostart
	ln ${home}/${desktop} ${home}/.config/xfce4/autostart/.
	ln ${home}/${desktop} ${home}/.kde/Autostart/.
END-OF-MKDIR
	# autostart terminator -l Deploy desktop config file
	su ${user} << END-OF-TERMINATOR.DESKTOP
	cat << END-OF-DESKTOP_ENTRY > ${home}/${desktop}
[Desktop Entry]
Type=Application
Exec=/usr/bin/terminator -m -l Deploy
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=Terminator-Deploy
Name=Terminator-Deploy
Comment[en_US]=Terminator Deploy Layout
Comment=Terminator Deploy Layout
END-OF-DESKTOP_ENTRY
END-OF-TERMINATOR.DESKTOP
	su ${user} << END-OF-MKDIR
END-OF-MKDIR
}

function setup_Prep_Hostname(){
	desc \set hostname to vendor serial: Dell
	opts='-o ppid --no-heading'
	echo "  PID" = `ps -o pid,ppid,cmd --no-heading -p $$`
	echo " PPID" = `ps -o pid,ppid,cmd --no-heading -p $(ps $opts -p $$)`
	echo "PPPID" = `ps -o pid,ppid,cmd --no-heading -p $(ps $opts -p $(ps $opts -p $$))`
	${scriptPath}/../defaults/defaults.terminator.sh -i layout


}
function setup_Prep_Add_Aliases(){
	desc Setup Aliases
	cat << EOF > /etc/profile.d/aliases.sh
alias ll='ls -la --color'
alias     startXFCE='startxfce4'
alias startFallback='echo dbus-launch gnome-session --session=gnome-fallback > ~/.xinitrc; startx'
alias  startClassic='echo dbus-launch gnome-session --session=gnome-classic  > ~/.xinitrc; startx'
alias    startUnity='sudo /usr/lib/lightdm/lightdm-set-default -s ubuntu; sudo start lightdm'
alias     startLXDE=''
EOF
}
function setup_Prep_Add_Repos(){
        desc Prep: Add repos
        waitForNetwork || return 1

	# Add Oracle VirtualBox Repo
	echo "deb http://download.virtualbox.org/virtualbox/debian $DISTRIB_CODENAME contrib" > \
	"/etc/apt/sources.list.d/oracle-virtualbox.list"
	wget -q -O - http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc | apt-key add -

	# Add Google Chrome Repo
	echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > \
	"/etc/apt/sources.list.d/google-chrome.list"
	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -

	# Add UCK Repos
	rm -f "/etc/apt/sources.list.d/uck-team"*
	add-apt-repository -y ppa:uck-team/uck-stable
	sed -i '/^deb/{ h; s/^/#/; x;s/quantal/precise/; G; }' \
	"/etc/apt/sources.list.d/uck-team-uck-stable-quantal.list"
	add-apt-repository -y ppa:uck-team/uck-unstable
        sed -i '/^deb/{ h; s/^/#/; x; s/quantal/oneiric/; G; }' \
	"/etc/apt/sources.list.d/uck-team-uck-unstable-quantal.list"

	# Add Adobe Repo
	sed -i.save 's/^/#/' "/etc/apt/sources.list.d/canonical_Adobe.list"
	for repo in								\
	"deb http://archive.canonical.com/ubuntu precise partner"		\
	"deb-src http://archive.canonical.com/ubuntu precise partner"		\
	"deb http://archive.canonical.com/ubuntu `lsb_release -sc` partner"	\
	"deb-src http://archive.canonical.com/ubuntu `lsb_release -sc` partner"
	do echo ${repo} >> "/etc/apt/sources.list.d/canonical_Adobe.list"; done

	# Add Medibuntu repo for free and non-free packages like acroread
	wget -O "/etc/apt/sources.list.d/medibuntu.list" \
	http://www.medibuntu.org/sources.list.d/$(lsb_release -cs).list
	apt-get --quiet update
	apt-get --yes --quiet --allow-unauthenticated install medibuntu-keyring

	# Oracle Java
	add-apt-repository -y ppa:webupd8team/java

	# Add X2GO Repos
	add-apt-repository -y ppa:x2go/stable

	# Add Grub Customizer Repos
	add-apt-repository -y ppa:danielrichter2007/grub-customizer

	# Add EverPad
	add-apt-repository -y ppa:nvbn-rm/ppa

	# Add Tweak & MyUnity Repos
	add-apt-repository -y ppa:tualatrix/ppa

	# Update
	apt-get ${aptopt} update
}
function setup_Package_Autoresponces(){
        desc Prep \for EULA and other apt-get prompts
	###################################################################################
	waitForNetwork || return 1
	# debconf-show --listdbs
	# debconf-show --listowners | sort
        echo hddtemp hddtemp/daemon select false | debconf-set-selections
	echo gdm gdm/daemon_name select /usr/sbin/gdm | debconf-set-selections
	echo gdm shared/default-x-display-manager select lightdm | debconf-set-selections
	echo lightdm shared/default-x-display-manager select lightdm | debconf-set-selections
        echo acroread-common acroread-common/default-viewer select true | debconf-set-selections
	echo oracle-java6-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
	echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
	echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
        echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
	# Output debconf settings to verify changes made above
	debconf-show --listowners |\
	egrep "(hddtemp|gdm|lightdm|acroread|oracle|ttf)" |\
	awk '{print "debconf-show "$0" | sed \"s/^/"$1"\t/\"  " }' |\
	bash
}

function setup_Package_Holds(){
	desc Apt package holds
        ###################################################################################
	echo linux-image-generic hold		| dpkg --set-selections
	echo grub-pc hold			| dpkg --set-selections
	echo grub-common hold			| dpkg --set-selections
	echo grub-gfxpayload-lists hold		| dpkg --set-selections
	echo grub-pc hold			| dpkg --set-selections
	echo grub-pc-bin hold			| dpkg --set-selections
	echo grub2-common hold			| dpkg --set-selections
	dpkg --get-selections | grep -v install
}
function setup_Package_Gnome_Defaults(){
	desc Terminal\; Run Command as Login Shell
	# gconftool-2

	# Set the Gnome Terminal to "Run Command as Login Shell"
	local opt='--direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory'
	gconftool-2 $opt -t bool -s /apps/gnome-terminal/profiles/Default/login_shell true

	# Change default terminal from Gnome Terminal to Terminator
	local opt='--direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory'
	gconftool-2 $opt -t string -s /desktop/gnome/applications/terminal/exec terminator

}
function setup_Install_Daemons(){
        desc openssh apache2 nfs tftp
	waitForNetwork || return 1
	waitAptgetInstall
        apt-get ${aptopt} install openssh-server
        apt-get ${aptopt} install apache2
        apt-get ${aptopt} install nfs-kernel-server
        apt-get ${aptopt} install tftpd-hpa tftp-hpa
	#apt-get ${aptopt} install 
}
function setup_Install_Daemon_VBox_Server(){
        desc VirtualBox Host Server
        ###################################################################################
	# get latest version info
        local latest=`wget -O - -o /dev/null http://download.virtualbox.org/virtualbox/LATEST.TXT`
	# setup extended pack download url
	local vbox_extpack="Oracle_VM_VirtualBox_Extension_Pack-${latest}.vbox-extpack"
	# retrived the package name and version
	local IFS=$'\n'
	local -a pkg_candidate=(`apt_search -v $latest -e $latest virtualbox-`)
	unset IFS
	# installed virtualbox if only one candidate was found
	if (( ${#pkg_candidate[@]} == 1 )); then
		waitAptgetInstall
		apt-get ${aptopt} install ${pkg_candidate[0]}
        	wget -r -O /tmp/$vbox_extpack -nv http://download.virtualbox.org/virtualbox/${latest}/$vbox_extpack
        	VBoxManage extpack install /tmp/$vbox_extpack
		rm -f /tmp/$vbox_extpack
	else
		echo "${pkg_candidate[*]}"
		return 1
	fi
}

function setup_Must_Have_Tools(){
	desc vim, ethtool, iotop, iftop, jre, chrome
        ###################################################################################
	waitForNetwork || return 1
	stall 3
	waitAptgetUpdate
	apt-get ${aptopt} update
	waitAptgetInstall
	apt-get ${aptopt} install	vim ethtool hwinfo iotop iftop git xclip \
					terminator multitail everpad \
					apt-file dlocate wajig aptitude\
					expect expect-dev \
					gconf-editor \
					ipcalc \
					cups-pdf \
					p7zip p7zip-full \
					google-chrome-stable
	# clean up
	waitAptgetUpdate
	apt-file ${aptopt} update
	waitAptgetInstall
	apt-get ${aptopt} -f install
	waitAptgetInstall
	apt-get ${aptopt} upgrade

	# skype	
	waitAptgetInstall
	apt-get ${aptopt} install	skype

	# setup defaults for the following applications
		read -d $'' apps << EOL
			google_chrome
			vim
			terminator
			top
EOL
	# locate and run installers
		for app in $apps; do
        		ls -1             "${scriptPath}"/defaults.${app}.sh 2> /dev/null
        		ls -1 "${scriptPath}"/../defaults/defaults.${app}.sh 2> /dev/null
		done | while read script; do
			"${script:-false}" -rr
		done

	# setup team viewer
	cd   /tmp
	wget http://download.teamviewer.com/download/teamviewer_linux_x64.deb
	dpkg -i teamviewer_linux_x64.deb
	rm   -f teamviewer_linux_x64.deb
	# clean up
	waitAptgetInstall
	apt-get ${aptopt} -f install
	waitAptgetInstall
	apt-get ${aptopt} upgrade
}
function setup_AMD_Catalyst(){
	desc Requires user interaction
	echo linux-image-generic hold | dpkg --set-selections
	apt-get ${aptopt} install linux-headers-`uname -r`
	cd /tmp
	wget http://www2.ati.com/drivers/beta/amd-driver-installer-catalyst-12.11-beta11-x86.x86_64.zip
	unzip amd-driver-*.zip
	chmod +x amd-driver-*.run
	./amd-driver-*.run
	# Remove watermark
	SIG="/etc/ati/signature"
	[ ! -f "${SIG}.bk" ] && cp -f "${SIG}" "${SIG}.bk"
cat << END-OF-FILE > "${SIG}"
9777c589791007f4aeef06c922ad54a2:ae59f5b9572136d99fdd36f0109d358fa643f2bd4a2644d9efbb4fe91a9f6590a145:f612f0b01f2565cd9bd834f8119b309bae11a1ed4a2661c49fdf3fad11986cc4f641f1ba1f2265909a8e34ff1699309bf211a7eb4d7662cd9f8e3faf14986d92f646f1bc
END-OF-FILE

}
function setup_UCK_Server(){
	desc Install UCK \+ Dependencies
        ###################################################################################
	waitAptgetUpdate
	apt-get ${aptopt} update
	waitAptgetInstall
	apt-get ${aptopt} install libfribidi-bin gfxboot-dev gfxboot-theme-ubuntu
	waitAptgetInstall
	apt-get ${aptopt} install unionfs-fuse=`apt_get_version uck-unstable unionfs-fuse`
	waitAptgetInstall
	apt-get ${aptopt} install uck=`apt_get_version uck-stable uck`
}
function setup_Add_Desktop_xfce(){
	desc "XFCE Shells"
        ###################################################################################
	waitForNetwork || return 1
	stall 3
	waitAptgetInstall
        apt-get ${aptopt} install xfce4 xfce4-goodies xfwm4 xfwm4-themes backstep
	# Defaults for XFCE
	"/etc/builder/`basename ${source}`-skel_xfce4.sh" -rr
}
function setup_Add_Desktop_gnome_shells(){
	desc "Gnome Shells"
        ###################################################################################
	waitForNetwork || return 1
        waitAptgetInstall
	apt-get ${aptopt} install expect
        waitAptgetInstall
	local packages=(gnome-panel
			gnome-shell
			gnome-shell-extensions
			gnome-session-fallback
			gnome-tweak-tool)
	/usr/bin/expect -f <(cat << END-OF-EXPECT
set timeout -1
spawn apt-get -y -q install ${packages[@]}
#spawn apt-get -y -q install ${package}
match_max 100000
expect -exact "Preconfiguring packages ...\r"
set timeout 3
expect "$"
send -- "\r"
set timeout -1
expect eof
END-OF-EXPECT
)
}
function setup_Unity_Classic_Menu(){
        desc "Setup classicmenu-indicator_0.07_all.deb"
        ###################################################################################
        apt-get ${aptopt} install python-gmenu
        mkdir /root/Downloads
        cd    /root/Downloads
        waitAptgetInstall
	apt-get ${aptopt} install python-appindicator	
        wget https://launchpad.net/~diesch/+archive/testing/+build/3076110/+files/classicmenu-indicator_0.07_all.deb
        waitAptgetInstall
        dpkg -i classicmenu-indicator_0.07_all.deb
        waitAptgetInstall
        cat << EOF > /etc/xdg/autostart/classicmenu-indicator.desktop
[Desktop Entry]
Name=ClassicMenu Indicator
Comment=Indicator applet to show the Gnome Classic main menu
GenericName=ClassicMenu Indicator
Categories=GNOME;Utility;
Exec=classicmenu-indicator
Icon=gnome-main-menu
Type=Application
EOF
}
function setup_Synergy(){
	desc Synergy Keybard and Mouse share
	local latest="http://synergy-foss.org/download/?list"
	local version=`wget -O - -o /dev/null "${latest}" | sed '/Latest/s/<[^>]*>//gp;d' | awk '{printf $3}'`
	local target="http://synergy.googlecode.com/files/synergy-${version}-Linux-x86_64.deb"
	local package="/tmp/$$_synergy-${version}-Linux-x86_64.deb"
	wget -O "${package}" "${target}"
	[ ! -f  "${package}" ] && return 1
	dpkg -i "${package}"
}
function setup_VBox_Additions(){
        desc Install Virtual Box Linux Additions
        ###################################################################################
	waitForNetwork || return 1
	stall 3
	# Prep for vbox extentions
	waitAptgetInstall
	local kernel_headers=$(apt-cache search "linux-headers-$(uname -r)" | awk '{print $1}')
	apt-get ${aptopt} install make gcc dkms $kernel_headers xserver-xorg xserver-xorg-core

	# prep working dirs
	mkdir        /root/vbox_guest_additions
        mkdir        /root/vbox_guest_additions/ISO
        cd           /root/vbox_guest_additions

	# Get version of latest release
        rm -f                   /root/vbox_guest_additions/LATEST.TXT
        wget -nv http://download.virtualbox.org/virtualbox/LATEST.TXT 
        cat                     /root/vbox_guest_additions/LATEST.TXT
        local      version=`cat /root/vbox_guest_additions/LATEST.TXT`

	# Get VBoxGuestAdditions ISO
	local iso="VBoxGuestAdditions_${version}.iso"
	[ ! -f "/tmp/vbox_guest_additions/${iso}" ] && \
        wget -nv http://download.virtualbox.org/virtualbox/${version}/${iso}
	
	# Add vbox user and group to specific uid and gid 
	local ID=$(free_ID_pair 100)
	useradd  -u $ID -g 1 -M -d /var/run/vboxadd -s /bin/false vboxadd
	groupadd -g $ID                                           vboxsf

	# Modify /etc/adduser.conf to include new group vboxsf
	add_default_group vboxsf

	# Mount VBoxGuestAdditions ISO
	umount                                        /root/vbox_guest_additions/ISO
	opt="-t iso9660 -o ro,loop"
        mount $opt  /root/vbox_guest_additions/${iso} /root/vbox_guest_additions/ISO

	# Install VBoxGuestAdditions 
	/root/vbox_guest_additions/ISO/VBoxLinuxAdditions.run

	# Unmount VBoxGuestAdditions ISO and clean up
	umount                                        /root/vbox_guest_additions/ISO
        unset version
        unset iso

	# Add vboxvideo 3D module
	echo vboxvideo >> /etc/modules

	# After Reboot test as follows
	echo
	echo After reboot test as follows :: /usr/lib/nux/unity_support_test -p
}
function setup_X2GO(){
	desc "X2GO Server+Client"
        ###################################################################################
	waitForNetwork || return 1
	stall 3
	if ! ls /etc/apt/sources.list.d/x2go-stabe* &> /dev/null; then
        	waitAptgetUpdate
        	/usr/bin/add-apt-repository -y ppa:x2go/stable
        	waitAptgetUpdate
        	apt-get ${aptopt} update
	fi
        waitAptgetInstall
        apt-get ${aptopt} install python-software-properties
        apt-cache search x2go
        #apt-get ${aptopt} install x2goserver x2goclient x2gognomebindings cups-x2go
        waitAptgetInstall
        apt-get ${aptopt} install x2goserver x2goclient cups-x2go
                #echo
                #waitAptgetUpdate
                #sudo /usr/bin/add-apt-repository ppa:freenx-team
                #waitAptgetInstall
                #apt-get ${aptopt} install qtnx
}
function setup_Live_Distro_Desktop_Session(){
	desc Set Desktop Session
	#set_lightdm    ubuntu	xfce4-session	# no-go
	#set_lightdm    ubuntu	xfce4		# no-go
	#set_lightdm    ubuntu	ubuntu 		# works
	#set_lightdm    ubuntu	gnome		# works but not installed yet
	set_lightdm    ubuntu	xfce		# works
	#set_lightdm    ubuntu	gnome-classic	# untested
	#set_lightdm    ubuntu	gnome-fallback	# works
}

###########################################################################################
###########################################################################################
# Configure services
###########################################################################################
###########################################################################################
function setup_Configure_SSH(){
	desc SSH: disable GSSAPIAuth \& disable UseDNS
        desc Install openssh-server \& Modify /etc/ssh/sshd_config
	# Disable GSSAPIAuthentication
        sed -i "s/.*GSSAPIAuthentication yes.*/#GSSAPIAuthentication yes/" /etc/ssh/sshd_config
	# Disable DNS verification
	sed -i "/^[^#]*UseDNS.*/s/^/#/; \$aUseDNS no" /etc/ssh/sshd_config

	# Restart service
	stop ssh
	sleep 1
	start ssh
}
function setup_Add_Service_nfs(){
        desc Install nfs-kernel-server \& Modify /etc/exports
	waitForNetwork || return 1
	waitAptgetInstall 
        apt-get ${aptopt} install nfs-kernel-server
	# Enable service to start at boot
	update-rc.d nfs-kernel-server defaults
	# Setup export directory
	mkdir     /export
	chmod 755 /export
	# Modify export config file
	sed -i '/^\/export[ \t]/d' /etc/exports
	echo "/export	0.0.0.0/0(ro,sync,no_subtree_check)" >> /etc/exports
	# Lock down RPC Mountd port so that firewall exception can be made
	sed -i '/^RPCMOUNTDOPTS=/cRPCMOUNTDOPTS="-p 13025"' /etc/default/nfs-kernel-server
	# Restart service
	stop  nfs-kernel-server
	sleep 1
	start nfs-kernel-server
}
function setup_Add_Service_tftp_PXE(){
	waitForNetwork || return 1
	desc Install tftp
	waitAptgetInstall 
        apt-get ${aptopt} install tftpd-hpa syslinux
	echo RUN_DAEMON=\"yes\" >> /etc/default/tftp-hpa
	cp /usr/lib/syslinux/{pxelinux.0,vesamenu.c32} /var/lib/tftpboot/.

	mkdir /var/lib/tftpboot/pxelinux.conf
	cat << END-OF-PXELINUXCONF > /var/lib/tftpboot/pxelinux.conf/default
DEFAULT vesamenu.c32

     TIMEOUT   100
MENU TIMEOUTROW 59
MENU TITLE Dreamwarp PXE TFTP Boot Server
menu background backgrounds/apple-sexy-lingerie-640x480.jpg
MENU TABMSG My Message Here
MENU TABMSGROW 20
#MENU WIDTH 77
MENU MARGIN 0
MENU VSHIFT 3
#MENU HSHIFT 0
MENU ROWS 17
MENU ENDROW 27

menu color title 1;36;44 #66A0FF #00000000 none
menu color hotsel 30;47 #C00000 #DDDDDDDD
menu color sel 30;47 #000000 #FFFFFFFF
menu color border 30;44 #D00000 #00000000 std
menu color scrollbar 30;44 #DDDDDDDD #00000000 none

END-OF-PXELINUXCONF
}

function setup_Add_Service_dhcpd(){
	desc Install dhcpd
	#waitAptgetInstall
	#apt-get ${aptopt} install isc-dhcp-server
	#update-rc.d isc-dhcp-server defaults
	local       WAN='eth0'
	local       LAN='eth1'
	local    LAN_IP='192.168.250.10'
	local     range='53'
	local      mask='24'

	# Extrapolate ipv4 info and dhcpd ranges from ip and mask
	local   netmask=`ipcalc -bn ${LAN_IP}/${mask} | grep Network:   | sed 's| ||g;s|=|:|' | cut -f2 -d:`
	local broadcast=`ipcalc -bn ${LAN_IP}/${mask} | grep Broadcast: | sed 's| ||g;s|/|:|' | cut -f2 -d:`
	local   network=`ipcalc -bn ${LAN_IP}/${mask} | grep Network:   | sed 's| ||g;s|/|:|' | cut -f2 -d:`
	local  rangSTOP=`ipcalc -bn ${LAN_IP}/${mask} | grep HostMax:   | sed 's| ||g;s|/|:|' | cut -f2 -d:`
	local rangSTART=${rangSTOP%.*}.$(( ${rangSTOP##*.} - ${range} ))

	# Collect sme details using the NetworkManager Command Line Interface
	local       mac=`get_nmcli_dev_detail ${LAN} GENERAL.HWADDR:`
	local        id=`get_nmcli_con_detail ${mac} connection.id:`
	local      uuid=`get_nmcli_con_detail ${mac} connection.uuid:`
	local      type=`get_nmcli_con_detail ${mac} connection.type:`
	local timestamp=`get_nmcli_con_detail ${mac} connection.timestamp:`
	local    domain=`get_nmcli_dev_detail ${WAN} .fqdn_domainname:`
	local  dns_svrs=`get_nmcli_dev_detail ${WAN} .domain_name_servers:`

	echo mac=$mac
	echo id=$id
	echo uuid=$uuid

	return 0

	# Test if NetworkManager.conf contains the option 'no-auto-default'
	# If it does, verify interface mac entry and add if nessisary
	local   nm_conf='/etc/NetworkManager/NetworkManager.conf'
	if   ! `egrep -i ^no-auto-default=                     "${nm_conf}" &> /dev/null`; then
		sed -i "/^\[main\]$/a\no-auto-default=${mac}," "${nm_conf}"
	elif ! `egrep -i ^no-auto-default=.*${mac},            "${nm_conf}" &> /dev/null`; then
		sed -i "/^no-auto-default=/s/$/${mac},/"       "${nm_conf}"
	fi

	# Create NetworkManager interface config file
	cat << END-OF-WIREDCONNECTION > "/etc/NetworkManager/system-connections/${id}"
[${type}]
duplex=full
mac-address=${mac}

[connection]
id=${id}
uuid=${uuid}
type=${type}
timestamp=${timestamp}

[ipv6]
method=auto

[ipv4]
method=manual
addresses1=${LAN_IP};${mask};0.0.0.0;
END-OF-WIREDCONNECTION
	
	# Modify the 'INTERFACES' option in /etc/default/isc-dhcp-server config file
	sed "/^INTERFACES=/cINTERFACES=\"${LAN}\"" /etc/default/isc-dhcp-server

	# Backup the isc-dhcp-server config; /etc/dhcp/dhcpd.conf
	mv -v /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bk-`date '+%s'`

	# Setup isc-dhcp-server config; /etc/dhcp/dhcpd.conf
	cat << END-OF-DHCPDCONF > /etc/dhcp/dhcpd.conf
option domain-name "${domain}";
option domain-name-servers ${dns_svrs// /, };
default-lease-time 600;
max-lease-time 7200;
authoritative;
log-facility local7;
subnet ${network} netmask ${netmask} {
	range ${rangSTART} ${rangSTOP};
	option subnet-mask ${netmask};
	option broadcast-address ${broadcast};
	option routers ${LAN_IP};

	### PXE Server IP ###
	next-server ${LAN_IP};
	filename "pxelinux.0";
}
END-OF-DHCPDCONF

	# Restart the NetworkManager
	/etc/init.d/network-manager stop
	sleep 3
	/etc/init.d/network-manager start
	
}
function setup_Add_Service_iptables(){
	desc Install iptables \+ MASQUERADE
	# https://help.ubuntu.com/community/UFW
	# cat /etc/services for service names
	ufw --force reset
	sed -i '/^DEFAULT_FORWARD_POLICY=/cDEFAULT_FORWARD_POLICY="ACCEPT"' \
		/etc/default/ufw
	sed -i '/net\/ipv4\/ip_forward=/cnet/ipv4/ip_forward=1' \
		/etc/ufw/sysctl.conf
	sed -i '/net\/ipv6\/conf\/default\/forwarding=/cnet/ipv6/conf/default/forwarding=1' \
		/etc/ufw/sysctl.conf
	local cript=`cat << END-OF-SED
		0,/^\*filter/ {
			0,/^$/ {
				/^$/ {
					i
					i# nat Table rules
					i*nat
					i:POSTROUTING ACCEPT [0:0]
					i
					i# FORWARD traffic through eth0
					i#-A POSTROUTING ! -d 192.168.192.0/24 -j MASQUERADE
					i-A POSTROUTING -s 192.168.250.0/24 -o eth0 -j MASQUERADE
					i
					i# don't delete the 'COMMIT' line or these nat Table rules won't be processed
					iCOMMIT
				}
			}
		}
END-OF-SED
`
	sed -i "$cript" /etc/ufw/before.rules
	ufw enable
	ufw status verbose
	ufw allow ssh
	ufw allow http
	ufw allow https
	ufw allow in on eth1 from any port 68 to any port 67 proto udp
	ufw allow in on eth1 from any to any port 69 proto udp
	ufw allow in on eth1 from any to any port 2049
	ufw allow in on eth1 from any to any port 111
	ufw allow in on eth1 from any to any port 13025
	ufw allow in on eth1 from any to any port 1039
	ufw allow in on eth1 from any to any port 1047
	ufw allow in on eth1 from any to any port 1048
	ufw allow in on eth1 from any to any port 514
	ufw --force reload
}
function setup_Multimedia(){
	desc DVD support
        ###################################################################################
	waitForNetwork || return 1
	waitAptgetInstall
        apt-get ${aptopt} install libdvdread4
        /usr/share/doc/libdvdread4/install-css.sh
        waitAptgetInstall
        apt-get ${aptopt} install ubuntu-restricted-extras
}
function setup_grub_customizer(){
        desc Command line app \# \> grub-customizer
        ###################################################################################
	waitForNetwork || return 1
	if ! ls /etc/apt/sources.list.d/danielrichter* &> /dev/null; then
		waitAptgetUpdate
        	/usr/bin/add-apt-repository -y ppa:danielrichter2007/grub-customizer
	        waitAptgetUpdate
        	apt-get update
	fi
        waitAptgetInstall
        apt-get ${aptopt} install grub-customizer
}

function setup_ubuntu_tweak_n_myunity(){
        desc Ubuntu Tweak and MyUnity
        ###################################################################################
	waitForNetwork || return 1
	if ! ls /etc/apt/sources.list.d/tualatrix* &> /dev/null; then
        	waitAptgetUpdate
	        /usr/bin/add-apt-repository -y ppa:tualatrix/ppa
	        waitAptgetUpdate
        	apt-get update
	fi
        waitAptgetInstall
        apt-get ${aptopt} install ubuntu-tweak myunity
}
function setup_unity_monitors(){
        desc Setup indicator-multiload indicator-sysmonitor
        ###################################################################################
	waitForNetwork || return 1
	if ! ls /etc/apt/sources.list.d/indicator-multiload* &> /dev/null; then
        	waitAptgetUpdate
        	add-apt-repository -y ppa:indicator-multiload/stable-daily
		local update=true
	fi
	if ! ls /etc/apt/sources.list.d/alexeftimie* &> /dev/null; then
		waitAptgetUpdate
	        add-apt-repository -y ppa:alexeftimie/ppa
		local update=true
	fi
	# Run apt-get update if new repo were added
	if ${update:- false}; then
	        waitAptgetUpdate
        	apt-get -y update
	fi
        waitAptgetInstall
        apt-get ${aptopt} install indicator-multiload indicator-sysmonitor
}
function setup_Crossover(){
        desc Codeweavers Crossover \for Office
        ###################################################################################
	waitForNetwork || return 1
	# dependencies
        waitAptgetInstall
	apt-get ${aptopt} install gdebi libc6-i386 ia32-libs ia32-libs-multiarch \
				 lib32gcc1 lib32nss-mdns lib32nss-mdns lib32z1 \
				 python-glade2 lib32asound2
	# setup working dir
	mkdir /root/codeweavers_crossover
	cd    /root/codeweavers_crossover
	rm -f /root/codeweavers_crossover/*.deb
	
	# base url were codeweavers serves it's applications
	local base_url='http://media.codeweavers.com/pub/crossover/cxlinux/demo/'
	# download deb list
	local opt="--spider -r -nd -l 1 --cut-dirs 1 -A deb"
        wget ${opt} ${base_url} 2>&1 | tee wget.log
	# sort through architechturally appropriate packages
	case $(uname -m) in
                x86_64)         local filter='amd64';;
                i386|i586|i686) local filter='i386';;
        esac
	# get newest version and link
	local version=$(egrep "Removing.*crossover_[0-9.-]*_${filter}" wget.log | sort | awk 'END{print $2}')
	local url=$(egrep "http.*${version%?}" wget.log | awk '{print $3}')
	echo ${version%?}
	# download crossover
	wget --progress=bar:force ${url}
	# install
	dpkg -i ${version%?}
}
function setup_adobe(){
        desc Adobe, Java and Flash
        ###################################################################################
	waitForNetwork || return 1
	# Auto-responce
        echo acroread-common acroread-common/default-viewer select true | debconf-set-selections
	echo oracle-java6-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
	echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
	echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
	# Add Adobe Repo
	if ! ls /etc/apt/sources.list.d/canonical* &> /dev/null; then
		sed -i.save 's/^/#/' "/etc/apt/sources.list.d/canonical_Adobe.list"
		for repo in								\
		"deb http://archive.canonical.com/ubuntu precise partner"		\
		"deb-src http://archive.canonical.com/ubuntu precise partner"		\
		"deb http://archive.canonical.com/ubuntu `lsb_release -sc` partner"	\
		"deb-src http://archive.canonical.com/ubuntu `lsb_release -sc` partner"
		do echo ${repo} >> "/etc/apt/sources.list.d/canonical_Adobe.list"; done
		local update=true
	fi
	# Add Oracle Java repo
	if ! ls /etc/apt/sources.list.d/webupd8team-java* &> /dev/null; then
		add-apt-repository -y ppa:webupd8team/java
		local update=true
	fi
	# Add Medibuntu repo for free and non-free packages like acroread
	if ! ls /etc/apt/sources.list.d/medibuntu* &> /dev/null; then
		wget -O "/etc/apt/sources.list.d/medibuntu.list" "http://www.medibuntu.org/sources.list.d/`lsb_release -cs`.list"
        	waitAptgetUpdate
		apt-get --quiet update
		apt-get --yes --quiet --allow-unauthenticated install medibuntu-keyring
		local update=true
	fi
	# Run apt-get update if new repo were added
	if ${update:- false}; then
	        waitAptgetUpdate
        	apt-get -y update
	fi
        waitAptgetInstall
	# Install Acrobat Reader
        waitAptgetInstall
        apt-get ${aptopt} install acroread flashplugin-installer
	# Install Flash
        waitAptgetInstall
        apt-get ${aptopt} install flashplugin-downloader flashplugin-nonfree-extrasound
	# Install Firefox Acrobat Plugin
        waitAptgetInstall
        apt-get ${aptopt} install adobe-flashplugin
	# Modify of apt-cacher client setting required for Oracle Java Install
	local oracleProxy='Acquire::http::Proxy::download.oracle.com "DIRECT";'
	egrep -l -R "^Acquire::http::Proxy " /etc/apt |\
	xargs -i@ sed -i.bk`date "+%s"` "/^Acquire::http::Proxy /a${oracleProxy}" @
	# Oracle Java Development Kit JDK X
        waitAptgetInstall
        apt-get ${aptopt} install oracle-java6-installer
        #waitAptgetInstall
        #apt-get ${aptopt} install oracle-java7-installer
        #waitAptgetInstall
        #apt-get ${aptopt} install oracle-java8-installer
}
function setup_Clean_Update_Upgrade(){
	desc Apt clean, update \& upgrade
        ###################################################################################
	waitForNetwork || return 1
	echo up
	#apt_clean_update_upgrade
}

#function waitForNetwork(){
#	mesg Network up
#}
