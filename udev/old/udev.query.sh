#!/bin/bash

scriptName="$(basename $BASH_SOURCE)"
scriptPath="$(cd `dirname  $BASH_SOURCE`; pwd)"

username=$(whoami)
userhome="$(cat /etc/passwd | grep $username | cut -f6 -d:)"

disk=$1
jobdetails="${userhome}/.VirtualBox/jobDetails.$disk"
mem=256

  spinrite="$userhome/ISO/SpinRite.iso"
      dban="$userhome/ISO/dban-2.2.6_i586.iso"
ubuntu1010="$userhome/ISO/ubuntu-10.10-desktop-amd64.iso"
ubuntu1104="$userhome/ISO/ubuntu-11.04-desktop-amd64.iso"
   knoppix="$userhome/ISO/ADRIANE-KNOPPIX_V6.4.3CD-2010-12-20-EN.iso"
    hirens="$userhome/ISO/Hirens.BootCD.14.0.iso"
     ghost="$userhome/ISO/ghost.iso"

  spinrite="$userhome/Data/ISO.BootableUSB/SpinRite.iso"
      dban="$userhome/Data/ISO.BootableUSB/dban-2.2.6_i586.iso"
ubuntu1010="$userhome/Data/ISO.Linux/Ubuntu/ubuntu-10.10-desktop-amd64.iso"
ubuntu1104="$userhome/Data/ISO.Linux/Ubuntu/ubuntu-11.10-desktop-amd64.iso"
   knoppix="$userhome/Data/ISO.Linux/KNOPPIX/ADRIANE-KNOPPIX_V6.7.0CD-2011-08-01-EN.iso"
    hirens="$userhome/Data/ISO.BootableUSB/Hirens.BootCD.14.0.iso"
     ghost="$userhome/Data/ISO.Misc/ghost.big-Z9-SURE-AUTO.iso"

function color(){

        local color=$(echo $1 | tr A-Z a-z)
        shift 1
        local text=$(echo $@)

        [ "${color:0:1}" == "u" ] && { local underline="true"; color=${color:1}; }

        case ${color} in
        black)          color='30m';;   blue)           color='34m';;   brown)          color='33m';;   cyan)           color='36m';;
        darkbrown)      color='1;33m';; darkgray)       color='1;30m';; green)          color='32m';;   lightblue)      color='1;34m';;
        lightcyan)      color='1;36m';; lightgray)      color='37m';;   lightgreen)     color='1;32m';; lightpurple)    color='1;35m';;
        lightred)       color='1;31m';; purple)         color='35m';;   red)            color='1;31m';; white)          color='1;37m';;
        yellow)         color='1;33m';; *)              return;;
        esac

        [ "${underline}" == "true" ] && color='4;'${color}
        echo "\e[${color}${text}\e[00m"
}


echo -e "         Please enter a unique name to detail this disk : $(color green ${disk})          "
echo -e " $(color red \(no spaces or special characters, dashes and underscores are OK\))"
echo
echo -n " > "
read name
echo
echo    "         Please choose a boot selection by number                          "
echo    " (bad selections or no selection defaults to the first choice)" 
echo
echo -e " $(color red 1:) SpinRite"
echo -e " $(color red 2:) Darik's Boot And Nuke (DBAN)"
echo -e " $(color red 3:) Drive Backup; Ghost"
echo -e	" $(color red 4:) Linux Deploy; Ubuntu 10.10"
echo -e	" $(color red 5:) Linux Deploy; Ubuntu 11.04"
echo -e " $(color red 6:) Linux Diag; Knoppix"
echo -e " $(color red 7:) WinPE Diag; Hirens BootCD"
echo
echo -n " > "
read isonum
echo
echo    " Thankyou"
echo
case $isonum in
        1)      iso="${spinrite}"	;;
	2)	iso="${dban}"		;;
	3)	iso="${ghost}"		
		mem=512			;;
	4)	iso="${ubuntu1010}"	;;
	5)	iso="${ubuntu1104}"	;;
	6)	iso="${knoppix}"	;;
	7)	iso="${hirens}"		;;
	*)	iso="${spinrite}"	;;
esac

echo "name=$name" > "${jobdetails}"
echo "iso=$iso"  >> "${jobdetails}"
echo "jobp=$2"   >> "${jobdetails}"
echo "mem=$mem"  >> "${jobdetails}"

for x in $(seq 3 -1 1); do echo -n $x.; sleep 1; done

