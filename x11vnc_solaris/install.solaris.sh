#!/bin/bash

# setup pkgutils
# http://www.opencsw.org/manual/for-administrators/getting-started.html
###pkgadd -d http://get.opencsw.org/now

# add /opt/csw/bin to PATH & SUPATH in /etc/default/login

# Install dependancies; lsof, netcat(vnc port forward), ncurses(vim color support)
###pkgutil -i lsof
###pkgutil -i netcat
###pkgutil -i ncurses

# verify that sshd_config allows for TCP and gateway forwarding
# allowTcpForwarding yes
# GatewayPorts yes

# Setup SMF Services

#1) Add service entries to /etc/services
for p in {1..9}; do

	cat <<-SERVICES >> /etc/services
vnc$p		590$p/tcp			# vncserver /etc/x11vnc/Xvnc-dynamic.sh
	SERVICES
done
#2) Add SMF service entry
for p in {1..9}; do
	# remove entries first
	svcadm disable vnc$p/tcp
	svccfg delete  vnc$p/tcp
	rm -f /var/svc/manifest/network/vnc$p-tcp.xml
	# re-add SMF entry
	cat <<-SMF | inetconv -i <(cat)
vnc$p stream tcp nowait root /etc/x11vnc/Xvnc-dynamic.sh Xvnc-dynamic.sh allowed.vncserver
	SMF
done
#3) list service entries
for p in {1..9}; do
	svcs -a vnc$p/tcp
done
#4) bind services to localhost
for p in {1..9}; do
	inetadm -m vnc$p/tcp bind_addr="127.0.0.1"
done
#5) list service details
for p in {1..9}; do
	inetadm -l vnc$p/tcp
done
#6) restart service so bind localhost will take affect
for p in {1..9}; do
	svcadm restart vnc$p/tcp
done


