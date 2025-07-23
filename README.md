Nginx with PHP on Debian 12.11

This project provides a simple installer that relies on Debian packages rather
than compiling everything from source.  Configuration files for Nginx, PHP and
Certbot are included in the `files` directory and are automatically installed by
`install.sh`.

Clone the repository and run the installer:

```sh
git clone https://github.com/dertin/debian-nginx-php.git
cd debian-nginx-php
chmod +x install.sh
sudo DOMAIN=example.com EMAIL_SUPPORT=admin@example.com ./install.sh
```

The `DOMAIN` and `EMAIL_SUPPORT` environment variables are used to customise the
configuration and to request the initial HTTPS certificate with Certbot.

## Important:

- You must have a domain address pointing to your server before running the script so that your HTTPS certificate can be requested automatically.

- If you change the domain after installation you will need to update the certificate manually with `certbot`.


## List of installed programs:

| Program       | Version    |
| ------------- |:----------:|
| openssl       | 3.5.1     |
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
| mariadb client| 11.8.2     |
| php           | 8.2.x      |
| nginx         | 1.22.x     |
| letsencrypt   | 4.1.1      |
| blackfire     | latest     |

**Note:** The installer relies entirely on Debian packages and no longer compiles these components from source.

All collaboration is appreciated, through https://github.com/dertin/debian-nginx-php/issues

Use at your own risk

[![CircleCI](https://circleci.com/gh/dertin/debian-nginx-php/tree/develop.svg?style=svg)](https://circleci.com/gh/dertin/debian-nginx-php/tree/develop)
