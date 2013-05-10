#!/bin/builder.sh

# IMPORTANT: Includes must be placed before global variables like "skip" & "step"
#while read import; do
#	${import:+/bin/bash} "${import:-false}"
#done < <(ls -1              "${scriptPath}"/functions.*.sh 2> /dev/null
#	 ls -1 "${scriptPath}"/../functions/functions.*.sh 2> /dev/null)

# GLOBAL VARIABLES
skip=( false false false false )
step=1
prefix="setup"
source=http://192.168.248.24/config/$scriptName

function setup_skel_Structure(){
	desc Build skel directory structure
	mkdir -p  /etc/skel/.config/xfce4
	chmod 700 /etc/skel/.config
	chmod 700 /etc/skel/.config/xfce4
}
function setup_Panel_Icons(){
	desc Add Panel icons
	mkdir -p                            /etc/skel/.config/xfce4/panel/launcher-13
	mkdir -p                            /etc/skel/.config/xfce4/panel/launcher-13
	cat << END-OF-13520553166.desktop > /etc/skel/.config/xfce4/panel/launcher-13/13520553166.desktop
[Desktop Entry]
Name=Terminator
Comment=Multiple terminals in one window
TryExec=terminator
Exec=terminator
Icon=terminator
Type=Application
Categories=GNOME;GTK;Utility;TerminalEmulator;System;
StartupNotify=true
X-Ubuntu-Gettext-Domain=terminator
X-Ayatana-Desktop-Shortcuts=NewWindow;
X-XFCE-Source=file:///usr/share/applications/terminator.desktop

[NewWindow Shortcut Group]
Name=Open a New Window
Exec=terminator
TargetEnvironment=Unity
END-OF-13520553166.desktop
	mkdir -p                            /etc/skel/.config/xfce4/panel/launcher-14
	cat << END-OF-13520553487.desktop > /etc/skel/.config/xfce4/panel/launcher-14/13520553487.desktop
[Desktop Entry]
Version=1.0
Name=Google Chrome
GenericName=Web Browser
Comment=Access the Internet
Exec=/opt/google/chrome/google-chrome %U
Terminal=false
Icon=google-chrome
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml_xml;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;
X-Ayatana-Desktop-Shortcuts=NewWindow;NewIncognito
X-XFCE-Source=file:///usr/share/applications/google-chrome.desktop

[NewWindow Shortcut Group]
Name=New Window
Exec=/opt/google/chrome/google-chrome
TargetEnvironment=Unity

[NewIncognito Shortcut Group]
Name=New Incognito Window
Exec=/opt/google/chrome/google-chrome --incognito
TargetEnvironment=Unity
END-OF-13520553487.desktop
}
function setup_Panel_xml(){
	desc Establish Default Panel XML
	mkdir -p                        /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
	cat << END-OF-xfce4-panel.xml > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="30"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="13"/>
        <value type="int" value="14"/>
        <value type="int" value="3"/>
        <value type="int" value="15"/>
        <value type="int" value="8"/>
        <value type="int" value="9"/>
        <value type="int" value="10"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
        <value type="int" value="2"/>
        <value type="int" value="11"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu"/>
    <property name="plugin-2" type="string" value="actions"/>
    <property name="plugin-3" type="string" value="tasklist"/>
    <property name="plugin-15" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-4" type="string" value="pager"/>
    <property name="plugin-5" type="string" value="clock"/>
    <property name="plugin-6" type="string" value="systray">
      <property name="names-visible" type="array">
        <value type="string" value="xfce4-power-manager"/>
        <value type="string" value="networkmanager applet"/>
        <value type="string" value="classicmenu-indicator"/>
      </property>
    </property>
    <property name="plugin-8" type="string" value="cpugraph"/>
    <property name="plugin-9" type="string" value="diskperf"/>
    <property name="plugin-10" type="string" value="netload"/>
    <property name="plugin-11" type="string" value="screenshooter"/>
    <property name="plugin-13" type="string" value="launcher">
      <property name="items" type="array">
        <value type="string" value="13520553166.desktop"/>
      </property>
    </property>
    <property name="plugin-14" type="string" value="launcher">
      <property name="items" type="array">
        <value type="string" value="13520553487.desktop"/>
      </property>
    </property>
  </property>
</channel>
END-OF-xfce4-panel.xml

}
