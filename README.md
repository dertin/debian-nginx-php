# LEMP Stack on Debian

The latest stable versions of software for a LEMP stack on a Debian server are compiled with an optimized configuration for the best performance, speed of response and security.

The basic usage is
```sh
git clone https://github.com/dertin/lemp-stack-debian.git
cd lemp-stack-debian/
chmod +x install.sh
sudo ./install.sh all N
```
## Important:

- You must have a domain address pointing to your server before running the script, so that your HTTPS certificate is configured correctly automatically. If you do not have a domain now, enter the domain you are going to configure later and then manually configure your HTTPS certificate.

- It is recommended to restart the system when the script requests it.
After the system starts, you will manually rerun the script `sudo ./install.sh all N` and skip the steps that have already been installed before restarting the system to continue.


## List of installed programs:

| Program       | Version    |
| ------------- |:----------:|
| openssl       | 1.1.1c     |
| python2       | 2.7.16     |
| python3       | 3.7.3      |
| zlib          | 1.2.11     |
| lz4           | 1.9.1      |
| libssh2       | 1.9.0      |
| nghttp2       | 1.39.1     |
| curl          | 7.65.1     |
| cmake         | 3.14.5     |
| libzip        | 1.5.2      |
| libcrack2     | 2.9.7      |
| libxml2       | 2.9.9      |
| libxslt       | 1.1.33     |
| jemalloc      | 5.2.0      |
| mariadb       | 10.4       |
| php           | 7.3.7      |
| nginx         | 1.16.0     |
| modpagespeed  | 1.13.35.2  |
| letsencrypt   | last       |
| blackfire     | last       |


All collaboration is appreciated, through https://github.com/dertin/lemp-stack-debian/issues

Use at your own risk

[![alt travis-ci](https://travis-ci.org/dertin/lemp-stack-debian.svg?branch=develop)](https://travis-ci.org/dertin/lemp-stack-debian/)
