Nginx with PHP on Debian 12.11

The latest stable versions of software to create a web service platform in Debian 12.11 are compiled with a configuration optimized for the best performance, speed of response and security.


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
| openssl       | 3.5.1     |
| ~~python2~~   | 2.7.18     |
| python3       | 3.12.3      |
| zlib          | 1.3.1      |
| lz4           | 1.10.0     |
| libssh2       | 1.11.1     |
| nghttp2       | 1.66.0     |
| curl          | 8.15.0     |
| cmake         | 4.0.3     |
| libzip        | 1.11.4     |
| libcrack2     | 2.10.3     |
| libxml2       | 2.11.9     |
| libxslt       | 1.1.43     |
| mimalloc      | 3.1.5      |
| mariadb client| 11.8.2     |
| php           | 8.4.10      |
| nginx         | 1.28.0     |
| letsencrypt   | 4.1.1      |
| blackfire     | latest     |

**Note:** The deprecated jemalloc library was removed and this stack now links against mimalloc 3.1.5 by default.

All collaboration is appreciated, through https://github.com/dertin/debian-nginx-php/issues

Use at your own risk

[![alt travis-ci](https://travis-ci.org/dertin/debian-nginx-php.svg?branch=develop)](https://travis-ci.org/dertin/debian-nginx-php/)
