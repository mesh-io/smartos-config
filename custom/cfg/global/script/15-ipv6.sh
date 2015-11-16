#!/usr/bin/bash

. /lib/svc/share/smf_include.sh
. /lib/sdc/config.sh

load_sdc_sysinfo
load_sdc_config

# Run through every NIC tag
for tag in ${SYSINFO_Nic_Tags//,/ }; do
	iface=SYSINFO_NIC_${tag}

	# Run through existing tag instance ids
	sdc_config_keys | sed -n "s:${tag}\([0-9]\{1,\}\)_v6_ip:\1:p" | while read instance; do
		v6_ip=CONFIG_${tag}${instance}_v6_ip
		v6_gw=CONFIG_${tag}${instance}_v6_gateway

		# Be sure ip address and gateway exists
		if [[ -z "${!v6_ip}" ]]; then
			break;
		elif [[ "${!v6_ip}" == "autoconf" ]]; then
			ipadm create-addr -t -T addrconf ${!iface}/v6a
			svcadm enable svc:/network/routing/ndp
		elif [[ "${!v6_ip}" == "dhcp" ]]; then
			ipadm create-addr -t -T dhcp ${!iface}/v6d
			svcadm enable svc:/network/routing/ndp
		else
			v6_iponly=$(echo ${!v6_ip} | sed 's:/.*::')
			ipadm create-addr -t -T static ${!v6_ip} ${!iface}/v6s
			svcadm enable svc:/network/routing/ndp

			if [[ -n "${!v6_gw}" ]]; then
				route add -inet6 ${!v6_gw} ${v6_iponly} -interface
				route add -inet6 default ${!v6_gw}
			fi
		fi
	done
done

exit $SMF_EXIT_OK
