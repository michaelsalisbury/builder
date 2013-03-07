#!/bin/bash

function main(){
	if [ "$(whoami)" == "root" ]; then
		if [ -n "$1" ]; then
			if [ -d "$(awk -F: -v U=$1 'U == $1{print $6}' /etc/passwd)" ]; then
				echo $1 | xargs -i@ su @ /bin/bash -c $(readlink -f ${BASH_SOURCE})
			else
				echo ERROR! Bad username supplied
			fi
		else
			echo The following users will now have Office installed...
			echo -----------------------------------------------------
			list_users
			echo -----------------------------------------------------
			echo 10 seconds to cancel\; press ctrl-c
			for i in {10..1}; do echo -n $i..; sleep 1; done	
			echo -----------------------------------------------------
			echo
			list_users | xargs -i@ su @ /bin/bash -c $(readlink -f ${BASH_SOURCE})
		fi

	else
		#[ "$(whoami)" != "test" ] && exit 1
		global_variables
		unpack_office
		setup_wine_dir
		setup_local_dir
		setup_config_dir
		reconfigure_desktop_shortcuts
		reconfigure_wine_reg_configs
	fi
}
function reconfigure_wine_reg_configs(){
	# fix desktop shortcuts
	local target_files="${HOME}/.local/share/applications"
	echo -n ${HOME} :: Reconfiguring desktop files in \"${target_files}\" .
	while read path; do
		sed -i "s|${wine_home}|${HOME}|g" "${path}"
		echo -n .
	done < <(find "${target_files}" -type f -name *desktop)
	echo
}
function reconfigure_desktop_shortcuts(){
	# fix wine config files
	while read path; do
		local source_file=$(basename "${path}")
		local target_file="${wine_dir}/${source_file}"
		local source_file="${path}"
		echo -n ${HOME} :: Reconfiguring \"${target_file}\" .
		while read line; do echo -n .; done < <(
			sed "s|${wine_home}|${HOME}|g" "${source_file}" | tee "${target_file}")
		echo
	done < <(ls -d1 "${wine_tmp}"/*.reg)
	echo
}
function setup_config_dir(){
	# setup menu files in .config directory
	local source_files="${wine_tmp}/.config/menus/applications-merged"
	local backup_files="${wine_tmp}/.config.bk/menus/applications-merged"
	local target_files="${HOME}/.config/menus/applications-merged"
	[ ! -d "${source_files}" ] && { echo \"${source_files}\" missing from unpacked office install!; exit 1; }
	echo -n ${HOME} :: Backing up \"${target_files}\" .
	while read line; do echo -n .; done < <(rsync -vr "${target_files}"/ "${backup_dir}"/)
	echo
	echo -n ${HOME} :: Installing menu files to \"${target_files}\" .
	mkdir -p "${target_files}"
	while read line; do echo -n .; done < <(rsync -vr "${source_files}"/ "${target_files}"/)
	echo
	echo
}
function setup_local_dir(){
	# setup desktop files in .local directory
	local source_files="${wine_tmp}/.local/share"
	local backup_files="${wine_tmp}/.local.bk/share"
	local target_files="${HOME}/.local/share"
	[ ! -d "${source_files}" ] && { echo \"${source_files}\" missing from unpacked office install!; exit 1; }
	while read path; do
		local target_dir=$(basename "${path}")
		local backup_dir="${backup_files}/${target_dir}"
		local target_dir="${target_files}/${target_dir}"
		mkdir -p  "${backup_dir}"
		echo -n ${HOME} :: Backing up \"${target_dir}\" .
		while read line; do echo -n .; done < <(rsync -vr "${target_dir}"/ "${backup_dir}"/)
		echo
		mkdir -p  "${target_dir}"
		echo -n ${HOME} :: Setting up \"${target_dir}\" .
		while read line; do echo -n .; done < <(rsync -vr "${path}"/ "${target_dir}"/)
		echo
	done < <(ls -d1 "${source_files}"/*)
	echo
}
function setup_wine_dir(){
	# move wine directory
	[   -d "${wine_dir}" ] && { echo ERROR! destination wine dir \"${wine_dir}\" already exists!; exit 1; }
	[ ! -d "${wine_dir}" ] && mv "${wine_tmp}/${wine_name}" "${wine_dir}"
	echo ${HOME} :: Prepping links in \"${wine_dir}/dosdevices\"
	ln -s "../drive_c" "${wine_dir}/dosdevices/c:"
	ln -s "/dev/sr0"   "${wine_dir}/dosdevices/d::"
	ln -s /            "${wine_dir}/dosdevices/z:"
	echo -n ${HOME} :: Backing up wine reg files to \"${wine_tmp}\" .
	while read line; do echo -n .; done < <(cp -v "${wine_dir}"/*.reg "${wine_tmp}"/.)
	echo
	echo
}
function unpack_office(){
	# make staging directory
	[   -d "${wine_tmp}" ] && rm -rf "${wine_tmp}"
	[ ! -d "${wine_tmp}" ] && mkdir  "${wine_tmp}"
	[ ! -d "${wine_tmp}" ] && { echo ERROR! couldn\'t create stage dir \"${wine_tmp}\"; exit 1; }

	# unpack office instalation
	cd     "${wine_tmp}"
	[ "$(pwd)" != "${wine_tmp}" ] && { echo ERROR! didn\'t change to stage dir \"${wine_tmp}\"; exit 1; }
	echo -n ${HOME} :: Unpacking Office to \"${wine_tmp}\" .
	while read line; do echo -n .; done < <(tar -zxvf "${wine_tgz}")
	echo
	echo
}
function global_variables(){
		wine_tgz=$(readlink -f "${BASH_SOURCE}")
		wine_tgz=$(dirname     "${wine_tgz}")
		wine_tgz=$(readlink -f "${wine_tgz}"/Office*wine*)
		wine_home="/home/office"
		wine_name=".wine32_office"
		wine_dir="${HOME}/${wine_name}"
		wine_tmp="${HOME}/${wine_name}_tmp"
}


function list_users(){
	awk -F: '"file "$6 |& getline D{if(D ~ "directory$" && $3 >= 1000) print $1}' /etc/passwd
}




























main $@
