#!/bin/sh

### Example to add a subdomain to the certificate ###
# sudo certbot certonly --cert-name example.com -d example.com -d www.example.com -d test.example.com [...]

# To force the renewal add the parameter: --force-renewal
certbot renew --noninteractive --agree-tos

if [ $? -ne 0 ]
 then
    ERRORLOG=`tail /var/log/letsencrypt/error-letsencrypt.log`
    echo -e "The Let's Encrypt cert has not been renewed! \n \n" $ERRORLOG
else
    sudo nginx -s reload
fi

exit 0
