#!/bin/bash


# SOURCE Dependant Functions
source "$(dirname "${BASH_SOURCE}")/../functions/functions.general.sh"
source "$(dirname "${BASH_SOURCE}")/../functions/functions.test.sh"

# GLOBAL vars; fully qualified script paths and names
BASH_SRCFQFN=$(canonicalpath "${BASH_SOURCE}")
BASH_SRCNAME=$(basename "${BASH_SRCFQFN}")
BASH_SRCDIR=$(dirname "${BASH_SRCFQFN}")

SOURCE_CONFIG_GLOBAL_VARS "/opt/udev/etc/vbox_launcher/config"

LOG='/var/log/vbox_launcher.log'


GET_WINDOW_LIST
