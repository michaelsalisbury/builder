#!/bin/builder.sh
skip=( true false false false false false true true true false true false true true true true true true true true true true true false true true true true false true true true true true false false false false false false )
step=1
prefix="setup"
source=http://192.168.248.24/config/$scriptName

aptopt="-y -q"
autoLoginUser="msalisbury"
###########################################################################################
###########################################################################################
function networkUpMsg(){ echo Network Up, Internet Accessible + DNS Responding.; }

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
function passwd(){
	local username=$1
	local password=$2
	perl -e 'system("usermod -p ".crypt($ARGV[1], rand)." $ARGV[0]")' $username $password
}
function ssh_keys(){
	cat << EOF-OF-SSHKEYS >> $@
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAofjHmUuZrNEsTUSx/Agb5bJOGP57DvbLxAh9xsBniAvyA7I3X68TAJZixWKQEs4SbhNhkO5wcZwC/9k/j2GXpvKEFewscxlw9X1/Mcxcpndl94Yptei2klBb5WKNSFJ06GxkxM/AtfXK6IQtKr/qiQfg/pdvwQ/X51kKFp8DQdiaUz5GgEqh19y6+uCfqGJsOkNph/9cGJGeJxRxJjuwghI3fmb9QapxLSqcQBJ++0GDo4UyO5smJgBiyL96g3sOzB4H/UMGdnQqsemLGvRmu60Jmy15D0I1XDfcN29kYOfoxYzkpbxvp3P9F/BL/Yao/J3x1Cz1U17GqRduTgnwrQ== root@RHEL01.localdomain
ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAmMckh4/gd/8LK4wpmhdcnSEzLuDR+aiNojMI5j3enNRiJ4Kml4+JxlwllosZW2soz8i6THVEzp24d39XrfrXmopXQaUr+D41ES0WDbq0ZNu2hxLVxwLFimbo7xdRKs5+e8VuBBbH7gIvGYdmUGWEN8972S2UJpJnupgw4WaOg8U= rsa-key-20110617
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAzIO6rkj+CGBs4caGagQgZb18JALME2x8dD1HHgEjNJ2waB/MAsEPa80QZm1hQydjt5T5Sz2Ni9sayeOYAXHNLydmzoOWqw2Hd0I9LiSx6Kw9c7D+27RDjXgEjo6cCAgDRH9IL6tqVWzwGAYb3hx7O+u4ZYuByYzzClvzFpfVFOtffS+f/8qQfGHElCP3RZSZaNzy5HAx2P4Y5cRKhGLDyitOTe1aBAMUVjDQybSMc8nV0Z7T8A7pa+6/JncxqYvTjYY6YlVwiZesImjjo2tkvH1QT5N2z6lc2NTePF5FI+INiO9UJvqRXdTxxdtm2kwbk4sAAbvWEDWOFPh+53RTQQ== root@pxe.pig.pie
EOF-OF-SSHKEYS
}
function ssh_keys_autoLoginUser(){
	mkdir         /home/${autoLoginUser}
	mkdir         /home/${autoLoginUser}/.ssh
	ssh_keys      /home/${autoLoginUser}/.ssh/authorized_keys
	chown -R 1000 /home/${autoLoginUser}
	chgrp -R 1000 /home/${autoLoginUser}
	chmod     744 /home/${autoLoginUser}/.ssh
	chmod     600 /home/${autoLoginUser}/.ssh/*
}
function ssh_keys_root(){
	mkdir              /root/.ssh
	ssh_keys           /root/.ssh/authorized_keys
        chown -R root.root /root/.ssh
        chmod 744          /root/.ssh
        chmod 600          /root/.ssh/*
}

###########################################################################################
###########################################################################################
function setup_Live_Distro_Prep(){
        waitForNetwork && networkUpMsg || return 1
        desc Prep: Add repos \& ssh keys \& autoLoginUser
	# repo keys
	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
	wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | apt-key add -
	# repoa
        cat << END-OF-REPOS >> /etc/apt/sources.list
deb http://us.archive.ubuntu.com/ubuntu/ quantal universe
deb-src http://us.archive.ubuntu.com/ubuntu/ quantal universe
deb http://us.archive.ubuntu.com/ubuntu/ quantal-updates universe
deb-src http://us.archive.ubuntu.com/ubuntu/ quantal-updates universe
deb http://dl.google.com/linux/chrome/deb/ stable main
deb http://download.virtualbox.org/virtualbox/debian quantal contrib
END-OF-REPOS
	#
	apt_clean_n_update
	# autoLoginUser
	useradd -u 1000 -m -s /bin/bash                  ${autoLoginUser}
	passwd                                           ${autoLoginUser} 1qaz@WSX
	usermod -a -G adm,cdrom,sudo,dip,plugdev,lpadmin ${autoLoginUser}
	ssh_keys_autoLoginUser
	passwd                          root             1qaz@WSX
	ssh_keys_root
	# Disable Welcome Screen
	apt-get ${aptopt} remove ubiquity
	# Setup casper.conf
	cat << END-OF-CASPER > /etc/casper.conf
# This file should go in /etc/casper.conf
# Supported variables are:
# USERNAME, USERFULLNAME, HOST, BUILD_SYSTEM, FLAVOUR

export USERNAME="ubuntu"
export USERFULLNAME="Live session user"
export HOST="ubuntu"
export BUILD_SYSTEM="Ubuntu"

# USERNAME and HOSTNAME as specified above won't be honoured and will be set to
# flavour string acquired at boot time, unless you set FLAVOUR to any
# non-empty string.

export FLAVOUR="Ubuntu"
END-OF-CASPER
}

function setup_ssh(){
	waitForNetwork && networkUpMsg || return 1
        desc Install openssh-server \& Modify /etc/ssh/sshd_config
	waitAptgetInstall
        apt-get ${aptopt} install openssh-server
        sed -i "s/.*GSSAPIAuthentication yes.*/#GSSAPIAuthentication yes/" /etc/ssh/sshd_config
}

