#!/bin/bash

function color(){

	local color=$(echo $1 | tr A-Z a-z)
	shift 1
	local text=$(echo $@)

	[ "${color:0:1}" == "u" ] && { local underline="true"; color=${color:1}; }

	case ${color} in
	black)		color='30m';;	blue)		color='34m';;	brown)		color='33m';;	cyan)		color='36m';;
        darkbrown)	color='1;33m';;	darkgray)	color='1;30m';;	green)		color='32m';;	lightblue)	color='1;34m';;
        lightcyan)	color='1;36m';;	lightgray)	color='37m';;	lightgreen)	color='1;32m';;	lightpurple)	color='1;35m';;
        lightred)	color='1;31m';;	purple)		color='35m';;	red)		color='1;31m';;	white)		color='1;37m';;
        yellow)		color='1;33m';;	*)		return;;
	esac

	[ "${underline}" == "true" ] && color='4;'${color}	
	echo "\e[${color}${text}\e[00m"
}

################################################################################################################
################################################################################################################
LN="--------------------------------------------------------------------------------------------------"
IF=eth0
IP=$(ifconfig | sed -n "/eth0/,/^$/{
				/inet addr/{
					s/.*inet addr://
					s/ Bcast.*//
					p
				}
			}")


PRE="System IP  $IP"
POST=`date`
echo -e `color red ${LN}`
echo -e `color green "System IP"`"  $IP"`color red ${LN:${#PRE} + ${#POST} + 1}` $POST


################################################################################################################
################################################################################################################
echo
echo -e `color red ${LN}`
echo -e `color red -``color green fdisk``color red ${LN:6}`

columnc=(white  green  white   white    white   white   green   white   white   )
justify=(l      l       r       r       r       r       r       r       r)
columns=(5      10      7      7      17      6      10      10      7)
while read line; do
        column=0
        lineColor='none'
        [ -n "`echo $line | sed -n '/Device/p'`" ] && lineColor='red'


        for word in `echo $line`; do
                [ "$lineColor" == "none" ] && columnC=${columnc[$column]} || columnC=$lineColor
                # Modify data here
                [ -n "`echo $word | sed -n '/[0-9]\{4,\}/p'`" ] && word=`printf "%'d\n" $word`
                # Don't modify code below, this prints columns
                whitesp=$(( ${columns[$column]} - ${#word} + 1 ))
                whitesp="`echo $(yes i|head -n${whitesp//-*/1})|sed 's/i//g'`"
                case ${justify[$column]} in
                        l)      echo -ne `color $columnC ${word}`"$whitesp";;
                        r)      echo -ne "$whitesp"`color $columnC ${word}`;;
                esac
                echo -n " "
                let column++
        done
        echo
done < <(fdisk -l 2>&1 | sed -n '/\(dev.sd\)\|\(Device\)/{
                                        s/Disk/DISK/g
                                        s/^/---> /g
                                        s/---> DISK/DISK/g
                                        s/^DISK/\n\nDISK/g
                                        /doesn/d
                                        /Boot/{s/$/\t\tBoot/}
                                        /\*/{s/$/\t\t<>/}
                                        s/Boot/    /
                                        s/\*/ /
					s/Linux swap \/ Solaris/Linux-SWAP/
                                        p
                                }')

################################################################################################################
################################################################################################################

echo
echo -e `color red ${LN}`
echo -e `color red -``color green "System Stats"``color red ${LN:13}`
echo
columnc=(red  white   purple     white   white   white   green   white   white)
justify=(l      r       r       r       r       r       l       r       r)
columns=(7     8       5      11      35      10      10      10      7)
while read line; do
        column=0
        lineColor='none'
        [ -n "`echo $line | sed -n '/CPU/p'`" ] && lineColor='red'
        for word in `echo $line`; do
		[ "$lineColor" == "none" ] && columnC=${columnc[$column]} || columnC=$lineColor
		whitesp=$(( ${columns[$column]} - ${#word} + 1 ))
		whitesp="`echo $(yes i|head -n${whitesp//-*/1})|sed 's/i//g'`"
                case ${justify[$column]} in
                        l)      echo -ne `color $columnC ${word}`"$whitesp";;
                        r)      echo -ne "$whitesp"`color $columnC ${word}`;;
                esac
                echo -n " "
                let column++
        done
        echo
done < <(ps -o pid,time,pcpu,comm,args -C VirtualBox)
#       Modify line above to feed "while read"

################################################################################################################
################################################################################################################

echo 
columnc=(red	white	green	purple	purple	white	white	white	white)
justify=(l	r	r	r	r	r	r	r	r)
columns=(10	2	12	12	12	12	12	12	7)
while read line; do
	column=0
        lineColor='none'
        [ -n "`echo $line | sed -n '/\(mem\)\|\(swp\)/p'`" ] && lineColor='red'
	for word in `echo $line`; do
		[ "$lineColor" == "none" ] && columnC=${columnc[$column]} || columnC=$lineColor
		# Modify data here		
		word=${word//kb/Kb }
		word=${word//\%/\% }
		word=${word//mem/mem }
		word=${word//swp/swp }
		[ -n "`echo $word | sed -n '/[0-9]\{3,\}/p'`" ]	&& word=`printf "%'d\n" $word`
		# Don't modify code below, this prints columns
                whitesp=$(( ${columns[$column]} - ${#word} + 1 ))
                whitesp="`echo $(yes i|head -n${whitesp//-*/1})|sed 's/i//g'`"
                case ${justify[$column]} in
                        l)      echo -ne `color $columnC ${word}`"$whitesp";;
                        r)      echo -ne "$whitesp"`color $columnC ${word}`;;
                esac
		echo -n " "
		let column++
	done
	echo
done < <(sar -S -r 1 1 | grep -vE "Average|Linux|^$")
#	Modify line above to feed "while read"

################################################################################################################
################################################################################################################

echo 
columnc=(red  white   green     white   white   purple   white   white   green)
justify=(l      r       r       r       r       r       r       r       r)
columns=(10     2       10      10      10      10      10      10      7)
while read line; do
        column=0
        lineColor='none'
        [ -n "`echo $line | sed -n '/CPU/p'`" ] && lineColor='red'
        for word in `echo $line`; do
		[ "$lineColor" == "none" ] && columnC=${columnc[$column]} || columnC=$lineColor
                # Modify data here
		word=${word//\%/\% }
                # Don't modify code below, this prints columns
                whitesp=$(( ${columns[$column]} - ${#word} + 1 ))
                whitesp="`echo $(yes i|head -n${whitesp//-*/1})|sed 's/i//g'`"
                case ${justify[$column]} in
                        l)      echo -ne `color $columnC ${word}`"$whitesp";;
                        r)      echo -ne "$whitesp"`color $columnC ${word}`;;
                esac
                echo -n " "
                let column++
        done
        echo
done < <(sar -P ALL 1 1 | grep -vE "Average|all|^$|Linux")
#       Modify line above to feed "while read"

################################################################################################################
################################################################################################################
echo
echo -e `color red --------------------------------------------------------------------------------------------------`
echo




