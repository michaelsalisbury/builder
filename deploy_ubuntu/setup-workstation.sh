#!/bin/builder.sh
skip=( false false false false false false false false false false false false false false false false false false false false false false false false false false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/system-setup/$scriptName

subScriptBase="/root/system-setup/`basename ${source}`"


# Get Ubuntu version info and ... 
#	DISTRIB_ID=Ubuntu
#	DISTRIB_RELEASE=11.10
#	DISTRIB_CODENAME=oneiric
#	DISTRIB_DESCRIPTION="Ubuntu 11.10"
while read import; do
	${import:+.} "${import:-false}"
done << IMPORTS
	/etc/lsb-release
	`ls -1              "${scriptPath}"/functions*.sh 2> /dev/null`
	`ls -1 "${scriptPath}"/../functions/functions*.sh 2> /dev/null`
IMPORTS
	#`ls -1    functions/functions*.sh 2> /dev/null`

aptopt="-y -q"
#autoLoginShell="ubuntu"
#autoLoginShell="gnome-session-fallback"
autoLoginShell="xfce4-session"

###########################################################################################
###########################################################################################
function setup_Prep_Add_sudo(){
	desc Prep: Enable sudo wihout password \(2 prompts\)
	local username=`who -u | grep '\.' | awk '{print $1}'`
	echo $username
	if [ "`whoami`" == "root" ]; then
		sed -i "/^${username}/d" /etc/sudoers
		echo -e "\n${username} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
	else
		sudo sed -i "/^${username}/d" /etc/sudoers
		echo -e "\n${username} ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
	fi
}
function setup_Prep_Add_SSH_Keys(){
	desc Add SSH Keys to root \& all user with uid \>= 1000
	set_ssh_authorized_keys	all
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
        waitForNetwork && networkUpMsg || return 1

	# Add Oracle VirtualBox Repo
	echo "deb http://download.virtualbox.org/virtualbox/debian $DISTRIB_CODENAME contrib" > \
	"/etc/apt/sources.list.d/oracle-virtualbox.list"
	wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | apt-key add -

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

	# Add EverPad
	add-apt-repository -y ppa:nvbn-rm/ppa

	# Update
	apt-get ${aptopt} update
}
function setup_Package_Autoresponces(){
        desc Prep \for EULA and other apt-get prompts
	###################################################################################
	waitForNetwork && networkUpMsg || return 1
	# debconf-show --listdbs
	# debconf-show --listowners | sort
        echo hddtemp hddtemp/daemon select false | debconf-set-selections
	echo gdm gdm/daemon_name select /usr/sbin/gdm | debconf-set-selections
	echo gdm shared/default-x-display-manager select lightdm | debconf-set-selections
	echo lightdm shared/default-x-display-manager select lightdm | debconf-set-selections
        echo acroread-common acroread-common/default-viewer select true | debconf-set-selections
        echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
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
        desc openssh-server apache2 nfs-kernel-server tftpd-hpa
	waitForNetwork && networkUpMsg || return 1
	waitAptgetInstall
        apt-get ${aptopt} install openssh-server
        apt-get ${aptopt} install apache2
        apt-get ${aptopt} install nfs-kernel-server
        apt-get ${aptopt} install tftpd-hpa tftp-hpa
	#apt-get ${aptopt} install 
}
function setup_Install_Daemon_VBox_Server(){
        desc Install VirtualBox Host
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
	desc Install Tools\; vim, ethtool, iotop, iftop, jre, chrome, filezilla 
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
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
					#default-jre default-jre-headless \
	# Defaults for vim
	"${subScriptBase}-defaults_vim.sh" -rr	

	# Defaults for Terminator
	"${subScriptBase}-defaults_terminator.sh" -rr

	# Defaults for Chrome
	"${subScriptBase}-defaults_google_chrome.sh" -rr

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
	waitForNetwork && networkUpMsg || return 1
	stall 3
	waitAptgetInstall
        apt-get ${aptopt} install xfce4 xfce4-goodies xfwm4 xfwm4-themes backstep
	# Defaults for XFCE
	"/etc/builder/`basename ${source}`-skel_xfce4.sh" -rr
}
function setup_Add_Desktop_gnome_shells(){
	desc "Gnome Shells"
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
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
	waitForNetwork && networkUpMsg || return 1
	stall 3
	# Prep for vbox extentions
	waitAptgetUpdate
	apt-get ${aptopt} update
	waitAptgetInstall
	apt-get ${aptopt} install linux-headers-`uname -r` build-essential dkms xserver-xorg xserver-xorg-core
	stall 3
        ###################################################################################
	# prep working dirs
        mkdir  /tmp/vbox_guest_additions
        mkdir  /tmp/vbox_guest_additions_ISO
        cd     /tmp/vbox_guest_additions

	# Get version of latest release
        rm -f  /tmp/vbox_guest_additions/LATEST.TXT
        wget -nv http://download.virtualbox.org/virtualbox/LATEST.TXT
        cat    /tmp/vbox_guest_additions/LATEST.TXT
        local version=`cat /tmp/vbox_guest_additions/LATEST.TXT`

	# Get VBoxGuestAdditions ISO
	local iso="VBoxGuestAdditions_${version}.iso"
        rm -f  /tmp/vbox_guest_additions/${iso}
        wget -nv http://download.virtualbox.org/virtualbox/${version}/${iso}
	
	# Mount VBoxGuestAdditions ISO
        umount                             /tmp/vbox_guest_additions_ISO
        mount -t iso9660 -o loop,ro ${iso} /tmp/vbox_guest_additions_ISO

	# Add vbox user and group to specific uid and gid 
	useradd  -u 130 -g 1 -M -d /var/run/vboxadd -s /bin/false vboxadd
	groupadd -g 130                                           vboxsf

	# Install VBoxGuestAdditions 
        cd /tmp/vbox_guest_additions_ISO
        ./VBoxLinuxAdditions.run

	# Unmount VBoxGuestAdditions ISO and clean up
        cd ~
        umount /tmp/vbox_guest_additions_ISO
	rm -rf /tmp/vbox_guest_additions*

	# Add vboxvideo 3D module
	echo vboxvideo >> /etc/modules

	# After Reboot test as follows
	echo
	echo After reboot test as follows :: /usr/lib/nux/unity_support_test -p
}
function setup_X2GO(){
	desc "X2GO Server+Client"
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	stall 3
        waitAptgetUpdate
        /usr/bin/add-apt-repository -y ppa:x2go/stable
        waitAptgetUpdate
        apt-get ${aptopt} update
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
	sed -i "/^[^#]*UseDNS.*/s/^/#/; $a\\tUseDNS no" /etc/ssh/sshd_config

	# Restart service
	stop ssh
	sleep 1
	start ssh
}
function setup_Add_Service_nfs(){
        desc Install nfs-kernel-server \& Modify /etc/exports
	waitForNetwork && networkUpMsg || return 1
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
	waitForNetwork && networkUpMsg || return 1
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

function setup_Clean_Update_Upgrade(){
	desc Apt clean, update \& upgrade
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	apt_clean_n_update
	apt_update_n_upgrade
}

function waitForNetwork(){
	mesg Network up
}
