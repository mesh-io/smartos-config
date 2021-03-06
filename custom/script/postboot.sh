#!/usr/bin/bash

## Load configuration information from USBKey
. /lib/svc/share/smf_include.sh
. /lib/sdc/config.sh

load_sdc_sysinfo
load_sdc_config

## Set the PATH environment because of other commands in /usr
PATH=/usr/bin:/usr/sbin:${PATH}

## Local variables
cfg='/opt/custom/cfg'

## Functions
function deploy() {
	folder="${cfg}/${1}"

	if [[ -d "${folder}" ]]; then
		# Set 755 permissions for /root folder (must have 755 for ssh)
	        [[ -d "${folder}/root/root/" ]] && chmod 755 "${folder}/root/root/"

		# Copy all files from the root-folder
		[[ -d "${folder}/root" ]] && cp -a "${folder}/root/"* /

		# Run all scripts from the script-folder
		if [[ -d "${folder}/script" ]]; then
			for script in "${folder}/script/"*; do
				[[ -x "${script}" ]] && ./${script}
			done
		fi

		# Deploy cronjobs
		[[ -d "${folder}/crontab" ]] && cat "${folder}/crontab/"* | crontab
	fi
}

## Deploy global configuration
deploy "global"

## Deploy datacenter configuration
deploy "datacenter/${SYSINFO_Datacenter_Name}"

## Deploy host configuration
deploy "host/${SYSINFO_Hostname}"

exit $SMF_EXIT_OK
