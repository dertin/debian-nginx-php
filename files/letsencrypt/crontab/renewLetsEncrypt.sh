#!/bin/sh

### Example to add a subdomain to the certificate ###
# sudo ./certbot-auto certonly --cert-name example.com -d example.com -d www.example.com -d test.example.com [...]

cd /opt/letsencrypt/
# To force the renewal add the parameter: --force-renewal
# and add --config /etc/letsencrypt/configs/example.conf
./certbot-auto renew --noninteractive --no-self-upgrade --agree-tos

if [ $? -ne 0 ]
 then
    ERRORLOG=`tail /var/log/letsencrypt/error-letsencrypt.log`
    echo -e "The Let's Encrypt cert has not been renewed! \n \n" $ERRORLOG
else
    sudo nginx -s reload
fi

exit 0
