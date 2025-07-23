Nginx with PHP on Debian 12.11

This project provides a simple installer that relies on Debian packages rather
than compiling everything from source.  Configuration files for Nginx, PHP and
Certbot are included in the `files` directory and are automatically installed by
`install.sh`.

Clone the repository and run the installer. The script configures the official
nginx repository and the Sury PHP repository so the latest stable versions
of nginx and PHP 8.4 can be installed on Debian 12.11:

```sh
git clone https://github.com/dertin/debian-nginx-php.git
cd debian-nginx-php
chmod +x install.sh
sudo DOMAIN=example.com EMAIL_SUPPORT=admin@example.com ./install.sh
```

The `DOMAIN` and `EMAIL_SUPPORT` environment variables are used to customise the
configuration and to request the initial HTTPS certificate with Certbot.

When running in CI (or when the environment variable `POLICY_BLOCK=1` is set)
the installer creates a `/usr/sbin/policy-rc.d` symlink protected with
`dpkg-divert`. This prevents services from starting automatically. You can
verify it exists with:

```sh
sudo ls -l /usr/sbin/policy-rc.d
sudo head -n2 /usr/sbin/policy-rc.d
```

## Important:

- You must have a domain address pointing to your server before running the script so that your HTTPS certificate can be requested automatically.

- If you change the domain after installation you will need to update the certificate manually with `certbot`.


## List of installed programs:

| Program       | Version    |
| ------------- |:----------:|
| php           | 8.4.x      |
| nginx         | 1.28.x     |
| mariadb client| 11.8.2     |
| certbot       | 2.1.0      |

**Note:** The installer relies entirely on Debian packages and no longer compiles these components from source.

All collaboration is appreciated, through https://github.com/dertin/debian-nginx-php/issues

Use at your own risk

[![CircleCI](https://circleci.com/gh/dertin/debian-nginx-php/tree/develop.svg?style=svg)](https://circleci.com/gh/dertin/debian-nginx-php/tree/develop)
