#!/bin/sh

base_name='bootstrap-base.postinst'
sed_script="/tmp/preseed/preseed.${base_name}.sed"
sed_target="/var/lib/dpkg/info/${base_name}"

cat << END-OF-SED > ${sed_script}
	/^waypoint 1[ \t]*check_target/              i . /tmp/preseed/preseed.${base_name}.sh
	/^waypoint 1[ \t]*check_target/              a waypoint 1      interactive_01
	/^waypoint 1[ \t]*get_mirror_info/           a waypoint 1      interactive_02
	/^waypoint 1[ \t]*pre_install_hooks/         a waypoint 1      interactive_03
	/^waypoint 100[ \t]*install_base_system/     a waypoint 1      interactive_04
	/^waypoint 1[ \t]*setup_dev/                 a waypoint 1      interactive_05
	/^waypoint 1[ \t]*configure_apt_preferences/ a waypoint 1      interactive_06
	/^waypoint 1[ \t]*configure_apt$/            a waypoint 1      interactive_07
	/^waypoint 3[ \t]*apt_update/                a waypoint 1      interactive_08
	/^waypoint 5[ \t]*post_install_hooks/        a waypoint 1      interactive_09
	/^waypoint 1[ \t]*pick_kernel/               a waypoint 1      interactive_10
	/^waypoint 20[ \t]*install_kernel/           a waypoint 1      interactive_11
	/^waypoint 10[ \t]*install_extra/            a waypoint 1      interactive_12
	/^waypoint 0[ \t]*final_apt_preferences/     a waypoint 1      interactive_13
	/^waypoint 0[ \t]*cleanup/                   a waypoint 1      interactive_14
END-OF-SED

sed -i -f ${sed_script} ${sed_target}
