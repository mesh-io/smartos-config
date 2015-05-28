#!/usr/bin/bash

## Load configuration information from USBKey
. /lib/svc/share/smf_include.sh
. /lib/sdc/config.sh

load_sdc_sysinfo
load_sdc_config

## Set the PATH environment because of other commands in /usr
PATH=/usr/bin:/usr/sbin:${PATH}

## Sendmail configuration for SmartHost setup
if [[ ${CONFIG_mail_smarthost} ]]; then
	sed -i "s:^DS$:DS[${CONFIG_mail_smarthost}]:g" /etc/mail/submit.cf
	sed -i "s:^DS$:DS[${CONFIG_mail_smarthost}]:g" /etc/mail/sendmail.cf
fi

## Possibility to modify the sender domian name, default FQDN
if [[ ${CONFIG_mail_sender_domain} ]]; then
	sed -i "s:#Dj.*:Dj${CONFIG_mail_sender_domain}:g" /etc/mail/submit.cf
	sed -i "s:#Dj.*:Dj${CONFIG_mail_sender_domain}:g" /etc/mail/sendmail.cf
fi

if [[ ${CONFIG_mail_auth_user} ]]; then
	echo 'AuthInfo:'${CONFIG_mail_smarthost}' "U:'${CONFIG_mail_auth_user}'" "I:'${CONFIG_mail_auth_user}'" "P:'${CONFIG_mail_auth_pass}'"' \
		> /etc/mail/default-auth-info
	echo -e 'Kauthinfo hash /etc/mail/default-auth-info
O AuthMechanisms=EXTERNAL GSSAPI DIGEST-MD5 CRAM-MD5 LOGIN PLAIN
Sauthinfo
R$*\t\t\t$: <$(authinfo AuthInfo:$&{server_name} $: ? $)>
R<?>\t\t$: <$(authinfo AuthInfo:$&{server_addr} $: ? $)>
R<?>\t\t$: <$(authinfo AuthInfo: $: ? $)>
R<?>\t\t$@ no               no authinfo available
R<$*>\t\t$# $1' \
	| tee -a /etc/mail/sendmail.cf >> /etc/mail/submit.cf
	makemap hash /etc/mail/default-auth-info < /etc/mail/default-auth-info
	chgrp smmsp /etc/mail/default-auth-info.db
fi

## Redirect all root emails to admin address
if [[ ${CONFIG_mail_adminaddr} ]]; then
	echo "root: ${CONFIG_mail_adminaddr}" >> /etc/mail/aliases
	newaliases
fi

## Refresh the configuration
if [[ ${CONFIG_mail_smarthost} || ${CONFIG_mail_sender_domain} ]]; then
	svcadm refresh sendmail-client
	svcadm refresh sendmail
fi

exit $SMF_EXIT_OK
