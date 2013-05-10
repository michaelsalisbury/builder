#!/bin/builder.sh

# IMPORTANT: Includes must be placed before global variables like "skip" & "step"
while read import; do
        source <(sed '1,/^function/{/^function/p;d}' "${import}")
done < <(ls -1              "${scriptPath}"/functions.*.sh 2> /dev/null
	 ls -1 "${scriptPath}"/../functions/functions.*.sh 2> /dev/null)

# GLOBAL VARIABLES
skip=( false false false false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/system-setup/$scriptName

source_app=http://10.173.119.78/packages/Computation/vmd-1.9.1.bin.LINUXAMD64.opengl.tar.gz

function setup_make_Config(){
	desc Setting up default config
	# install dependencies for OPENGL FLTK TK NETCDF TCL
	apt-get -y install \
			libfltk1.3 libfltk1.3-dev libfltk-*1.3 \
			tcl tcl-dev \
			tk  tk-dev \
			netcdf* libnetcdf*

	# get vmd
	mkdir /opt/vmd
	cd    /opt/vmd
	local       source_app_file=$(basename "${source_app}")
	rm -f    "${source_app_file}"
	wget     "${source_app}"
	tar -zxf "${source_app_file}"
	local       source_app_path=$(find ./* -maxdepth 0 -type d -cmin 1)

	# setup vmd
	cd "${source_app_path}"
	./configure LINUXAMD64 OPENGL FLTK TK NETCDF TCL
	cd src
	make install
}
