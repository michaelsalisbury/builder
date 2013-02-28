#!/bin/builder.sh
skip=( false false false false false false false )
step=1
prefix="setup"

        ##########################################################################################################
        owncloud_Downloads_Prep=/root/Downloads
        owncloud_changelog=$owncloud_Downloads_Prep/owncloud_changelog
        owncloud_mysql_root_passwd=1qaz@WSX
        owncloud_mysql_database_name=owncloud
        ##########################################################################################################
        function repc(){ echo `seq $1` | sed "s/ /$2/g;s/[^$2]//g"; }
        function desc(){ echo; line="#### $@ `repc 100 '#'`"; echo `repc 101 '#'`; echo ${line:0:100}; echo; }
        function parse_new_version(){ sed '/^Release/s/[^"]*"\([0-9\.]*\)"$/\1/p;d' "$owncloud_changelog" | head -1; }
        function parse_cur_version(){ sed "/version/s/[^']*'\([0-9\.]*\)',$/\1/p;d" /var/www/owncloud_config/config.php; }                                                    
	function parse_IP(){ ifconfig eth0 | sed 's/.*inet addr:\([^ ]*\).*/\1/p;d'; }
        function parse_HN(){ grep HOSTNAME /etc/sysconfig/network | cut -d= -f2; }


function setup_Download(){
        ##########################################################################################################      
        ################################################################ Download new release
                                                                    desc Download new release
        mkdir   -p "$owncloud_Downloads_Prep"
        rm      -f "$owncloud_changelog"
        wget -q -O "$owncloud_changelog" http://owncloud.org/releases/Changelog
        [ -f       "$owncloud_changelog" ] && echo Changelog retrieved. && echo
        ver=`parse_new_version`
        echo New version = $ver && echo

        rm      -f "$owncloud_Downloads_Prep/owncloud-${ver}.tar.bz2"
        wget -q -O "$owncloud_Downloads_Prep/owncloud-${ver}.tar.bz2" http://owncloud.org/releases/owncloud-${ver}.tar.bz2                                                          
        [ -f       "$owncloud_Downloads_Prep/owncloud-${ver}.tar.bz2" ] && echo New version [${ver}] retrieved.
}       

