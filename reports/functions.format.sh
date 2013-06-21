#!/bin/bash

# FUNCTIONS
# SET_MAX_WIDTH_BY_COLS
# REPC
# PAD_ANCHOR_CNTR_R
# PAD_ANCHOR_CNTR_L
# PAD_ANCHOR_R
# PAD_ANCHOR_L

# GLOBAL ENVIRONMENTAL VARS; MAX_WIDTH
MAX_WIDTH_DEFAULT=90
SPLIT_DELIM_DEFAULT=\-

function SET_MAX_WIDTH_BY_COLS(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT}}
	# set GLOBAL vars; COLUMNS, LINES
	source <(resize)
	MAX_WIDTH=`tput cols 2>/dev/null`
	MAX_WIDTH=${MAX_WIDTH:-${width}}
}
function REPC(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT}}
	# manditory pad character
	local pad_chr=$(PAD_CHR_TR "$1")
	# return
	cat <<-SED | sed -n -f <(cat) <(seq ${width})
		s/.*/${pad_chr}/			# swap count for pad_chr 
		H					# append pad_chr to hold buffer
		\${					# at last line do
			x				# swap hold buffer to pattern space
			s/\n//g				# remove all new-line chars
			s/\(.\{${width}\}\).*/\1/	# capture the correct num od chars
			p				# print
		}
	SED
	####################################################### alternate
	# fill pad_chr to width
	#pad_chr=$(seq ${width} | sed "s/.*/${pad_chr}/" | tr -d "\n")
	# return
	#echo "${pad_chr:0:${width}}"
}
function PAD_SPLIT(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT}}
	# manditory pad character
	local pad_chr=$(PAD_CHR_TR "$1")
	shift
	
	# set split_chr; optional
	local split_delim="${1}"
	(( ${#split_delim} == 2 )) && [ "${split_delim:0:1}" == "${SPLIT_DELIM_DEFAULT}" ] \
		&& split_delim=${split_delim:1:1} && shift\
		|| split_delim=${SPLIT_DELIM_DEFAULT}

	# set right and left text entries
	local  left=$(echo "$@" | sed "s/\(.*\)[[:space:]]${split_delim}[[:space:]].*/\1/")
	local right=$(echo "$@" | sed "s/.*[[:space:]]${split_delim}[[:space:]]\(.*\)/\1/")

	# add leading or trailing spaces
	[ "${pad_chr}" != "${right:0:1}" ] && right=" ${right}"
	[ "${pad_chr}" != "${left: -1}" ] && left="${left} "
	
	# fill with repeating chars
	pad_chr=$(REPC $(( width - ${#left} - ${#right} )) "${pad_chr}")

	# prep return
	local line="${left}${pad_chr}${right}"

	# return
	echo "${line:0:${width}}"
}
function PAD_ANCHOR_CNTR_SPLIT(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT}}
	# manditory pad character; split chr is optional and values are comma sperated
	local   pad_chr=( ${1//,/ } )
	local split_chr=${pad_chr[1]:-  ${pad_chr}}
	local   pad_chr=$(PAD_CHR_TR   "${pad_chr}")
	local split_chr=$(PAD_CHR_TR "${split_chr}")
	shift

	echo pad_chr :: $pad_chr
	echo split_chr :: $split_chr

	# manditory split ratio entry; split width is minimal
	#    [split width #char|split width %char]
	#    [split width #char|split width %char],[left width #char|left width %char]
	local split_width=( ${1//,/ } )
	[ "${split_width: -1}" == "%" ] \
		&& split_width=$(( width * ${split_width:0:-1} / 100 ))
	local left_width=${split_width[1]:-$(( ( width - split_width ) / 2 ))}
	[ "${left_width: -1}" == "%" ] \
		&& left_width=$(( width * ${left_width:0:-1} / 100 ))
	shift

	# set right_width
	local right_width=$(( width - split_width - left_width ))

	echo split_width :: $split_width
	echo right_width :: $right_width
	echo left_width :: $left_width

	# set split_chr; optional
	local split_delim="${1}"
	(( ${#split_delim} == 2 )) && [ "${split_delim:0:1}" == "${SPLIT_DELIM_DEFAULT}" ] \
		&& split_delim=${split_delim:1:1} && shift\
		|| split_delim=${SPLIT_DELIM_DEFAULT}

	echo split_delim :: $split_delim

	# set right and left text entries
	local  left=$(echo "$@" | sed "s/\(.*\)[[:space:]]${split_delim}[[:space:]].*/\1/")
	local right=$(echo "$@" | sed "s/.*[[:space:]]${split_delim}[[:space:]]\(.*\)/\1/")

	# pad right and left text entries
	local  left=$(PAD_ANCHOR_R ${left_width}  "${pad_chr}" "${left}")
	local right=$(PAD_ANCHOR_L ${right_width} "${pad_chr}" "${right}")

	# pad center text entry
	if [ "${pad_chr}" != "${split_chr}" ]; then
		split_chr=$(PAD_CNTR ${split_width} " " "${split_chr}")
	else
		# check for matching left or right text char and add buffer spaces
		split_chr=$(REPC ${split_width} "${pad_chr}")
		[ "${pad_chr}" == "${right:0:1}" ] \
			&& split_chr=$(sed "s/./ /${split_width}" <(echo "${split_chr}"))
		[ "${pad_chr}" == "${left: -1}"  ] \
			&& split_chr=$(sed 's/./ /' <(echo "${split_chr}"))

	fi

	# return
	echo "${left}${split_chr}${right}"
}
function PAD_ANCHOR_CNTR_R(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT}}
	# manditory pad character
	local pad_chr=$(PAD_CHR_TR "$1")
	shift
	# text to center
	local line="$@"

	# center shift space var
	local space=0

	# add leading or trailing spaces
	[ "${pad_chr}" != "${line:0:1}" ] && line=" ${line}" && space=1
	[ "${pad_chr}" != "${line: -1}" ] && line="${line} "

	# fill with repeating chars
	pad_chr=$(REPC $(( width / 2 - space )) "${pad_chr}")

	# prep return
	line="${pad_chr}${line}${pad_chr}"

	# return
	echo "${line:0:${width}}"
}
function PAD_ANCHOR_CNTR_L(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT}}
	# manditory pad character
	local pad_chr=$(PAD_CHR_TR "$1")
	shift
	# text to center
	local line="$@"

	# center shift space var
	local space=0

	# add leading or trailing spaces
	[ "${pad_chr}" != "${line:0:1}" ] && line=" ${line}"
	[ "${pad_chr}" != "${line: -1}" ] && line="${line} " && space=1

	# prep line
	line=$(PAD_ANCHOR_R $(( width / 2 + space )) "${pad_chr}" "${line}")
	
	# fill with repeating chars
	pad_chr=$(REPC ${width} "${pad_chr}")

	# prep return
	line="${line}${pad_chr}"
	
	# return
	echo "${line:0:${width}}"
}
function PAD_CHR_TR(){
	case "$1" in
		-s)	echo \ ;;	
		-e)	echo \=;;
		-p)	echo \|;;		
		-t)	echo \~;;
		*)	echo "$1";;
	esac
}
function PAD_CNTR(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT}}
	# manditory pad character
	local pad_chr=$(PAD_CHR_TR "$1")
	shift
	# text to center
	local line="$@"

	# add leading or trailing spaces
	[ "${pad_chr}" != "${line: -1}" ] && (( width > ${#line} )) && line="${line} "
	[ "${pad_chr}" != "${line:0:1}" ] && (( width > ${#line} )) && line=" ${line}"

	# determine if integers are even or odd
	local width_is_odd=$(( width == width / 2 * 2 ))
	local line_is_odd=$(( ${#line} == ${#line} / 2 * 2 ))

	# add trailing fillchar if nessisary
	(( width_is_odd != line_is_odd )) && (( width > ${#line} )) && line+=${pad_chr}

	# calculate pad_chr wing length
	width=$(( ( width - ${#line} ) / 2 ))

	# fill with repeating chars
	pad_chr=$(REPC ${width} "${pad_chr}")

	# return
	echo "${pad_chr}${line}${pad_chr}"
}
function PAD_ANCHOR_R(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT}}
	# manditory pad character
	local pad_chr=$(PAD_CHR_TR "$1")
	shift
	# text to anchor right
	local line="$@"
	# add buffer space between text and pad chars if first text char is diff
	[ "${pad_chr}" != "${line:0:1}" ] && line=" ${line}"
	# setup pad_char string
	pad_chr=$(REPC ${width} "${pad_chr}")
	# pre-pend pad chars
	line="${pad_chr}${line}"
	# return
	echo "${line: -${width}}"
}
function PAD_ANCHOR_L(){
	# is first arg a positive integer
	[[ $1 =~ ^[0-9]+ ]] \
		&& { local width=$1 && shift; } \
		|| local width=${MAX_WIDTH:-${MAX_WIDTH_DEFAULT}}
	# manditory pad character
	local pad_chr=$(PAD_CHR_TR "$1")
	shift
	# text to anchor right
	local line="$@"
	# add buffer space between text and pad chars if last text char is diff
	[ "${pad_chr}" != "${line: -1}" ] && line="${line} "
	# setup pad_char string
	pad_chr=$(REPC ${width} "${pad_chr}")
	# apend pad chars
	line="${line}${pad_chr}"
	# return
	echo "${line:0:${width}}"
}

