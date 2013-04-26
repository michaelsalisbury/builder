#!/bin/bash


# CPUFreq

	#add-apt-repository -y ppa:artfwo/ppa
	#apt-get update
	#apt-get -y  install indicator-cpufreq
	#apt-get -yf install

# System Load Indicator
	add-apt-repository -y ppa:indicator-multiload/stable-daily
	apt-get update
	apt-get -y  install indicator-multiload
	apt-get -yf install

# Stack Exchange Applet Indicator
	#apt-get -y  install stackapplet
	#apt-get -yf install

# Virtual Box Indicator
	add-apt-repository -y ppa:michael-astrapi/ppa
	apt-get update
	apt-get -y  install indicator-virtualbox
	apt-get -yf install

# Keylick indicator (num-lock, tab-lock, scroll-lock)
	add-apt-repository -y ppa:tsbarnes/indicator-keylock
	apt-get update
	apt-get -y  install indicator-keylock
	apt-get -yf install

# Radio Tray indicator
	add-apt-repository -y ppa:tsbarnes/indicator-keylock
	apt-get update
	apt-get -y  install indicator-keylock
	apt-get -yf install

# LAPTOP - Touchpad Indicator
	add-apt-repository -y ppa:atareao/atareao
	apt-get update
	apt-get -y  install touchpad-indicator
	apt-get -yf install

# LAPTOP - Battery Indicator
	add-apt-repository -y ppa:iaz/battery-status
	apt-get update
	apt-get -y  install battery-status
	apt-get -yf install

# LAPTOP -Brighness Indicator
	add-apt-repository -y ppa:jan-simon/indicator-brightness
	apt-get update
	apt-get -y  install indicator-brightness
	apt-get -yf install

# My Weather Indicator Applet
        add-apt-repository -y ppa:noobslab/indicators
        apt-get update
        apt-get -y  install my-weather-indicator
	apt-get -yf install

# Another Weather Indicator Ubuntu Repo
	apt-get -y  install indicator-weather
	apt-get -yf install

# System Monitor Indicator
	add-apt-repository -y ppa:alexeftimie/ppia
	apt-get update
	apt-get -y  install indicator-sysmonitor
	apt-get -yf install

# Google Task Indicator
	apt-get -y  install google-tasks-indicator
	apt-get -yf install

# Google Calendar Indicator
	apt-get -y  install calendar-indicator
	apt-get -yf install

# Ubuntu One Indicator
	add-apt-repository -y ppa:rye/ubuntuone-extras
	apt-get update
	apt-get -y  install indicator-ubuntuone
	apt-get -yf install

# Hardware Sensors
	add-apt-repository -y ppa:alexmurray/indicator-sensors
	apt-get update
	apt-get -y  install indicator-sensors
	apt-get -yf install

# System notifications
	add-apt-repository -y ppa:jconti/recent-notifications
	apt-get update
	apt-get -y  install indicator-notifications
	apt-get -yf install

# Workspace Indicator
	add-apt-repository -y ppa:geod/ppa-geod
	apt-get update
	apt-get -y  install indicator-workspaces
	apt-get -yf install


