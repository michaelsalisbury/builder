#!/bin/bash

#mail="michael.salisbury@ucf.edu"
mail="michael.salisbury@ucf.edu jp@ucf.edu robert.haas@ucf.edu"

mkdir   -p /root/Downloads
rm      -f /root/Downloads/owncloud_changelog  
wget -q -O /root/Downloads/owncloud_changelog http://owncloud.org/releases/Changelog
ver=$(sed '/^Release/s/[^"]*"\([0-9\.]*\)"$/\1/p;d' /root/Downloads/owncloud_changelog | head -1)
cur=$(sed "/version/s/[^']*'\([0-9\.]*\)',$/\1/p;d" /var/www/owncloud_config/config.php)

[[ ! "${ver}" = "${cur}" ]] && {
	echo Update Available ::: Current Version ${cur} ::: New Version ${ver}
	echo ----------------------------------------------------------------
	sed '/^Release *\"'${cur}'\"/,$d' /root/Downloads/owncloud_changelog

	for address in ${mail}
                do
			mail -s "$(hostname) ::: New Owncloud Version Available"  ${address}  << END-OF-MESSAGE
Update Available ::: Current Version ${cur} ::: New Version ${ver}
----------------------------------------------------------------
$(sed '/^Release *\"'${cur}'\"/,$d' /root/Downloads/owncloud_changelog)
END-OF-MESSAGE
		done
}




