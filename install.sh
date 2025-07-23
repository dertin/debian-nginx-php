#!/usr/bin/env bash
set -euo pipefail

# Installs and configures packages on Debian 12.11 using APT whenever possible.
# Only mimalloc is built from source if not available.

# non interactive apt
export DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-noninteractive}
shopt -s expand_aliases
alias apt-get='/usr/bin/apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"'

# Optimization flags used if compiling any component
export CFLAGS="-march=native -O2 -pipe"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib"
export LIBS="-ldl"

setup_apt() {
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
}

install_packages() {
  apt-get install -y build-essential ca-certificates wget curl gnupg pkg-config \
    cmake openssl zlib1g-dev liblz4-dev libzip-dev libssh2-1-dev libnghttp2-dev \
    libcurl4-openssl-dev libcrack2-dev libxml2-dev libxslt1-dev mariadb-client \
    nginx php php-fpm php-cli php-mysql python3 python3-pip python3-venv certbot \
    python3-certbot-nginx
}

install_mimalloc() {
  if dpkg -s libmimalloc-dev >/dev/null 2>&1; then
    return
  fi
  local tmp=/var/tmp/mimalloc_build
  local url="https://github.com/microsoft/mimalloc/archive/refs/tags/v3.1.5.tar.gz"
  mkdir -p "${tmp}" && cd "${tmp}"
  wget -O mimalloc.tar.gz "$url"
  tar xf mimalloc.tar.gz --strip-components=1
  cmake -B build -DCMAKE_BUILD_TYPE=Release -DMI_BUILD_SHARED=ON .
  make -C build
  make -C build install
  ldconfig
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
  install_mimalloc
  check_versions
}

main "$@"
