#!/bin/bash

##############################################################################
echo Getting relative and absolute path variables
scriptFQFN=$(readlink -nf "${BASH_SOURCE}")
scriptName=$(basename "${scriptFQFN}")
scriptPath=$(dirname  "${scriptFQFN}")
scriptRelativePath=$(dirname "${BASH_SOURCE}")
gitRelativeRootPath=$(git rev-parse --show-cdup)

##############################################################################
echo Setting up initial softlinks
ln -sf ${gitRelativeRootPath}builder .
ln -sf ${gitRelativeRootPath}functions .
ln -sf ${gitRelativeRootPath}defaults .
ln -sf ${gitRelativeRootPath}deploy_ubuntu deploys
ln -sf "${scriptPath}"/preseed .
##############################################################################
echo Linking CORE command templates
ls -1 "${scriptRelativePath}"/CORE.* | while read CORE_FILE; do
	BASE_NAME=$(basename ${CORE_FILE} .template)
	CORE_VER=$(ls -1 "${scriptPath}"/archive/"${BASE_NAME}".v* | sed 's/.*v\([0-9]\+\)$/\1/' | sort -n | tail -1)
	ln -sf "${CORE_FILE}" "${BASE_NAME//CORE./}"
	cp  -f "${CORE_FILE}" "${BASE_NAME//CORE./}".v$(( CORE_VER + 1 ))
done
##############################################################################
echo Copying script templates
ls -1 "${scriptRelativePath}"/scripts_* | while read SCRIPT_FILE; do
	BASE_NAME=$(basename "${SCRIPT_FILE}" .template)
	cp -f "${SCRIPT_FILE}" "${BASE_NAME//scripts_/}"
done
##############################################################################
echo Copying seed template
ls -1 "${scriptRelativePath}"/seed.template | while read SEED_FILE; do
	BASE_NAME=$(basename "${SEED_FILE}" .template)
	cp -f "${SEED_FILE}" "${BASE_NAME}"
done
##############################################################################
echo Linking package lists
ls -1 "${scriptRelativePath}"/packages.*.template | while read PKG_FILE; do
	BASE_NAME=$(basename "${PKG_FILE}" .template)
	ln -sf "${PKG_FILE}" "${BASE_NAME}"
done
##############################################################################
echo Linking Apt-Cache Server and DNS Server Address lists
for ADDRESS_FILE in \
	DNS_SERVER_ADDRESS		\
	APT_CACHE_SERVER_ADDRESS
do
	ln -sf "${scriptRelativePath}"/${ADDRESS_FILE} .
done
##############################################################################
	
exit 0
read -d $'' cfgs << END-OF-LIST
	early_command.sh
	success_command.sh
	common_funcs
END-OF-LIST
for cfg in $cfgs; do [ ! -e ${cfg} ] && cp ../${cfg}.template ${cfg}; done
##############################################################################
echo Copying preseed templates
read -d $'' cfgs << END-OF-LIST
	mint.seed
END-OF-LIST
for cfg in $cfgs; do [ ! -e ${cfg}.preseed ] && cp ../preseed/${cfg}.template ${cfg}; done
##############################################################################
echo Copying CGI templates
read -d $'' cfgs << END-OF-LIST
	success_command.cgi
END-OF-LIST
for cfg in $cfgs; do [ ! -e ${cfg} ] && cp ../${cfg}.template ${cfg}; done
