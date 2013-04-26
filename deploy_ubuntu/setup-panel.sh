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
