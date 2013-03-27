#!/bin/builder.sh
skip=( false false false false )
step=1
prefix="setup"
source=http://10.173.119.78/scripts/system-setup/$scriptName

while read import; do
	. "${import}"
done < <(ls -1              "${scriptPath}"/functions.*.sh 2> /dev/null
	 ls -1 "${scriptPath}"/../functions/functions.*.sh 2> /dev/null)

source_app=http://10.173/119.78/packages/Computation/vmd-1.9.1.bin.LINUXAMD64.opengl.tar.gz

function setup_make_Config(){
	desc Setting up default config
	# get vmd


}
