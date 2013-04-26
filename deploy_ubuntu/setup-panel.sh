#!/bin/bash


# CPUFreq

	#sudo add-apt-repository -y ppa:artfwo/ppa
	#sudo apt-get update
	#sudo apt-get -y install indicator-cpufreq
	#sudo apt-get -yf install

# System Load Indicator
	sudo add-apt-repository -y ppa:indicator-multiload/stable-daily
	sudo apt-get update
	sudo apt-get -y install indicator-multiload
	sudo apt-get -yf install

# Stack Exchange Applet Indicator
	#apt-get install stackapplet
	#sudo apt-get -yf install

# Virtual Box Indicator
	sudo add-apt-repository -y ppa:michael-astrapi/ppa
	sudo apt-get update
	sudo apt-get -y install indicator-virtualbox
	sudo apt-get -yf install

# Keylick indicator (num-lock, tab-lock, scroll-lock)
	sudo add-apt-repository -y ppa:tsbarnes/indicator-keylock
	sudo apt-get update
	sudo apt-get -y install indicator-keylock
	sudo apt-get -yf install

# Radio Tray indicator
	sudo add-apt-repository -y ppa:tsbarnes/indicator-keylock
	sudo apt-get update
	sudo apt-get -y install indicator-keylock
	sudo apt-get -yf install
