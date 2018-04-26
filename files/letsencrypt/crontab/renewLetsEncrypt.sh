#!/bin/sh

cd /opt/letsencrypt/
./certbot-auto renew --noninteractive --no-self-upgrade --agree-tos --config /etc/letsencrypt/configs/XXDOMAINXX.conf

if [ $? -ne 0 ]
 then
    ERRORLOG=`tail /var/log/letsencrypt/XXDOMAINXX-letsencrypt.log`
    echo -e "The Let's Encrypt cert has not been renewed! \n \n" $ERRORLOG
else
    nginx -s reload
fi

exit 0
