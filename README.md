# LEMP stack on a Debian server

The latest stable versions of software for a LEMP stack on a Debian server are compiled with an optimized configuration for the best performance, speed of response and security.

The basic usage is
```sh
git clone https://github.com/dertin/lemp-stack-debian.git
cd lemp-stack-debian/
chmod +x install.sh
sudo ./install.sh all
```

You must have a domain address before executing the script, so that your https certificate is correctly configured automatically. If you do not have a domain now, enter the domain you are going to buy later, and then manually configure your https certificate.

List of installed programs:

| Program       | Version    |
| ------------- |:----------:|
| openssl       | 1.1.0h     |
| python2       | 2.7.15     |
| zlib          | 1.2.11     |
| lz4           | 1.8.1.2    |
| libssh2       | 1.8.0      |
| nghttp2       | 1.32.0     |
| curl          | 7.61.0     |
| cmake         | 3.12.0     |
| libzip        | 1.5.1      |
| libcrack2     | 2.9.6      |
| libxml2       | 2.9.8      |
| libxslt       | 1.1.33-rc1 |
| jemalloc      | 5.1.0      |
| mariadb       | 10.2.14    |
| php           | 7.2.8      |
| nginx         | 1.15.2     |
| letsencrypt   | last       |
| blackfire     | last       |


All collaboration is appreciated, through https://github.com/dertin/lemp-stack-debian/issues

Use at your own risk

[![alt travis-ci](https://travis-ci.org/dertin/lemp-stack-debian.svg?branch=develop)](https://travis-ci.org/dertin/lemp-stack-debian/)