function setup_Unpack(){
##########################################################################################################
################################################################ Unpack to /var/www/owncloud-${ver}
                                                            desc Unpack to /var/www/owncloud-${ver}

        ver=`parse_new_version`
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
function setup_Bind(){
##########################################################################################################
################################################################ Bind config directory
                                                            desc Bind config directory

        ver=`parse_new_version`
	cnf='/var/www/owncloud_config/config.php'
	mkdir /var/www/owncloud_data
	mkdir /var/www/owncloud_config
	cp -f /var/www/owncloud-${ver}/config/* /var/www/owncloud_config/.
	cp    /var/www/owncloud_config/config.sample.php					${cnf}
	sed -i "/datadirectory/ s/.*/\"datadirectory\" => '\/var\/www\/owncloud_data',/"	${cnf}
	sed -i "/forcessl/      s/.*/\"forcessl\" => true,/"					${cnf}
	sed -i "/owncloud.apps/ s/\/apps/-${ver}\/apps/"					${cnf}

	sed -i "/\/var\/www\/owncloud-${ver}\/config/d" /etc/fstab
	echo "/var/www/owncloud_config		/var/www/owncloud-${ver}/config	bind	defaults,bind	0 0" \
		>> /etc/fstab
	echo Bind entry to map /var/www/owncloud_config to /var/www/owncloud-${ver}/config made in fstab
	mount -a
	[ -n "`grep ${ver} /etc/mtab`" ] && echo /var/www/owncloud_config mounted to /var/www/owncloud-${ver}/config
}
function setup_Permissions(){
	##########################################################################################################
	################################################################ Fix permissions
                                                            desc Fix permissions
	
        ver=`parse_new_version`
	chown -R root.root       /var/www/owncloud-${ver}
	chown -R apache.apache   /var/www/owncloud-${ver}/apps
	chown -R apache.apache   /var/www/owncloud-${ver}/.htaccess
	chown -R apache.apache   /var/www/owncloud_config
	chown -R apache.apache   /var/www/owncloud_data

	echo "Permisions set to own[root]   grp[root] for /var/www/owncloud-${ver}"
	echo "Permisions set to own[apache] grp[apache] for /var/www/owncloud-${ver}/apps"
	echo "Permisions set to own[apache] grp[apache] for /var/www/owncloud-${ver}/.htaccess"
	echo "Permisions set to own[apache] grp[apache] for /var/www/owncloud_config"
	echo "Permisions set to own[apache] grp[apache] for /var/www/owncloud_data"
}
function setup_Apache(){
##########################################################################################################
################################################################ Add new Apache virtual host config
                                                            desc Update Apache virtual host config

        ver=`parse_new_version`
	IP=`parse_IP`
	cp -f /etc/owncloud/owncloud.http.conf /etc/httpd/conf.d/owncloud.conf
	sed -i "/ServerAlias/s/serverHostName.cos.ucf.edu/`hostname`/" /etc/httpd/conf.d/owncloud.conf
	sed -i  "/ServerName/s/serverHostName.cos.ucf.edu/`hostname`/" /etc/httpd/conf.d/owncloud.conf
	sed -i "/RewriteRule/s/serverHostName.cos.ucf.edu/`hostname`/" /etc/httpd/conf.d/owncloud.conf
	sed -i "/RewriteCond/s/-server_IP_address-/${IP//./\.}/"        /etc/httpd/conf.d/owncloud.conf
	sed -i "/DocumentRoot/s/owncloud-ver/owncloud-${ver}/"          /etc/httpd/conf.d/owncloud.conf

	[ -n "`grep ${ver} /etc/httpd/conf.d/owncloud.conf`" ] && echo Apache virtual host config updated
}
function setup_Service(){
##########################################################################################################
################################################################ Restart Apache
                                                            desc Restart Apache
	
        ver=`parse_new_version`
	IP=`parse_IP`
	HN=`parse_HN`
	sed -i "/${IP}/d"                     /etc/hosts
	echo "${IP}	${HN}	${HN%%.*}" >> /etc/hosts

	[ -f "/etc/php.ini.bk" ] && {
	        mv /etc/php.ini    /etc/php.ini-`date "+%s"`
	        cp /etc/php.ini.bk /etc/php.ini
	} || {  cp /etc/php.ini    /etc/php.ini.bk; }
	
	[ -f "/etc/httpd/conf/httpd.conf.bk" ] && {
		mv /etc/httpd/conf/httpd.conf    /etc/httpd/conf/httpd.conf.bk-`date "+%s"`
		cp /etc/httpd/conf/httpd.conf.bk /etc/httpd/conf/httpd.conf
	} || {	cp /etc/httpd/conf/httpd.conf    /etc/httpd/conf/httpd.conf.bk; }
	
	sed -i '/php_value memory_limit/s/.*/php_value memory_limit 1024M/' /var/www/owncloud-${ver}/.htaccess
	
	sed -i '/memory_limit/         s/.*/memory_limit        = 1024M/'	/etc/php.ini
	sed -i '/upload_max_filesize/  s/.*/upload_max_filesize = 1024M/'	/etc/php.ini
	sed -i '/post_max_size/        s/.*/post_max_size       = 1024M/'	/etc/php.ini
	sed -i '/[^;]*max_input_time/  s/.*/max_input_time      = 1800/'	/etc/php.ini
	
	sed -i '/SSLEngine/            s/.*/SSLEngine off/'	/etc/httpd/conf.d/ssl.conf
	sed -i '/ServerTokens/         s/.*/ServerTokens PROD/'	/etc/httpd/conf/httpd.conf
	sed -i '/NameVirtualHost..:80/{s/#//p;s/80/443/}'	/etc/httpd/conf/httpd.conf
	echo TraceEnable off >>					/etc/httpd/conf/httpd.conf
	chkconfig --level 35 httpd on
	service httpd restart
}



















