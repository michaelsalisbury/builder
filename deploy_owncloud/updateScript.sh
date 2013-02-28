#!/bin/bash
wget	--recursive				\
	--timestamping				\
	--no-directories			\
	--level 1				\
	--cut-dirs 1				\
	--accept sh,sql,conf			\
	--directory-prefix /etc/owncloud        \
	http://10.173.119.78/packages/owncloud	\
	2>&1					\
	| sed '/index/d;/\(not\|saved\)/!d;s/--.*//'

chmod 755 /etc/owncloud/*
