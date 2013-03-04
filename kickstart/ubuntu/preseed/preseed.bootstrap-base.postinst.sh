interactive () {
        local waypoint=$*
        local script="/tmp/interactive.${waypoint}.sh"
	cat << END-OF-INTERACTIVE > "${script}"
# jump to tty6 to display message
exec < /dev/tty6 > /dev/tty6 2> /dev/tty6
chvt 6
echo Welcome to an interatice prompt after waypoint \"${waypoint}\"
echo
/bin/sh
chvt 1
exec < /dev/tty1 > /dev/tty1 2> /dev/tty1
exit 0
END-OF-INTERACTIVE
	/bin/sh "${script}"
}

interactive_01 () { interactive check target; }
interactive_02 () { interactive get mirror info; }
interactive_03 () { interactive pre install hooks; }
interactive_04 () { interactive install base system; }
interactive_05 () { interactive setup dev; }
interactive_06 () { interactive configure apt preferences; }
interactive_07 () { interactive configure apt; }
interactive_08 () { interactive apt update; }
interactive_09 () { interactive post install hooks; }
interactive_10 () { interactive pick kernel; }
interactive_11 () { interactive install kernel; }
interactive_12 () { interactive install extra; }
interactive_13 () { interactive final apt preferences; }
interactive_14 () { interactive cleanup; }