function setup_aliases(){
	desc Setup Aliases
	cat << EOF > /etc/profile.d/aliases.sh
alias ll='ls -la --color'
EOF
}

function setup_top_template(){
	desc Setup top template for root and ${autoLoginUser}

	cat << END-OF-TOPRC > /root/.toprc
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

	(cat << EOF
	cat << END-OF-TOPRC > /home/${autoLoginUser}/.toprc
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
EOF
) | su ${autoLoginUser}
}
function setup_Autoresponces(){
        desc Prep \for EULA and other apt-get prompts
	###################################################################################
	waitForNetwork && networkUpMsg || return 1
        echo hddtemp hddtemp/daemon select false | debconf-set-selections
        echo acroread-common acroread-common/default-viewer select true | debconf-set-selections
        echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
}
function setup_Package_Holds(){
	desc Apt package holds
        ###################################################################################
	echo grub-pc hold		| dpkg --set-selections
	echo grub-common hold		| dpkg --set-selections
	echo grub-gfxpayload-lists hold	| dpkg --set-selections
	echo grub-pc hold		| dpkg --set-selections
	echo grub-pc-bin hold		| dpkg --set-selections
	echo grub2-common hold		| dpkg --set-selections
	dpkg --get-selections | grep -v install
}
function setup_Initial_Clean_Update_Upgrade(){
	desc Apt clean, update \& upgrade
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	apt_clean_n_update
	apt_update_n_upgrade
	reboot
}
function setup_Follow_Up_Update_Upgrade(){
	desc Apt update \& upgrade
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	apt_update_n_upgrade
	reboot
}
function setup_vboxadditions(){
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
        ./VBoxLinuxAdditions.run
        cd     /root/Downloads
        umount                                                        /root/Downloads/vbox_guest_additions
	rm -f  /root/Downloads/VBoxGuestAdditions_${version}.iso
	rm -rf /root/Downloads/vbox_guest_additions
}
function setup_vbox(){
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
	apt-get ${aptopt} install	vim ethtool gconf-editor iotop iftop \
					default-jre default-jre-headless \
					terminator multitail

	waitAptgetInstall
	apt-get ${aptopt} install google-chrome-stable
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
function setup_xubuntu(){
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
function setup_kubuntu(){
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
function setup_xfce(){
	desc "XFCE Shells"
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	stall 10
        #waitAptgetInstall
	#/usr/bin/add-apt-repository -y ppa:fossfreedom/xfwm4
        waitAptgetUpdate
        apt-get ${aptopt} update
        #waitAptgetInstall
        #apt-get ${aptopt} install dictionaries-common wamerican-insane
	waitAptgetInstall
        apt-get ${aptopt} install xfce4 xfce4-goodies xfwm4 xfwm4-themes backstep
        #waitAptgetInstall
	#apt-get ${aptopt} upgrade
}
function setup_gnome_shells(){
	desc "Gnome Shells"
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
        /usr/bin/add-apt-repository -y ppa:gnome3-team/gnome3
        /usr/bin/add-apt-repository -y ppa:ricotz/testing
        waitAptgetUpdate
        apt-get ${aptopt} update
        #waitAptgetInstall
        #apt-get ${aptopt} install dictionaries-common wamerican-insane
        waitAptgetInstall
        apt-get ${aptopt} install gnome gnome-shell gnome-session-fallback
        waitAptgetInstall
        apt-get ${aptopt} install gnome-shell-extentions-common
        waitAptgetInstall
        apt-get ${aptopt} install gnome-panel gnome-shell gnome-session-fallback gnome-tweak-tool
}
function setup_x2go(){
	desc "X2GO Server+Client"
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	stall 10
        waitAptgetUpdate
        /usr/bin/add-apt-repository -y ppa:x2go/stable
        waitAptgetUpdate
        apt-get ${aptopt} update
        waitAptgetInstall
        apt-get ${aptopt} install python-software-properties wamerican-insane
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
function setup_adobe(){
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
function setup_monitors(){
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
function setup_classicmenu(){
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





