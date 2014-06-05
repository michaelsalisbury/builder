#!/bin/bash
ISO='/ISO/clonezilla-live-20130429-raring-amd64.iso'
MNT='/opt/clonezilla'

if [ -e "${ISO}" ]; then
	if [ -d "${MNT}/iso" ]; then
		mount -t iso9660 "${ISO}" ${MNT}/iso || exit 1
	else
		exit 2
	fi
	if [ -f "${MNT}/iso/live/filesystem.squashfs" ]; then
		mount -t squashfs "${MNT}/iso/live/filesystem.squashfs" ${MNT}/squashfs || exit 3
	else
		exit 4
	fi
	if [ -d "${MNT}/tmp" ]; then
		mount -t aufs -o br=${MNT}/tmp=rw:${MNT}/squashfs=ro none ${MNT}/root || exit 5
	else
		exit 6
	fi
	mount -o bind /proc ${MNT}/root/proc
	mount -o bind /sys  ${MNT}/root/sys
	mount -o bind /dev  ${MNT}/root/dev

	chroot ${MNT}/root clonezilla

	umount ${MNT}/root/proc
	umount ${MNT}/root/sys
	umount ${MNT}/root/dev

	umount ${MNT}/root
	umount ${MNT}/squashfs
	umount ${MNT}/iso
fi
