#!/bin/builder.sh
skip=( false false false false false false false false false false )
step=1
prefix="setup"

function includes(){
	functions*.sh
}
function global_variables(){
	owncloud_release_major=7
	owncloud_Downloads_Prep=/root/Downloads
	owncloud_changelog=$owncloud_Downloads_Prep/owncloud_changelog
	owncloud_mysql_root_passwd=1qaz@WSX
	owncloud_mysql_database_name=owncloud
	owncloud_http_conf=/etc/httpd/conf.d/owncloud.conf
}

#function repc(){ echo `seq $1` | sed "s/ /$2/g;s/[^$2]//g"; }
#function desc(){
#	echo; line="#### $@ `repc 100 '#'`"; echo `repc 101 '#'`; echo ${line:0:100}; echo;
#}
function parse_new_version(){
	#sed '/^Release/s/[^"]*"\([a-z0-9\.]*\)"$/\1/p;d'       "$owncloud_changelog" | grep ^${owncloud_release_major} | head -1;
	sed '/Version/s/.*>Version\s\([^[:space:]]*\).*/\1/p;d' "$owncloud_changelog" | grep ^${owncloud_release_major} | head -1;
}
function parse_new_versions(){
	#sed '/^Release/s/[^"]*"\([a-z0-9\.]*\)"$/\1/p;d'       "$owncloud_changelog" | grep ^${owncloud_release_major}
	sed '/Version/s/.*>Version\s\([^[:space:]]*\).*/\1/p;d' "$owncloud_changelog" | grep ^${owncloud_release_major}
}
#function parse_cur_version(){
#	sed "/version/s/[^']*'\([0-9\.]*\)',$/\1/p;d" /var/www/owncloud_config/config.php;
#}
function parse_cur_version(){
	local -a docRoot=( $(
		grep DocumentRoot "${owncloud_http_conf}" |\
		sort -u |\
		head -1
	) )
	cat <<-END-OF-SED | sed -f <(cat) "${docRoot[@]:1}/lib/util.php"
		/getVersionString() *{/,/}/ {
			/return/ s/[^0-9]*\([0-9\.]*\).*/\1/p
		}
		d
	END-OF-SED
}

