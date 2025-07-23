#!/usr/bin/env bash
set -euo pipefail

# Installs and configures packages on Debian 12.11 using the distribution
# repositories.  Service configuration files bundled with this repository are
# copied into place and customised with the DOMAIN and EMAIL_SUPPORT environment
# variables.

# non interactive apt
export DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-noninteractive}
shopt -s expand_aliases
alias apt-get='/usr/bin/apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"'

# Optimization flags used if compiling any component
export CFLAGS="-march=native -O2 -pipe"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib"
export LIBS="-ldl"


install_policy_block() {
  if ! dpkg-divert --list | grep -q '/usr/sbin/policy-rc.d'; then
    mkdir -p /usr/local/sbin
    cat <<'EOF' >/usr/local/sbin/policy-rc.block
#!/bin/sh
exit 101
EOF
    chmod 755 /usr/local/sbin/policy-rc.block
    dpkg-divert --add --local --rename \
      --divert /usr/sbin/policy-rc.d.real /usr/sbin/policy-rc.d
    ln -sf /usr/local/sbin/policy-rc.block /usr/sbin/policy-rc.d
  fi
}

setup_apt() {
  if [ -n "${CI:-}" ] || [ "${POLICY_BLOCK:-}" = "1" ]; then
    install_policy_block
  fi
  if [ ! -f /etc/apt/sources.list ]; then
    cat <<'EOL' >/etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib non-free-firmware
deb-src http://deb.debian.org/debian bookworm main contrib non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free-firmware
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free-firmware
deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free-firmware
deb http://deb.debian.org/debian bookworm-backports main contrib non-free-firmware
deb-src http://deb.debian.org/debian bookworm-backports main contrib non-free-firmware
EOL
  fi

  if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    mv /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian.sources.disabled
  fi

  sed -i '/^#\s*deb-src /s/^#//' /etc/apt/sources.list
  apt-get update
  apt-get -y upgrade

  # PHP 8.4 from sury repository
  if [ ! -f /etc/apt/sources.list.d/php.list ]; then
    apt-get install -y wget lsb-release gnupg
    wget -qO - https://packages.sury.org/php/apt.gpg | \
      gpg --dearmor -o /usr/share/keyrings/php-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/php-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" \
      >/etc/apt/sources.list.d/php.list
  fi

  # Latest stable nginx from official repository
  if [ ! -f /etc/apt/sources.list.d/nginx.list ]; then
    apt-get install -y curl lsb-release gnupg
    curl -fsSL https://nginx.org/keys/nginx_signing.key | \
      gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian $(lsb_release -cs) nginx" \
      >/etc/apt/sources.list.d/nginx.list
  fi

  apt-get update
}

install_packages() {
  # install python first so py3compile is available for other packages
  apt-get install -y --no-install-recommends python3 python3-pip python3-venv
  # remaining packages
  apt-get install -y --no-install-recommends systemd-sysv build-essential ca-certificates wget curl gnupg pkg-config \
    cmake openssl zlib1g-dev liblz4-dev libzip-dev libssh2-1-dev libnghttp2-dev \
    libcurl4-openssl-dev libcrack2-dev libxml2-dev libxslt1-dev mariadb-client \
    nginx php8.4 php8.4-fpm php8.4-cli php8.4-mysql certbot python3-certbot-nginx
}

configure_nginx() {
  local domain=${DOMAIN:-example.com}
  mkdir -p "/var/www/${domain}/htdocs"
  chgrp www-data "/var/www/${domain}/htdocs"
  [ -f files/nginx/nginx.conf ] && cp files/nginx/nginx.conf /etc/nginx/nginx.conf || true
  mkdir -p /etc/nginx/conf.d
  [ -f files/nginx/conf.d/mail.conf ] && cp files/nginx/conf.d/mail.conf /etc/nginx/conf.d/mail.conf || true
  mkdir -p /etc/nginx/snippets
  if [ -d files/nginx/snippets ]; then
    cp -r files/nginx/snippets/* /etc/nginx/snippets/
  fi
  [ -f /etc/nginx/snippets/diffie-hellman ] && sed -i "s#XXDOMAINXX#${domain}#g" /etc/nginx/snippets/diffie-hellman || true
  mkdir -p /etc/nginx/sites-available
  if [ -f files/nginx/sites-available/xxdomainxx.conf ]; then
    cp files/nginx/sites-available/xxdomainxx.conf "/etc/nginx/sites-available/${domain}.conf"
    sed -i "s#XXDOMAINXX#${domain}#g" "/etc/nginx/sites-available/${domain}.conf"
  fi
  mkdir -p /etc/nginx/sites-enabled
  [ -f /etc/nginx/sites-available/${domain}.conf ] && ln -sf "/etc/nginx/sites-available/${domain}.conf" "/etc/nginx/sites-enabled/${domain}.conf"
}

configure_php() {
  local phpv=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
  local fpm_dir="/etc/php/${phpv}/fpm"
  if [ -f files/php/etc/php-fpm.d/www.conf ]; then
    cp files/php/etc/php-fpm.d/www.conf "${fpm_dir}/pool.d/www.conf"
  fi
  if [ -f files/php/etc/php-fpm.conf ]; then
    sed "s#/usr/local/php/etc#${fpm_dir}#" files/php/etc/php-fpm.conf > "${fpm_dir}/php-fpm.conf"
  fi
  if [ -f files/php/etc/conf.d/modules.ini ]; then
    cp files/php/etc/conf.d/modules.ini "${fpm_dir}/conf.d/modules.ini"
  fi
}

configure_letsencrypt() {
  local domain=${DOMAIN:-example.com}
  local email=${EMAIL_SUPPORT:-admin@${domain}}
  mkdir -p "/var/www/${domain}/letsencrypt"
  chgrp www-data "/var/www/${domain}/letsencrypt"
  mkdir -p /etc/letsencrypt/configs
  if [ -f files/letsencrypt/configs/xxdomainxx.conf ]; then
    sed "s#XXDOMAINXX#${domain}#g;s#XXEMAILSUPPORTXX#${email}#g" \
      files/letsencrypt/configs/xxdomainxx.conf > \
      "/etc/letsencrypt/configs/${domain}.conf"
  fi
  mkdir -p /etc/letsencrypt/crontab
  if [ -f files/letsencrypt/crontab/renewLetsEncrypt.sh ]; then
    cp files/letsencrypt/crontab/renewLetsEncrypt.sh \
      "/etc/letsencrypt/crontab/${domain}-renewLetsEncrypt.sh"
  fi
  chmod +x "/etc/letsencrypt/crontab/${domain}-renewLetsEncrypt.sh"
  if [ -z "${CI:-}" ]; then
    command -v crontab >/dev/null || apt-get install -y cron
    (crontab -l 2>/dev/null; echo "0 0 * * * /etc/letsencrypt/crontab/${domain}-renewLetsEncrypt.sh") | crontab -
  fi
  certbot --config "/etc/letsencrypt/configs/${domain}.conf" certonly || true
  sed -i '/#REMOVE_AFTER_CONFIGURING_LE#/d' "/etc/nginx/sites-enabled/${domain}.conf"
  nginx -s reload || true
}


check_versions() {
  openssl version
  cmake --version | head -n1
  curl -V | head -n1
  python3 --version
  pip3 --version
  php -v | head -n1
  nginx -v
  certbot --version
}

main() {
  setup_apt
  install_packages
  configure_nginx
  configure_php
  configure_letsencrypt
  check_versions
}

main "$@"
