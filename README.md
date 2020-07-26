# Nginx with PHP on Debian Stretch

The latest stable versions of software to create a web service platform in Debian Stretch are compiled with a configuration optimized for the best performance, speed of response and security.


To compile the platform you can use the following instructions:
```sh
git clone https://github.com/dertin/debian-nginx-php.git
cd debian-nginx-php/
chmod +x install.sh
sudo ./install.sh all N
```

You can modify the build.json file according to your needs using packer.io
```sh
cd debian-nginx-php/packer
packer build build.json
```

## Important:

- You must have a domain address pointing to your server before running the script, so that your HTTPS certificate is configured correctly automatically. If you do not have a domain now, enter the domain you are going to configure later and then manually configure your HTTPS certificate.

- It is recommended to restart the system when the script requests it.
After the system starts, you will manually rerun the script `sudo ./install.sh all N` and skip the steps that have already been installed before restarting the system to continue.


## List of installed programs:

| Program       | Version    |
| ------------- |:----------:|
| openssl       | 1.1.1g     |
| ~~python2~~   | 2.7.18     |
| python3       | 3.8.5      |
| zlib          | 1.2.11     |
| lz4           | 1.9.2      |
| libssh2       | 1.9.0      |
| nghttp2       | 1.41.0     |
| curl          | 7.71.1     |
| cmake         | 3.18.0     |
| libzip        | 1.7.3      |
| libcrack2     | 2.9.7      |
| libxml2       | 2.9.10     |
| libxslt       | 1.1.34     |
| jemalloc      | 5.2.1      |
| mariadb client| 10.4       |
| php           | 7.4.8      |
| nginx         | 1.19.1     |
| modpagespeed  | 1.13.35.2  |
| letsencrypt   | last       |
| blackfire     | last       |


All collaboration is appreciated, through https://github.com/dertin/debian-nginx-php/issues

Use at your own risk

[![alt travis-ci](https://travis-ci.org/dertin/debian-nginx-php.svg?branch=develop)](https://travis-ci.org/dertin/debian-nginx-php/)
