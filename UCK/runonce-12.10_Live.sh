#!/bin/builder.sh
skip=( true false false false false false false true true false false false true false true false true true true true true true true true true true true false false true true true false true true true false false false false false false false )
step=1
prefix="setup"
source=http://192.168.248.24/config/$scriptName


aptopt="-y -q"
autoLoginUser="ubuntu"
#autoLoginShell="ubuntu"
#autoLoginShell="gnome-session-fallback"
autoLoginShell="xfce4-session"
###########################################################################################
###########################################################################################

###########################################################################################
###########################################################################################
function setup_Live_Distro_Prep(){
        waitForNetwork && networkUpMsg || return 1
        desc Prep: Add repos \& root ssh keys,password
	# repo keys
	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
	wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | apt-key add -
	# repoa
        cat << END-OF-REPOS > /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ quantal main restricted
deb http://security.ubuntu.com/ubuntu/ quantal-security main restricted
deb http://archive.ubuntu.com/ubuntu/ quantal-updates main restricted
deb http://us.archive.ubuntu.com/ubuntu/ quantal universe
deb-src http://us.archive.ubuntu.com/ubuntu/ quantal universe
deb http://us.archive.ubuntu.com/ubuntu/ quantal-updates universe
deb-src http://us.archive.ubuntu.com/ubuntu/ quantal-updates universe
deb http://dl.google.com/linux/chrome/deb/ stable main
deb http://download.virtualbox.org/virtualbox/debian quantal contrib
END-OF-REPOS
	#
	apt_clean_n_update
	# Set Root Password
	set_user_passwd         root 1qaz@WSX
	set_ssh_authorized_keys root
}
function setup_Live_Distro_Remove_Packages(){
	desc Strip: Remove ubiquity
	# Disable Welcome Screen and remove the installer
	#apt-get ${aptopt} remove ubiquity
	apt-get ${aptopt} remove firefox
}
function setup_Live_Distro_Modify_Casper(){
	desc "Add noeject option"
	local file='/etc/init.d/casper'
	local cript=`cat << END-OF-SED
		/^[ \t]*eject/ {
			i\    # Skip eject if 'noeject' was enabled at boot
			i\    if grep -qs noeject /proc/cmdline; then
			i\    	return 0
			i\    fi
			i
		}
END-OF-SED
`
	sed -i "$cript" "$file"
}
function setup_Add_Service_ssh(){
	waitForNetwork && networkUpMsg || return 1
        desc Install openssh-server \& Modify /etc/ssh/sshd_config
	waitAptgetInstall
        apt-get ${aptopt} install openssh-server
        sed -i "s/.*GSSAPIAuthentication yes.*/#GSSAPIAuthentication yes/" /etc/ssh/sshd_config
}
function setup_Add_Service_nfs(){
	waitForNetwork && networkUpMsg || return 1
        desc Install nfs-kernel-server \& Modify /etc/exports
	waitAptgetInstall 
        apt-get ${aptopt} install nfs-kernel-server
	update-rc.d nfs-kernel-server defaults
	mkdir     /export
	chmod 777 /export
	cat << END-OF-EXPORTS >> /etc/exports
/export	0.0.0.0/0(ro,sync,no_subtree_check
END-OF-EXPORTS
	sed -i '/^RPCMOUNTDOPTS=/cRPCMOUNTDOPTS="-p 13025"' /etc/default/nfs-kernel-server
	stop  nfs-kernel-server
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
function get_nmcli_con_detail(){
	local mac=$1
	local detail=$2
	nmcli -t --fields NAME con list				|\
		xargs -i@ nmcli -t --fields all con list id @   |\
		egrep "(${detail}|\.mac-address:)"		|\
		sed 'N;s/\n/|/'					|\
		grep -i ${mac}					|\
		tr '|' '\n'					|\
		grep -i -v ${mac}				|\
		cut -f2 -d:
}
function get_nmcli_dev_detail(){
	local interface=$1
	local detail=$2
	nmcli -t --fields all dev list iface ${interface}	|\
		sed '/^DHCP4.OPTION/ { s/:/./; s/ = /:/; }'	|\
		egrep "${detail}"				|\
		cut -f2- -d:
}
function setup_Add_Service_dhcpd(){
	desc Install dhcpd
	waitAptgetInstall
	apt-get ${aptopt} install isc-dhcp-server
	update-rc.d isc-dhcp-server defaults
	local       WAN='eth0'
	local       LAN='eth1'
	local        ip='192.168.250.10'
	local       ips='53'
	local      mask='24'

	# Extrapolate ipv4 info and dhcpd ranges from ip and mask
	local   netmask=`ipcalc -bn ${ip}/${mask} | grep Network:   | sed 's| ||g;s|=|:|' | cut -f2 -d:`
	local broadcast=`ipcalc -bn ${ip}/${mask} | grep Broadcast: | sed 's| ||g;s|/|:|' | cut -f2 -d:`
	local   network=`ipcalc -bn ${ip}/${mask} | grep Network:   | sed 's| ||g;s|/|:|' | cut -f2 -d:`
	local  rangSTOP=`ipcalc -bn ${ip}/${mask} | grep HostMax:   | sed 's| ||g;s|/|:|' | cut -f2 -d:`
	local rangSTART=${rangSTOP%.*}.$(( ${rangSTOP##*.} - ${ips} ))

	# Collect sme details using the NetworkManager Command Line Interface
	local       mac=`get_nmcli_dev_detail ${LAN} GENERAL.HWADDR:`
	local        id=`get_nmcli_con_detail ${mac} connection.id:`
	local      uuid=`get_nmcli_con_detail ${mac} connection.uuid:`
	local      type=`get_nmcli_con_detail ${mac} connection.type:`
	local timestamp=`get_nmcli_con_detail ${mac} connection.timestamp:`
	local    domain=`get_nmcli_dev_detail ${WAN} .fqdn_domainname:`
	local  dns_svrs=`get_nmcli_dev_detail ${WAN} .domain_name_servers:`

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
addresses1=${ip};${mask};0.0.0.0;
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
	option routers ${ip};

	### PXE Server IP ###
	next-server ${ip};
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

function setup_Aliases(){
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
	echo linux-image-3.5.0-17-generic hold	| dpkg --set-selections
	echo grub-pc hold			| dpkg --set-selections
	echo grub-common hold			| dpkg --set-selections
	echo grub-gfxpayload-lists hold		| dpkg --set-selections
	echo grub-pc hold			| dpkg --set-selections
	echo grub-pc-bin hold			| dpkg --set-selections
	echo grub2-common hold			| dpkg --set-selections
	dpkg --get-selections | grep -v install
}
function setup_Clean_Update_Upgrade(){
	desc Apt clean, update \& upgrade
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	apt_clean_n_update
	apt_update_n_upgrade
}
function setup_UCK_Server(){
	desc Install UCK \+ Dependencies
        ###################################################################################
	add-apt-repository -y ppa:uck-team/uck-stable
	sed -i "/etc/apt/sources.list.d/uck-team-uck-stable-quantal.list" -f <(cat << END-OF-SED
        /^deb/{
                h
                s/^/#/
                x
                s/quantal/precise/
                G
        }
END-OF-SED
)
	add-apt-repository -y ppa:uck-team/uck-unstable
	sed -i "/etc/apt/sources.list.d/uck-team-uck-unstable-quantal.list" -f <(cat << END-OF-SED
        /^deb/{
                h
                s/^/#/
                x
                s/quantal/oneiric/
                G
        }
END-OF-SED
)
	waitAptgetUpdate
	apt-get ${aptopt} update
	waitAptgetInstall
	apt-get ${aptopt} install libfribidi-bin gfxboot-dev gfxboot-theme-ubuntu
	waitAptgetInstall
	apt-get ${aptopt} install unionfs-fuse=`apt_get_version uck-unstable unionfs-fuse`
	waitAptgetInstall
	apt-get ${aptopt} install uck=`apt_get_version uck-stable uck`
}


function setup_VBox_Server(){
	desc Install VirtualBox Host 
	###################################################################################
        mkdir  /root/Downloads
        cd     /root/Downloads
        rm -f  /root/Downloads/LATEST.TXT
        wget -nv http://download.virtualbox.org/virtualbox/LATEST.TXT
        cat   /root/Downloads/LATEST.TXT
        local version=`cat /root/Downloads/LATEST.TXT`
	apt-get ${aptopt} install virtualbox-${version}
	wget -nv http://download.virtualbox.org/virtualbox/${version}/Oracle_VM_VirtualBox_Extension_Pack-${version}.vbox-extpack
	VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-${version}.vbox-extpack
}
function setup_Must_Have_Tools(){
	desc Install Tools\; vim, ethtool, iotop, iftop, jre, chrome, filezilla 
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	stall 3
	waitAptgetUpdate
	apt-get ${aptopt} update
	waitAptgetInstall
	apt-get ${aptopt} install	vim ethtool hwinfo iotop iftop \
					terminator multitail \
					expect expect-dev \
					gconf-editor \
					ipcalc
					#default-jre default-jre-headless \

	"/etc/builder/`basename ${source}`-skel_terminator.sh" -rr
	waitAptgetInstall
	apt-get ${aptopt} install google-chrome-stable
	sed -i '/google.com/d' /etc/apt/sources.list
	"/etc/builder/`basename ${source}`-skel_google_chrome.sh" -rr
}

function setup_from_repo_programs(){
	desc "Programs"
        ###################################################################################
        waitAptgetInstall
        apt-get ${aptopt} install okular gimp gimp-data-extras gimp-gutenprint  \
                           gimp-gmic gimp-plugin-registry gnome-rdp \
                           remmina remmina-plugin-gnome remmina-plugin-nx \
                           remmina-plugin-rdp remmina-plugin-vnc
}
function setup_from_repo_Email(){
	desc "E-mail"
        ###################################################################################
        waitAptgetInstall
        apt-get ${aptopt} install thunderbird enigmail thunderbird-gnome-support \
                           xul-ext-calendar-timezones xul-ext-gdata-provider \
                           xul-ext-lightning
}
function setup_from_repo_editors(){
	desc "Editors"
        ###################################################################################
        waitAptgetInstall
        apt-get ${aptopt} install kile kile-doc gv wv texlive-extra-utils \
                           lyx lyx-common menu dvipost latex2html latex2rtf \
                           tex4ht tth writer2latex hevea libtiff-tools vim \
                           chktex texlive doxygen texlive-base-bin emacs
}
function setup_from_repo_programmimg(){
        desc "Programming"
        ###################################################################################
        waitAptgetInstall
        apt-get ${aptopt} install build-essential default-jre
        waitAptgetInstall
        apt-get ${aptopt} install build-essential mpich2 gfortran cfortran default-jre \
                           default-jre-headless gromacs tkgate xfig xfig-doc
}
function setup_from_repo_visualization(){
	desc "visualization"
        ###################################################################################
        waitAptgetInstall
        apt-get ${aptopt} install grace
}
function setup_from_repo_chat(){
	desc "Chat"
        ###################################################################################
        waitAptgetInstall
        apt-get ${aptopt} install pidgin pidgin-plugin-pack pidgin-sipe pidgin-themes \
                           pidgin-twitter pidgin-facebookchat pidgin-encryption \
                           pidgin-librvp pidgin-extprefs
}
function setup_from_repo_wine(){
	desc "WINE"
        ###################################################################################
        waitAptgetInstall
        echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
        apt-get ${aptopt} install wine1.4 wine1.4-amd64 winetricks q4wine gnome-exe-thumbnailer \
                           ttf-liberation ttf-mscorefonts-installer playonlinux
}
function setup_from_repo_media(){
	desc "Media"
        ###################################################################################
	waitAptgetInstall
        apt-get ${aptopt} install libdvdread4
        /usr/share/doc/libdvdread4/install-css.sh
        waitAptgetInstall
        apt-get ${aptopt} install ubuntu-restricted-extras
}
function setup_from_repo_backups(){
	desc "Backups"
        ###################################################################################
	waitAptgetInstall
        apt-get ${aptopt} install luckybackup luckybackup-data backintime-gnome
}
function setup_Add_Desktop_xubuntu(){
	desc "xubuntu"
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
        waitAptgetUpdate
        apt-get ${aptopt} update
        #waitAptgetInstall
        #apt-get ${aptopt} install dictionaries-common wamerican-insane
        waitAptgetInstall
        apt-get ${aptopt} install xubuntu-desktop
}
function setup_Add_Desktop_kubuntu(){
	desc "kubuntu"
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
        waitAptgetUpdate
        apt-get ${aptopt} update
        #waitAptgetInstall
        #apt-get ${aptopt} install dictionaries-common wamerican-insane
        waitAptgetInstall
        apt-get ${aptopt} install kubuntu-desktop
}
function setup_Add_Desktop_xfce(){
	desc "XFCE Shells"
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	stall 3
	waitAptgetInstall
        apt-get ${aptopt} install xfce4 xfce4-goodies xfwm4 xfwm4-themes backstep
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
function setup_Adobe(){
        desc Adobe, Java and Flash
        ###################################################################################
        echo acroread-common acroread-common/default-viewer select true | debconf-set-selections
        apt-get update
        /usr/bin/add-apt-repository -y "deb http://archive.canonical.com/ `lsb_release -sc` partner"
        waitAptgetUpdate
        sudo apt-get update
        waitAptgetInstall
        apt-get ${aptopt} install acroread
        waitAptgetInstall
        apt-get ${aptopt} install flashplugin-installer
        waitAptgetInstall
        apt-get ${aptopt} install flashplugin-downloader
        waitAptgetInstall
        apt-get ${aptopt} install flashplugin-nonfree-extrasound
        waitAptgetInstall
        apt-get ${aptopt} install adobe-flashplugin
        /usr/bin/add-apt-repository -y ppa:ferramroberto/java
        apt-get update
        apt-get ${aptopt} install sun-java6-jdk sun-java6-plugin
        waitAptgetInstall
        apt-get ${aptopt} install openjdk-6-jre
        waitAptgetInstall
	apt-get ${aptopt} install openjdk-7-jre
}
function setup_System_Resource_Monitors(){
	desc "Setup indicator-multiload indicator-sysmonitor"
        ###################################################################################
        waitAptgetUpdate
        /usr/bin/add-apt-repository -y ppa:indicator-multiload/stable-daily
        waitAptgetUpdate
        /usr/bin/add-apt-repository -y ppa:alexeftimie/ppa
        waitAptgetUpdate
        apt-get -y update
        waitAptgetInstall
        apt-get ${aptopt} install indicator-multiload indicator-sysmonitor
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
function setup_VBox_Additions(){
        desc Install Virtual Box Linux Additions
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	stall 3
	waitAptgetUpdate
	apt-get ${aptopt} update
	waitAptgetInstall
	apt-get ${aptopt} install linux-headers-`uname -r` build-essential dkms xserver-xorg xserver-xorg-core
        ###################################################################################
	stall 3
        mkdir  /root/Downloads
        mkdir  /root/Downloads/vbox_guest_additions
        cd     /root/Downloads
        rm -f  /root/Downloads/LATEST.TXT
        wget -nv http://download.virtualbox.org/virtualbox/LATEST.TXT
        cat   /root/Downloads/LATEST.TXT
        local version=`cat /root/Downloads/LATEST.TXT`
        rm -f  /root/Downloads/VBoxGuestAdditions_${version}.iso
        wget -nv http://download.virtualbox.org/virtualbox/${version}/VBoxGuestAdditions_${version}.iso
        umount                                                        /root/Downloads/vbox_guest_additions
        mount -t iso9660 -o loop,ro VBoxGuestAdditions_${version}.iso /root/Downloads/vbox_guest_additions
        cd     /root/Downloads/vbox_guest_additions
	useradd  -u 130 -g 1 -M -d /var/run/vboxadd -s /bin/false vboxadd
	groupadd -g 130                                           vboxsf
        ./VBoxLinuxAdditions.run
        cd     /root/Downloads
        umount                                                        /root/Downloads/vbox_guest_additions
	rm -f  /root/Downloads/VBoxGuestAdditions_${version}.iso
	rm -rf /root/Downloads/vbox_guest_additions
}
function setup_VBox_Additions_aptget(){
	desc Install Virtual Box Linux Additions via apt-get
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	stall 3
	waitAptgetUpdate
	apt-get ${aptopt} update
	waitAptgetInstall
	apt-get ${aptopt} install linux-headers-`uname -r` build-essential dkms xserver-xorg xserver-xorg-core
	waitAptgetInstall
	apt-get ${aptopt} install virtualbox-guest-dkms      \
				  virtualbox-guest-utils     \
				  virtualbox-guest-x11
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
function setup_Live_Distro_Users(){
	desc Add custom user account \& Setup /etc/lightdm/lightdm.conf
	# autoLoginUser
	add_admin_user ${autoLoginUser}
	add_admin_user msalisbury	1qaz@WSX
	add_basic_user mdebach		1qaz@WSX
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
# Support Functions Below
###########################################################################################
###########################################################################################


function networkUpMsg(){ echo Network Up, Internet Accessible + DNS Responding.; }

function apt_get_repos(){
        local repo='-'
        local pkg=$1
        (
        echo Name Version Repo
        for ver in `apt-cache show $pkg | egrep ^Version | cut -f2- -d:`
                do
                        repo=`apt-cache showpkg $pkg | sed "s|^$ver (/var/lib/apt/lists/\([^()]*\)).*|\1|p;d"`
                        echo $pkg $ver $repo
                done
        ) | column -t
}
function apt_get_version(){
        local repo=$1
        local pkg=$2
        for ver in `apt-cache show $pkg | egrep ^Version | cut -f2- -d:`
                do
                apt-cache showpkg $pkg | grep $ver | grep $repo &> /dev/null && echo $ver
                done | sort -u
}

function apt_clean_n_update(){
	desc Apt clean \& update
        ###################################################################################
	apt-get clean
	waitAptgetUpdate
	apt-get ${aptopt} update
}
function apt_update_n_upgrade(){
	desc Apt update \& upgrade
        ###################################################################################
	waitAptgetUpdate
	apt-get ${aptopt} update
	waitAptgetInstall
	apt-get ${aptopt} upgrade
}
function set_user_passwd(){
	local username=$1
	local password=$2
	perl -e 'system("usermod -p ".crypt($ARGV[1], rand)." $ARGV[0]")' $username $password
}
function set_lightdm(){
	local autoLoginUsr=$1
	local defaultShell=$2
	local etDMDefaults='/usr/lib/lightdm/lightdm-set-defaults'
	# valid session names /usr/share/xsessions
	#$etDMDefaults --autologin		$autoLoginUsr
	$etDMDefaults --session			$defaultShell
	#$etDMDefaults --show-manual-login	true
	#$etDMDefaults --show-remote-login	true
	#$etDMDefaults --allow-guest		true
	#$etDMDefaults --greeter
	return 0
	cat << END-OF-LIGHTDM > /etc/lightdm/lightdm.conf
[SeatDefaults]
autologin-guest=false
autologin-user=${username}
autologin-user-timeout=0
autologin-session=lightdm-autologin
#user-session=ubuntu
#user-session=xfce4-session
#user-session=gnome-fallback
user-session=${loginShell}
greeter-session=unity-greeter
END-OF-LIGHTDM
}
function add_admin_user(){
	local username=$1
	local password=$2
	useradd  -m -s /bin/bash                         ${username}
	set_user_passwd                                  ${username} $password
	usermod -a -G adm,cdrom,sudo,dip,plugdev,lpadmin ${username}
	set_ssh_authorized_keys                          ${username}
}
function add_basic_user(){
	local username=$1
	local password=$2
	useradd  -m -s /bin/bash                         ${username}
	set_user_passwd                                  ${username} $password
	set_ssh_authorized_keys                          ${username}
}
function get_ssh_keys(){
	cat << EOF-OF-SSHKEYS >> $@
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAofjHmUuZrNEsTUSx/Agb5bJOGP57DvbLxAh9xsBniAvyA7I3X68TAJZixWKQEs4SbhNhkO5wcZwC/9k/j2GXpvKEFewscxlw9X1/Mcxcpndl94Yptei2klBb5WKNSFJ06GxkxM/AtfXK6IQtKr/qiQfg/pdvwQ/X51kKFp8DQdiaUz5GgEqh19y6+uCfqGJsOkNph/9cGJGeJxRxJjuwghI3fmb9QapxLSqcQBJ++0GDo4UyO5smJgBiyL96g3sOzB4H/UMGdnQqsemLGvRmu60Jmy15D0I1XDfcN29kYOfoxYzkpbxvp3P9F/BL/Yao/J3x1Cz1U17GqRduTgnwrQ== root@RHEL01.localdomain
ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAmMckh4/gd/8LK4wpmhdcnSEzLuDR+aiNojMI5j3enNRiJ4Kml4+JxlwllosZW2soz8i6THVEzp24d39XrfrXmopXQaUr+D41ES0WDbq0ZNu2hxLVxwLFimbo7xdRKs5+e8VuBBbH7gIvGYdmUGWEN8972S2UJpJnupgw4WaOg8U= rsa-key-20110617
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAzIO6rkj+CGBs4caGagQgZb18JALME2x8dD1HHgEjNJ2waB/MAsEPa80QZm1hQydjt5T5Sz2Ni9sayeOYAXHNLydmzoOWqw2Hd0I9LiSx6Kw9c7D+27RDjXgEjo6cCAgDRH9IL6tqVWzwGAYb3hx7O+u4ZYuByYzzClvzFpfVFOtffS+f/8qQfGHElCP3RZSZaNzy5HAx2P4Y5cRKhGLDyitOTe1aBAMUVjDQybSMc8nV0Z7T8A7pa+6/JncxqYvTjYY6YlVwiZesImjjo2tkvH1QT5N2z6lc2NTePF5FI+INiO9UJvqRXdTxxdtm2kwbk4sAAbvWEDWOFPh+53RTQQ== root@pxe.pig.pie
EOF-OF-SSHKEYS
}
function get_user_details(){
	# Returns; username uid gid home
	cat /etc/passwd | egrep "^${1}:" | cut -d: -f1,3,4,6 | tr : ' ';
}
function set_ssh_authorized_keys(){
	read user uid gid home < <(get_user_details $1)
	[ ! -e "${home}" ] && return 1
	mkdir         "${home}/.ssh"
	get_ssh_keys  "${home}/.ssh/authorized_keys"
	chown -R $uid "${home}/.ssh"
	chgrp -R $gid "${home}/.ssh"
	chmod     744 "${home}/.ssh"
	chmod     600 "${home}/.ssh/authorized_keys"
}
function set_toprc(){
	read user uid gid home < <(get_user_details $1)
	echo $user $home $gid $uid
	touch                 "${home}/.toprc"
	chown $uid            "${home}/.toprc"
	chgrp $gid            "${home}/.toprc"
	cat << END-OF-TOPRC > "${home}/.toprc"
RCfile for "top with windows"           # shameless braggin'
Id:a, Mode_altscr=0, Mode_irixps=1, Delay_time=3.000, Curwin=0
Def     fieldscur=AEHIOQTWKNMbcdfgjplrsuvyzX
        winflags=32569, sortindx=10, maxtasks=0
        summclr=1, msgsclr=1, headclr=3, taskclr=1
Job     fieldscur=ABcefgjlrstuvyzMKNHIWOPQDX
        winflags=62777, sortindx=0, maxtasks=0
        summclr=6, msgsclr=6, headclr=7, taskclr=6
Mem     fieldscur=ANOPQRSTUVbcdefgjlmyzWHIKX
        winflags=62777, sortindx=13, maxtasks=0
        summclr=5, msgsclr=5, headclr=4, taskclr=5
Usr     fieldscur=ABDECGfhijlopqrstuvyzMKNWX
        winflags=62777, sortindx=4, maxtasks=0
        summclr=3, msgsclr=3, headclr=2, taskclr=3
END-OF-TOPRC
}