function setup_Download(){
	####################################################################################
	############################################################### Download new release
                                                                   desc Download new release
	mkdir   -p "$owncloud_Downloads_Prep"
	rm      -f "$owncloud_changelog"
	#wget -q -O "$owncloud_changelog" http://owncloud.org/releases/Changelog
	wget -q -O "$owncloud_changelog" http://owncloud.org/changelog/
	[ -f       "$owncloud_changelog" ] && echo Changelog retrieved. && echo
	ver=`parse_new_version`
	cur=`parse_cur_version`
	parse_new_versions      && echo
	echo New version = $ver && echo
	echo Cur version = $cur && echo

	rm      -f "$owncloud_Downloads_Prep/owncloud-${ver}.tar.bz2"
	wget -q -O "$owncloud_Downloads_Prep/owncloud-${ver}.tar.bz2" \
		    http://download.owncloud.org/community/owncloud-${ver}.tar.bz2
		    #http://owncloud.org/releases/owncloud-${ver}.tar.bz2
	[ -f       "$owncloud_Downloads_Prep/owncloud-${ver}.tar.bz2" ] \
	&& echo New version [${ver}] retrieved.
}
function setup_Backup(){
	####################################################################################
	############################################################# Backup current version
                                                                 desc Backup current version
	cur=`parse_cur_version`
	if [ ! -d /var/www/owncloud_config_bk${cur} ]; then
		cp -rvf  /var/www/owncloud_config /var/www/owncloud_config_bk${cur}
		echo
		if [ -d /var/www/owncloud_config_bk${cur} ]; then
			echo OwnCloud config backed-up to /var/www/owncloud_config_bk${cur}
			echo
		fi
	else
		echo WARNING!!! config already backed up to /var/www/owncloud_config_bk${cur}
	fi

	mysql_cred="-u root --password=$owncloud_mysql_root_passwd"
	mysql_db="$owncloud_mysql_database_name"

	if [ ! -f "/var/www/owncloud_mysql_dump_bk${cur}" ]; then
		mysql     $mysql_cred -D $mysql_db --execute="flush tables with read lock;"
		mysqldump $mysql_cred    $mysql_db > /var/www/owncloud_mysql_dump_bk${cur}
		mysql     $mysql_cred -D $mysql_db --execute="unlock tables;"
		echo Database backed up to /var/www/owncloud_mysql_dump_bk${cur}
	else
		echo WARNING!!! database already backed up to /var/www/owncloud_mysql_dump_bk${cur}
	fi
}
function setup_Unpack(){
	####################################################################################
	################################################# Unpack to /var/www/owncloud-${ver}
                                                     desc Unpack to /var/www/owncloud-${ver}
	
	ver=`parse_new_version`
	cur=`parse_cur_version`
	umount   /var/www/owncloud-${ver}/config
	umount   /var/www/owncloud-${ver}/config
	rm -rf   /var/www/owncloud-${ver}
	cd       /var/www
	tar -jxf "$owncloud_Downloads_Prep/owncloud-${ver}.tar.bz2"
	if [ -d /var/www/owncloud ]; then
		echo OwnCloud unpacked && echo
		mv /var/www/owncloud /var/www/owncloud-${ver}
	fi
	[ -d /var/www/owncloud-${ver} ] && echo OwnCloud setup in /var/www/owncloud-${ver}
}
function setup_Permissions(){
	####################################################################################
	################################################################ Fix permissions
	                                                            desc Fix permissions
	ver=`parse_new_version`
	chown -R root.root       /var/www/owncloud-${ver}
	chown -R apache.apache   /var/www/owncloud-${ver}/apps
	echo "Permisions set to own[root]   grp[root] for /var/www/owncloud-${ver}"
	echo "Permisions set to own[apache] grp[apache] for /var/www/owncloud-${ver}/apps"
}
function setup_Bind(){
	####################################################################################
	############################################################# Bind config directory
	                                                         desc Bind config directory
	ver=`parse_new_version`
	sed -i "/\/var\/www\/owncloud-${ver}\/config/d" /etc/fstab
	echo "/var/www/owncloud_config	/var/www/owncloud-${ver}/config	bind	defaults,bind	0 0" \
	>> /etc/fstab
	echo Bind entry to map /var/www/owncloud_config to /var/www/owncloud-${ver}/config made in fstab
	mount -a
	[ -n "`grep ${ver} /etc/mtab`" ] && echo /var/www/owncloud_config mounted to /var/www/owncloud-${ver}/config
}
function setup_Migrate_Apps(){
	##########################################################################################################
	################################################################ Mirror missing application directories
	                                                            desc Mirror missing application directories
	ver=`parse_new_version`
	cur=`parse_cur_version`
	ls -d /var/www/owncloud-${cur}/apps/* | while read directory; do
		[ ! -d "${directory/${cur}/${ver}}" ] && {
			echo Mirroring ::: ${directory}
			cp -rf ${directory}    ${directory/${cur}/${ver}}
			chown -R apache.apache ${directory/${cur}/${ver}}
		}
	done
}
function setup_Migrate_apps_Manualy(){
	##########################################################################################################
	################################################################ Re-setup missing application directories
	                                                            desc Re-setup missing application directories
	ver=`parse_new_version`
	cur=`parse_cur_version`
	ls -d /var/www/owncloud-${cur}/apps/* | while read directory; do
		[ ! -d "${directory/${cur}/${ver}}" ] && echo Manually Setup ::: ${directory}
	done
}
function setup_Apache(){
	##########################################################################################################
	################################################################ Add new Apache virtual host config
	                                                            desc Add new Apache virtual host config
	ver=`parse_new_version`
	cur=`parse_cur_version`
	if [ ! -f "/etc/httpd/conf.d/owncloud.conf.${cur}" ]; then
		cp /etc/httpd/conf.d/owncloud.conf /etc/httpd/conf.d/owncloud.conf.${cur}
		if [ -f /etc/httpd/conf.d/owncloud.conf.${cur} ]; then
			echo Old Apache virtual host config backed up to /etc/httpd/conf.d/owncloud.conf.${cur}
		fi
	else
		echo Old Apache virtual host config previosly backed up to /etc/httpd/conf.d/owncloud.conf.${cur}
		echo Be sure to verify that \"/etc/httpd/conf.d/owncloud.conf\" read is it should!
	fi
	#sed "/DocumentRoot/s/${cur}/${ver}/" /etc/httpd/conf.d/owncloud.conf > /etc/httpd/conf.d/owncloud.conf.${ver}
	sed -i "/DocumentRoot/s/${cur}/${ver}/" /etc/httpd/conf.d/owncloud.conf
	[ -n "`grep ${ver} /etc/httpd/conf.d/owncloud.conf`" ] && echo Apache virtual host config updated
	
}
function setup_Service(){
	##########################################################################################################
	################################################################ Restart Apache
	                                                            desc Restart Apache
	service httpd restart
}

