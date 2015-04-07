#!/bin/bash

# requires;
#	x11vnc-0.9.13-8.el6.x86_64 from rmpforge
#	xorg-x11-server-Xvfb-1.7.7-29.el6.x86_64.rpm for RHEL 6.1 from subscription
yum install epel-release
yum install libXfont xorg-x11-xfs xorg-x11-xfs-utils xorg-x11-xinit xorg-x11-xdm
yum install xorg-x11-fonts-100dpi.noarch \
	    xorg-x11-fonts-75dpi.noarch \
	    xorg-x11-fonts-ISO8859-*

yum install pixman pixman-devel libXfont
yum install nc lsof
yum install tigervnc-server
yum install redhat-lsb
yum install x11vnc

# verify that x11vnc is installed


# verify that xinetd is running


