#!/bin/bash

serviceFiles='/etc/x11vnc/systemd'

find /etc/systemd/system/{x11,X}vnc*.socket -exec basename '{}' ';' |
	sed 's/^/systemctl stop /' |
	bash

find /etc/systemd/system/{x11,X}vnc*.socket -exec basename '{}' ';' |
	sed 's/^/systemctl disable /' |
	bash

find "${serviceFiles}"/*.service -exec ln -sf '{}' /etc/systemd/system/. ';'

systemctl daemon-reload

find "${serviceFiles}"/*.socket -exec systemctl enable '{}' ';'

find "${serviceFiles}"/*.socket -exec basename '{}' ';' |
	sed 's/^/systemctl status /' |
	bash

find "${serviceFiles}"/*.socket -exec basename '{}' ';' |
	sed 's/^/systemctl start /' |
	bash

find "${serviceFiles}"/*.socket -exec basename '{}' ';' |
	sed 's/^/systemctl status /' |
	bash
