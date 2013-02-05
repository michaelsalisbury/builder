#!/bin/builder.sh
skip=( true false false false true true false false false true false false )
step=1
prefix="setup"
source=http://192.168.248.24/config/$scriptName

rootfsS="runonce-12.10_Live.sh"
sourceI="/export/ubuntu-12.10-desktop-amd64.iso"
liveISO="/export/ubuntu-12.10-just_vbox.iso"
isoDesc="01234567890123456789012345678901"
isoDesc="Ubuntu 12.10+ x64 Just VBox"
workDir="${HOME}/uck-just_vbox"
scriptD="${workDir}/customization-scripts"
initrdD="${workDir}/remaster-initrd"
   isoD="${workDir}/remaster-iso"


function networkUpMsg(){ echo Network Up, Internet Accessible + DNS Responding.; }

function setup_Prep(){
	desc Setup-UP Working Directory:  Unmount, Clean \& Prep
	if [ -e "${workDir}" ]; then
		cat /etc/mtab | grep "${workDir}" | cut -f2 -d\ | sed 's|^|sudo umount |' | bash
		cat /etc/mtab | grep "${workDir}" | cut -f2 -d\ | sed 's|^|sudo umount |' | bash
		sudo uck-remaster-clean-all "${workDir}"
		sudo rm -rf                 "${workDir}"
	fi
		mkdir -p "${scriptD}"
}
function setup_Unpack_ISO(){
	desc Unpack ISO
	#time sudo uck-remaster-unpack-iso "${sourceI}" "${workDir}"
	time sudo uck-remaster-unpack-iso -m "${sourceI}" "${workDir}"
}
function setup_Modify_ISO(){
	desc Modify ISO\; isolinux/\{txt.cfg isolinux.cfg gfxboot.cfg lang\}
	modify_isolinux_isolinux
	modify_isolinux_gfxboot
	modify_isolinux_txt
	modify_isolinux_lang
}
function setup_Unpack_initrd(){
	desc Unpack initrd
	time sudo uck-remaster-unpack-initrd "${workDir}"
}
function setup_Modify_initrd(){
	desc Modify initrd\; /etc/casper.conf
	sudo sed -i '/export FLAVOUR/s/.*/export FLAVOUR="Ubuntu"/' "${initrdD}/etc/casper.conf"
	sudo cat                                                    "${initrdD}/etc/casper.conf"
}
function setup_Unpack_rootfs(){
	desc Unpack rootfs
	time sudo uck-remaster-unpack-rootfs "${workDir}"
}
function setup_Update_Scripts(){
	desc Update scripts\; builder.sh ${source%/*}/${rootfsS}
	waitForNetwork && networkUpMsg || return 1
	mkdir -p  "${scriptD}"
	chmod 777 "${scriptD}"
	cd        "${scriptD}"
	rm -f                "builder.sh"
	wget -q "${source%/*}/builder.sh"
	chmod +x             "builder.sh"
	rm -f                "${rootfsS}"
	wget -q "${source%/*}/${rootfsS}"
	chmod +x             "${rootfsS}"
}
function setup_Modify_rootfs(){
	desc Modify rootfs\; ${rootfsS}
	cd "${scriptD}"
	[ ! -x "builder.sh" ] && echo builder.sh missing\! && return 1
	[ ! -x "${rootfsS}" ] && echo ${rootfsS} missing\! && return 1
	local cmd="prep.sh"
	touch                      "${cmd}"
	chmod +x                   "${cmd}"
	cat << END-OF-SCRIPT >     "${cmd}"
#!/bin/bash
	echo .........................................................
	cd /tmp/customization-scripts/
	cp -vf "${rootfsS}" /root/.
	cp -vf builder.sh    /bin/.
	echo Done with prep script
	echo .........................................................
	/root/"${rootfsS}"
END-OF-SCRIPT
	sudo uck-remaster-chroot-rootfs "${workDir}" "/tmp/customization-scripts/${cmd}"
}
function setup_Repack_initrd(){
	desc Repack initrd
	time sudo uck-remaster-pack-initrd "${workDir}"
}
function setup_Repack_rootfs(){
	desc Repack rootfs
	time sudo uck-remaster-pack-rootfs "${workDir}"
}
function setup_Repack_ISO(){
	desc Repack ISO
	time sudo uck-remaster-pack-iso "${liveISO}" "${workDir}" -d "${isoDesc}"
	sudo chown `whoami`        "${liveISO}"
	sudo chgrp `whoami`        "${liveISO}"
}

function modify_isolinux_lang(){
	local file="${isoD}/isolinux/lang"
	echo en_US | sudo tee "$file"
}
function modify_isolinux_gfxboot(){
	local file="${isoD}/isolinux/gfxboot.cfg"
	sudo sed -i '/hidden-timeout/s/^/#/' "$file"
}
function modify_isolinux_isolinux(){
	local file="${isoD}/isolinux/isolinux.cfg"
	local mod=`cat << END-OF-SED
		/^prompt/cprompt 1
		/^timeout/ctimeout 100
END-OF-SED
`
	sudo sed -i "$mod" "$file"
}
function modify_isolinux_txt(){
	#http://en.wikipedia.org/wiki/VESA_BIOS_Extensions#Linux_video_mode_numbers
	#VGA mode chart
	#Form Factor	4x3	4x3	 4x3	  4x3	    4x3	      4x3	4x3	   16x10    16x10    16x10
	#Colour depth	800x600	1024x768 1152x864 1280x1024 1400x1050 1600x1200 1920x1200  1280x800 1440x900 1680x1050
	#8 (256)	771	773	 353	  775	    835	      796/800	893	   	    864
	#15 (32K)	787	790	 354	  793		      797/801		   	    865
	#16 (65K)	788	791	 355	  794	    837	      798/802	           868	    866      865
	#24 (16M)	789	792	 ?	  795	    838	      799/803	           869	    867      866
	#32				 356	  829		          834		            868
	local file="${isoD}/isolinux/txt.cfg"
	local mod1=`cat << END-OF-SED
	        /^label live$/,/append/{
	                /^label/h
	                /^label/!H
	                /^label/clabel CLI
	                /menu/c\  menu label ^Command Line wo/ GUI Desktop
	                /append/{
	                        s/ quiet//
	                        s/ splash//
	                        s/ --/ text noplymouth --/
				s/ --/ vga=790 --/
	                        G
	                }
	        }
END-OF-SED
`
	local mod2=`cat << END-OF-SED
	        /^label live$/,/append/{
	                /^label/h
	                /^label/!H
	                /^label/clabel loud
	                /menu/c\  menu label ^Live Desktop w/ Boot Messages
	                /append/{
	                        s/ quiet//
	                        s/ splash//
	                        s/ --/ noplymouth --/
				s/ --/ vga=790 --/
	                        G
	                }
	        }
END-OF-SED
`
	sudo sed -i '/^default/cdefault CLI' "$file"
	sudo sed -i "$mod1"                  "$file"
	sudo sed -i "$mod2"                  "$file"
}




