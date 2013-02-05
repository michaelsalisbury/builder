#!/bin/builder.sh
skip=( true false false false false false false false false true false true true true true true true true true true true true true true true true true true true true true true true false false false false false false )
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

###########################################################################################
###########################################################################################
function xsetup_A(){
	desc "A"
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	echo A
}
function xsetup_B(){
	desc "B"
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	echo B
	reboot
}
function xsetup_C(){
	desc "C"
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	echo C
}
function xsetup_D(){
	desc "D"
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	echo D
}
function xsetup_END(){
	desc "END"
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	echo END
}
###########################################################################################
###########################################################################################


function setup_ssh(){
	waitForNetwork && networkUpMsg || return 1
        desc Modify /etc/ssh/sshd_config
        sed -i "s/.*GSSAPIAuthentication yes.*/#GSSAPIAuthentication yes/" /etc/ssh/sshd_config
        stop ssh
	stall 5
        start ssh
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

function setup_Must_Have_Tools(){
	desc Install Tools\; vim, ethtool, gconf-editor, iotop, iftop, default-jre
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	stall 10
	waitAptgetUpdate
	apt-get ${aptopt} update
	waitAptgetInstall
	apt-get ${aptopt} install vim ethtool gconf-editor iotop iftop default-jre terminator 

	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
        echo deb http://dl.google.com/linux/chrome/deb/ stable main >> /etc/apt/sources.list.d/google-chrome.list
	waitAptgetUpdate
	apt-get ${aptopt} update
	waitAptgetInstall
	apt-get ${aptopt} install google-chrome-stable
}

function setup_vboxadditions(){
        desc Install Virtual Box Linux Additions
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	stall 10
	waitAptgetUpdate
	apt-get ${aptopt} update
	waitAptgetInstall
	apt-get ${aptopt} install linux-headers-`uname -r` build-essential dkms xserver-xorg xserver-xorg-core
        ###################################################################################
	stall 10
        mkdir /root/Downloads
        mkdir /root/Downloads/vbox_guest_additions
        cd    /root/Downloads
        rm -f /root/Downloads/LATEST.TXT
        wget -nv http://download.virtualbox.org/virtualbox/LATEST.TXT
        cat   /root/Downloads/LATEST.TXT
        local version='4.1.16'
        local version='4.1.18'
        local version=`cat /root/Downloads/LATEST.TXT`
        rm -f /root/Downloads/VBoxGuestAdditions_${version}.iso
        wget -nv http://download.virtualbox.org/virtualbox/${version}/VBoxGuestAdditions_${version}.iso
        umount                                                        /root/Downloads/vbox_guest_additions
        mount -t iso9660 -o loop,ro VBoxGuestAdditions_${version}.iso /root/Downloads/vbox_guest_additions
        cd    /root/Downloads/vbox_guest_additions
        ./VBoxLinuxAdditions.run
        cd    /root/Downloads
        umount                                                        /root/Downloads/vbox_guest_additions
        reboot
}

function setup_interfaces(){
	desc "Fixup Interfaces"
	/sbin/udevadm trigger
	dmesg | sed 's|.*\(eth[1-9]\).*|\1|p;d' | /usr/bin/sort -u | while read eth; do
		echo - fixing ${eth}...
		cat >> /etc/network/interfaces << END-OF-INTERFACES

auto ${eth}
iface ${eth} inet dhcp
END-OF-INTERFACES
	done
	start networking &
}
function setup_Autoresponces(){
        desc Prep \for EULA and other apt-get prompts
	###################################################################################
	waitForNetwork && networkUpMsg || return 1
        echo hddtemp hddtemp/daemon select false | debconf-set-selections
        echo acroread-common acroread-common/default-viewer select true | debconf-set-selections
        echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
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
	#reboot
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
	#reboot
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
	reboot
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
	reboot
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

function setup_grub_customizer(){
	desc 'Command line application launch # > grub-customizer'
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	stall 10
        waitAptgetUpdate
        /usr/bin/add-apt-repository -y ppa:danielrichter2007/grub-customizer
        waitAptgetUpdate
        apt-get update
        waitAptgetInstall
        apt-get ${aptopt} install grub-customizer
}
function setup_ubuntu_tweak_n_myunity(){
        desc 'Ubuntu Tweak and MyUnity'
        ###################################################################################
        waitAptgetUpdate
        /usr/bin/add-apt-repository -y ppa:tualatrix/ppa
        waitAptgetUpdate
        apt-get update
        waitAptgetInstall
        apt-get ${aptopt} install ubuntu-tweak myunity
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
function setup_plymouth_theme_manager(){
	desc "Plymouth Theme Manager"
        ###################################################################################
        /usr/bin/add-apt-repository -y ppa:mefrio-g/plymouthmanager
        waitAptgetUpdate
        apt-get ${aptopt} update
        waitAptgetInstall
        apt-get ${aptopt} install plymouth-theme* plymouth-manager
}
function setup_auto_updates(){
	desc "Setup Auto Updates"
        ###################################################################################
	waitForNetwork && networkUpMsg || return 1
	stall 10
        waitAptgetInstall
        apt-get ${aptopt} install unattended-upgrades
        ###################################################################################
        cat << EOF > /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
        "\${distro_id} \${distro_codename}-security";
        "\${distro_id} \${distro_codename}-updates";
//      "\${distro_id} \${distro_codename}-proposed";
//      "\${distro_id} \${distro_codename}-backports";
};
EOF
        ###################################################################################
        cat << EOF > /etc/apt/apt.conf.d/10periodic
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
        ###################################################################################
        sed -i 's|^\(Prompt=\).*|\1never|' /etc/update-manager/release-upgrades
        echo "DONE: Review changes to the following files"
        echo -------------------------------------------
        echo "/etc/apt/apt.cond.d/50unattended-upgrades"
        echo "/etc/apt/apt.conf.d/10periodic"
        echo "/etc/update-manager/release-upgrades"
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
        mkdir /root/Downloads
        cd    /root/Downloads
        wget https://launchpad.net/~diesch/+archive/testing/+build/3076110/+files/classicmenu-indicator_0.07_all.deb
        waitAptgetInstall
        dpkg -i classicmenu-indicator_0.07_all.deb
        waitAptgetInstall
        apt-get ${aptopt} install python-gmenu
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






                ###################################################################################
                #desc "remove gnaome-colors-common"
                #apt-get ${aptopt} remove gnome-colors-common

                ###################################################################################
                #desc "Restore Splash Scheen"
                #rm                                                          /etc/alternatives/text.plymouth
                #ln -s /lib/plymouth/themes/ubuntu-text/ubuntu-text.plymouth /etc/alternatives/text.plymouth
                #rm                                                          /etc/alternatives/default.plymouth
                #ln -s /lib/plymouth/themes/ubuntu-logo/ubuntu-logo.plymouth /etc/alternatives/default.plymouth
                #update-initramfs -u
                #echo FRAMEBUFFER=y | tee /etc/initramfs-tools/conf.d/splash
                #waitAptgetInstall
                #apt-get ${aptopt} remove plymouth-theme-xubuntu-text plymouth-theme-xubuntu-logo
                #apt-get ${aptopt} --reinstall install plymouth-theme-ubuntu-logo plymouth-theme-ubuntu-text

		#desc "XFCE Fix Shell"
                #waitAptgetInstall
		#apt-get ${aptopt} remove aspell aspell-en dictionaries-common  miscfiles
                #waitAptgetInstall
		#apt-get ${aptopt} install aspell aspell-en dictionaries-common  miscfiles

function setup_disable_runonce(){
	desc "Remove from rc.local"
        ###################################################################################
	sed -i "/${scriptName}/s/^/#/" /etc/rc.local
}

