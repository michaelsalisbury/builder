#!/bin/builder.sh
skip=( false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/global/$scriptName

###########################################################################################
#                                                             Network Managemer CLI Support
###########################################################################################
function generate_uuid(){
	python -c 'import uuid; print uuid.uuid1();'
}
function get_nmcli_WAN(){
	# Returns iface ip; Tests for interface with DHCP4 IP address
	local -a ifaces
	while read iface; do
		if get_nmcli_detail $iface dhcp_ip &> /dev/null; then
			ifaces[${#ifaces[@]}]=$iface
		fi
	done < <(nmcli dev list	| awk '{if ($1 == "GENERAL.DEVICE:") { print $2; } }')
	if [ -n "${#ifaces[@]}" ]; then
		echo ${ifaces[@]}
		return 0
	else
		echo no-dhcp
		return 1
	fi
}
function get_nmcli_LAN(){
	# Returns all interfaces without DHCP ip addresses
	local -a ifaces
	while read iface; do
		if ! get_nmcli_detail $iface dhcp_ip &> /dev/null; then
			ifaces[${#ifaces[@]}]=$iface
		fi
	done < <(nmcli dev list	| awk '{if ($1 == "GENERAL.DEVICE:") { print $2; } }')
	if [ -n "${#ifaces[@]}" ]; then
		echo ${ifaces[@]}
		return 0
	else
		echo none
		return 1
	fi
}

function get_nmcli_detail(){
	if (( ${#@} < 2 )); then
		cat << END-OF-HELP-MESSAGE
 List of Available Interface Details
-------------------------------------
  uuid	      timestamp       id

  type	      dhcp_domain     mac		
  product     dhcp_ip         ip
  driver      dhcp_gw	      gw
              dhcp_mask       mask
              dhcp_cidr       cidr
-------------------------------------
END-OF-HELP-MESSAGE
		return 1
	fi
	local iface=$1
	local detail=$2
	local  mac="$FUNCNAME $iface mac"
	local  adr="$FUNCNAME $iface adr"
	local   ip="$FUNCNAME $iface ip"
	local cidr="$FUNCNAME $iface cidr"
	local dhcp_ip="$FUNCNAME $iface dhcp_ip"
	local dhcp_mask="$FUNCNAME $iface dhcp_mask"
	case "${detail}" in
		uuid)		get_nmcli_con_detail `$mac` connection.uuid;;
		id)		get_nmcli_con_detail `$mac` connection.id;;
		type)		get_nmcli_con_detail `$mac` connection.type;;
		timestamp)	get_nmcli_con_detail `$mac` connection.timestamp;;
		adr)		get_nmcli_con_detail `$mac` ^ipv4.addresses$;;
		ip)		$adr | awk -F'[ /,]' '{if (length($4) == 0) print $1; else print $4} ';;
		cidr)		$adr | awk -F'[ /,]' '{if (length($5) == 0) print $1; else print $5} ';;
		gw)		$adr | awk -F'[ /,]' '{if (length($9) == 0) print $1; else print $9} ';;
		mask)		get_ipcalc_netmask `$ip` `$cidr`;;
		driver)		get_nmcli_dev_detail $iface ^GENERAL.DRIVER$;;
		product)	get_nmcli_dev_detail $iface ^GENERAL.PRODUCT$;;
		mac)		get_nmcli_dev_detail $iface ^GENERAL.HWADDR$;;
		dhcp_domain)	get_nmcli_dev_detail $iface \.fqdn_domainname;;
		dhcp_dns)	get_nmcli_dev_detail $iface \.domain_name_servers;;
		dhcp_ip)	get_nmcli_dev_detail $iface ^DHCP4\.OPTION\[[0-9]*\]\.ip_address$;;
		dhcp_mask)	get_nmcli_dev_detail $iface ^DHCP4\.OPTION\[[0-9]*\]\.subnet_mask$;;
		dhcp_cidr)	get_ipcalc_netmask `$dhcp_ip` `$dhcp_mask`;;
		*)		;;
	esac
}
function get_nmcli_con_detail(){
	local mac=$1
	shift
	local regex=$@
	# Here we identify the connection name
	while read NAME; do
		while read line; do
			if [[ "${line}" =~ "mac-address:${mac}" ]]; then
				local id=$NAME
				break
			fi
		done < <(nmcli -t --fields all con list id "${NAME}")
	done < <(nmcli -t --fields NAME con list)
	# Here we regex for the connection detail
	while IFS=: read key value; do
		if [[ "${key}" =~ ${regex} ]]; then
			if [ -z "${value}" ]; then
				echo empty-value
				return 1
			else
				echo ${value}
				return 0
			fi
		fi
	done < <(nmcli -t --fields all con list id "${id}")
	echo no-matching-key
	return 1
}
function get_nmcli_dev_detail(){
	local iface=$1
	shift
	local regex=$@
	# Here we regex for the device detail
	while IFS=% read key value; do
		if [[ "${key}" =~ ${regex} ]]; then
			if [ -z "${value}" ]; then
				echo empty-value
				return 1
			else
				echo ${value}
				return 0
			fi
		fi
	done < <(nmcli -t --fields all dev list iface $iface | \
		sed 's/:/%/; /^DHCP4.OPTION/ { s/%/./; s/ = /%/; }')
	echo no-matching-key
	return 1
}
function set_nmcli_dhcp(){
	# Usage iface
	local iface=$1
	local mac=`get_nmcli_detail $iface mac`
	local nm_conf='/etc/NetworkManager/NetworkManager.conf'
	# stop network-manager service
	stop network-manager

	# If the entry "no-auto-default" exists and contains this interfaces mac then remove the mac
	if `egrep -i ^no-auto-default=.*${mac},                     "${nm_conf}" &> /dev/null`; then
		sed -i "/^no-auto-default=/ { s/${mac},//; /=$/d }" "${nm_conf}"
	fi

	# Remove the /etc/NetworkManager/system-connections/ file
	rm -f "/etc/NetworkManager/system-connections/`get_nmcli_detail $iface id`"

	# restart network-manager
	start network-manager
}
function set_nmcli_static(){
	# Usage iface ip mask|cidr [gw]
	local iface=$1

	# Verify that the network-manager service is running
	status network-manager | grep running &> /dev/null || { echo ERROR :: network-manager not running, exiting! && return 1; }

	
	local mac=`get_nmcli_detail $iface mac`
	local nm_conf='/etc/NetworkManager/NetworkManager.conf'

	# Verify package ipcalc is installed
	dpkg -s ipcalc &> /dev/null || { echo ERROR :: ipcalc not installed, exiting! && return 1; }

	# Create the /etc/NetworkManager/system-connections/ file
	# get_nmcli_systemConnection iface ip mask|cidr [gw]
	get_nmcli_systemConnection $iface $2 $3 $4
	cat  "/etc/NetworkManager/system-connections/`get_nmcli_detail $iface id`"

	# If the entry "no-auto-default" doesn't exist add it
	if   ! `egrep -i ^no-auto-default=                     "${nm_conf}" &> /dev/null`; then
		sed -i "/^\[main\]$/a\no-auto-default=${mac}," "${nm_conf}"
	# Else If the entry "no-auto-default" exists but doesn't contain this interfaces mac then add it
	elif ! `egrep -i ^no-auto-default=.*${mac},            "${nm_conf}" &> /dev/null`; then
		sed -i "/^no-auto-default=/s/$/${mac},/"       "${nm_conf}"
	fi

	# restart network-manager
	stop network-manager
	sleep 1
	start network-manager
}
function get_nmcli_systemConnection(){
	# Usage iface ip mask|cidr [gw]
	local iface=$1
	local IP=$2
	local GW=$4

	# Verify that the network-manager service is running
	status network-manager | grep running &> /dev/null || { echo ERROR :: network-manager not running, exiting! && return 1; }

	local MASK=`get_ipcalc_cidr $2 $3`
	[ -z "${GW}" ] && GW='0.0.0.0'

	# Verify package ipcalc is installed
	dpkg -s ipcalc &> /dev/null || { echo ERROR :: ipcalc not installed, exiting! && return 1; }

	# Set full path to interface config file
	local conf="/etc/NetworkManager/system-connections/`get_nmcli_detail $iface id`"
	touch                           "${conf}"
	chmod 600                       "${conf}"
	cat << END-OF-WIREDCONNECTION > "${conf}" 
[`get_nmcli_detail $iface type`]
duplex=full
mac-address=`get_nmcli_detail $iface mac`

[connection]
id=`get_nmcli_detail $iface id`
uuid=`get_nmcli_detail $iface uuid`
type=`get_nmcli_detail $iface type`
timestamp=`get_nmcli_detail $iface timestamp`

[ipv6]
method=auto

[ipv4]
method=manual
addresses1=${IP};${MASK};${GW};
END-OF-WIREDCONNECTION
}
function get_dhcpd_subnet_entry(){
	local iface=$1
	local reservations=$2
	local reservation_begin=$3

	# Verify that interface has IP address
	local ip=`get_nmcli_detail $iface ip`
	[[ "${ip}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || { echo ip-not-set && return 1; }

	# Gather interface details
	local cidr=`get_nmcli_detail $iface cidr`
	local mask=`get_nmcli_detail $iface mask`

	local  range_last=`get_ipcalc_last  $ip $cidr`
	local range_first=`get_ipcalc_first $ip $cidr`

	# Setup subnet range
	if [ -z "${reservation_begin}" ]; then
		local reservation_end=$range_last
		local reservation_begin=

	else
		echo hi
	fi


}

function get_nmcli_(){

	local       WAN='eth0'
	local       LAN='eth1'
	local    LAN_IP='192.168.250.10'
	local     range='53'
	local      mask='24'

	# Extrapolate ipv4 info and dhcpd ranges from ip and mask
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
}


