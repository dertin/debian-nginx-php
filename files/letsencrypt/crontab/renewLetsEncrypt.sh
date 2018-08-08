#!/bin/sh

# sudo /etc/letsencrypt/crontab/grupolfmedia.com-renewLetsEncrypt.sh

cd /opt/letsencrypt/
# To force the renewal add the parameter: --force-renewal
./certbot-auto renew --noninteractive --no-self-upgrade --agree-tos --config /etc/letsencrypt/configs/XXDOMAINXX.conf

if [ $? -ne 0 ]
 then
    ERRORLOG=`tail /var/log/letsencrypt/XXDOMAINXX-letsencrypt.log`
    echo -e "The Let's Encrypt cert has not been renewed! \n \n" $ERRORLOG
else
    sudo nginx -s reload
fi

exit 0

### Example to add a subdomain to the certificate ###
# sudo ./certbot-auto certonly --cert-name domain.com -d domain.com -d www.domain.com -d test.domain.com [...]
