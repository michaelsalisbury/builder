#!/bin/bash

function main(){
	if [ "$(whoami)" == "root" ]; then
		if [ -n "$1" ]; then
			local user=$1
			if [ -d "$(awk -F: -v U=${user} 'U == $1{print $6}' /etc/passwd)" ]; then
				xinit_start     ${user}
				xinit_run       ${user}
				xinit_stop      ${user}
			else
				echo ERROR! Bad username supplied
				exit 1
			fi
		else
			echo The following users will now have Office installed...
			echo -----------------------------------------------------
			list_users
			echo -----------------------------------------------------
			echo 10 seconds to cancel\; press ctrl-c
			#for i in {10..1}; do echo -n $i..; sleep 1; done	
			echo -----------------------------------------------------
			echo
			for user in `list_users`; do
				/bin/bash $(readlink -f ${BASH_SOURCE}) ${user}
			done
		fi
	else
		# Test to be sure script is running in X
		local  PPPID=$(ps --no-heading -o ppid -p ${PPID})
		local PPPPID=$(ps --no-heading -o ppid -p ${PPPID})
		if   who -u | egrep -q "${USER}.*${PPID}[[:space:]]*\(:[01]"; then
			echo ${HOME} :: Installing Office
		elif who -u | egrep -q "${USER}.*${PPPID}[[:space:]]*\(:[01]"; then
			echo ${HOME} :: Installing Office
		elif who -u | egrep -q "${USER}.*${PPPPID}[[:space:]]*\(:[01]"; then
			echo ${HOME} :: Installing Office
		else
			echo ERROR! this command must be run in X.  Exiting.
			exit 1
		fi
		# Define global variables and unpack wine dir to stage
		global_variables
		unpack_office
		# setup the 32 bit wine office instance
		      setup_wine_dir
		reconfigure_wine_reg_files
		 initialize_wine
		    rebuild_wine_menus
		      tweak_wine_desktop_configs
		set_default_mime_config
	fi
}
function (){




}
function initialize_wine(){
		echo -n ${HOME} :: Initializing wine .
		#env WINEARCH=win32 WINEPREFIX="${wine_dir}" wineboot -i 2>&1
		#/bin/bash


		#sleep 10
		#return 0
		while read line; do
			echo ${line} >> "${wine_log}"
			echo -n .
		done < <(
			env WINEARCH=win32 WINEPREFIX="${wine_dir}" wineboot -r 2>&1
			env WINEARCH=win32 WINEPREFIX="${wine_dir}" wineboot -u 2>&1
			env WINEARCH=win32 WINEPREFIX="${wine_dir}" wineboot -r 2>&1
		)
		echo
}
function tweak_wine_desktop_configs(){
	local target_files="${HOME}/.local/share/applications/wine/Programs"
	while read path; do
		local target_file=$(basename "${path}")
		echo ${HOME} :: Tweaking desktop file \"${target_file}\" .
		sed -i '/^Exec=.*lnk$/s/$/ %f/' "${path}"
	done < <(find "${target_files}" -type f -name "*.desktop" | grep "Word\|Excel\|Power")
	echo
}
function rebuild_wine_menus(){
	while read path; do
		local target_file=$(basename "${path}")
		echo    ${HOME} :: Rebuilding desktop menu entry \"${target_file}\" >> "${wine_log}"
		echo -n ${HOME} :: Rebuilding desktop menu entry \"${target_file}\" .
		while read line; do
			echo ${line} >> "${wine_log}"
			echo -n .
		done < <(env WINEPREFIX="${wine_dir}" wine winemenubuilder.exe "${path}" 2>&1)
		echo
	done < <(find "${wine_lnk}" -type f -name *.lnk)
	echo
}
function reconfigure_wine_reg_files(){
	# fix desktop shortcuts
	local target_files="${HOME}/.local/share/applications"
	echo -n ${HOME} :: Reconfiguring desktop files in \"${target_files}\" .
	while read path; do
		sed -i "s|${wine_home}|${HOME}|g" "${path}"
		echo -n .
	done < <(find "${target_files}" -type f -name *desktop)
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
		wine_log="${HOME}/.logs/wine32_office_install.log"
		wine_dir="${HOME}/${wine_name}"
		wine_tmp="${HOME}/${wine_name}_tmp"
		wine_lnk="${HOME}/${wine_name}/drive_c/users/Public/Start Menu/Programs"
}
function list_users(){
	awk -F: '"file "$6 |& getline D{if(D ~ "directory$" && $3 >= 1000) print $1}' /etc/passwd
}
function xinit_start(){
	local user=$1
	xinit 	/bin/su ${user} -c \
		"/usr/bin/gnome-session --session=gnome-classic" \
		-- :1 vt8 &> /dev/null &
}
function xinit_stop(){
	local user=$1
	#xhost +SI:localuser:${user}
	export DISPLAY=:1
	su ${user} -c "gnome-session-quit --no-prompt"
}
function xinit_run(){
	local user=$1
	#xhost +SI:localuser:${user}
	export DISPLAY=:1
	read -d $'' CMDS << END-OF-CMDS
        	for x in {10..1}; do
        	        echo -n \\\\\$x..
        	        sleep .5
        	done;	echo

		/bin/bash -c $(readlink -f ${BASH_SOURCE})

        	for x in {5..1}; do
        	        echo -n \\\\\$x..
        	        sleep .5
        	done;	echo
END-OF-CMDS
	cat << END-OF-SU | su ${user}
		terminator -m -e "${CMDS}"
END-OF-SU
}
main $@
