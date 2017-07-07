#!/bin/bash

# Tested on Debian 8.8 32bit / 64bit - DigitalOcean
# NOT COMPLETED, MAY HAVE SERIOUS ERRORS

BASEDIR="$PWD"
MACHINE_TYPE=`uname -m`

if [ "$MACHINE_TYPE" == "i386" ]; then
	export CPPFLAGS="-I/usr/local/include -I/usr/include/i386-linux-gnu"
fi

if [ "$MACHINE_TYPE" == "x86_64" ]; then
	export CPPFLAGS="-I/usr/local/include -I/usr/include/x86_64-linux-gnu"
fi

export LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib"
export LDCONFIG=-L/usr/local/lib
export LIBS="-ldl" # for curl / openssl

source /etc/profile

#####################################################################################################################
#
# FUNCTIONS
#
#####################################################################################################################

function wgetAndDecompress(){

  dirTmp=$1
  folderTmp=$2
  downloadAddress=$3

  if [ -z $dirTmp ] || [ -z $folderTmp ] || [ -z $downloadAddress ]
  then
     read -n 1 -s -p "Critical error in wgetAndDecompress()" && echo -e "\n"
    exit 0
  fi

  # tar.gz or tar.xz
  mkdir -p $dirTmp/$folderTmp
  wget -O $dirTmp/$folderTmp.tar $downloadAddress
  rm -Rf $dirTmp/$folderTmp/*
  tar -xvf $dirTmp/$folderTmp.tar -C $dirTmp/$folderTmp --strip-components=1
  cd $dirTmp/$folderTmp

}

function pauseToContinue() {
  read -n 1 -s -p "Press any key to continue" && echo -e "\n"
}

#####################################################################################################################
#
# INIT SCRIPT
#
#####################################################################################################################

global_domain="domian.com"
read -e -i "$global_domain" -p "Enter the domian: " input_global_domain
global_domain="${input_global_domain:-$global_domain}"

global_emailSupport="email@email.com"
read -e -i "$global_emailSupport" -p "Enter email support: " input_global_emailSupport
global_emailSupport="${input_global_emailSupport:-$global_emailSupport}"

read -e -i "Y" -p "Delete building directories ? [Y/n]: " input_delete_build

if [ $input_delete_build == "Y" ] || [ $input_delete_build == "y" ]
then
  rm -rf /var/tmp/*_build
fi

read -e -i "Y" -p "Install Essential ? [Y/n]: " input_install_essential

if [ $input_install_essential == "Y" ] || [ $input_install_essential == "y" ]
then

# Build Essential

  apt-get -y update
  apt-get -y upgrade
  apt-get -y dist-upgrade

  apt-get -y install coreutils build-essential expect perl file sudo cron xsltproc docbook-xsl docbook-xml \
  libpcre3 libpcre3-dev zlib1g-dev golang libssl-dev libtiffxx5 libexpat1-dev libpng12-dev libfreetype6-dev \
  pkg-config libfontconfig1-dev libjpeg62-turbo-dev libjpeg-dev xorg-sgml-doctools \
  x11proto-core-dev libxau-dev libxdmcp-dev needrestart g++ make binutils autoconf automake autotools-dev libtool \
  libbz2-dev zlib1g-dev libcunit1-dev libxml2-dev libev-dev libevent-dev libjansson-dev \
  libjemalloc-dev cython python3-dev python-setuptools libaio-dev libncurses5-dev \
  m4 libunistring-dev libgmp-dev trousers libidn2-0 libunbound-dev \
  bison libmcrypt-dev libicu-dev libltdl-dev libjpeg-dev libpng-dev libpspell-dev libreadline-dev \
  uuid-dev gnulib libc6-dev libc-dbg libpam0g-dev libmsgpack-dev libstemmer-dev libbsd-dev \
  libstdc++-4.9-dev autoconf-archive gnu-standards gettext gcc-4.9-locales debian-keyring \
  g++-multilib g++-4.9-multilib gcc-multilib flex liblinear-tools liblinear-dev mcrypt \
  gcj-jdk valgrind kytea libkytea-dev valgrind-mpi valkyrie \
  libdbi-perl libboost-all-dev libreadline-dev rsync net-tools libdbd-mysql-perl \
  re2c

  apt-get -y remove --purge --auto-remove curl
  apt-get -y remove --purge --auto-remove cmake*

  apt-get -y build-dep curl
  apt-get -y build-dep zlib
  apt-get -y build-dep openssl

  apt-get -y upgrade
  apt-get -y autoremove

  pauseToContinue

  read -e -i "Y" -p "Reboot ? [Y/n]: " input_install_reboot

  if [ $input_install_reboot == "Y" ] || [ $input_install_reboot == "y" ]
  then
    reboot
    exit 0
  fi

fi

#####################################################################################################################
#
# INSTALL OpenSSL (Tested with 1.1.0f - https://www.openssl.org/source/openssl-1.1.0f.tar.gz)
# config file: /usr/local/ssl/openssl.cnf
#
#####################################################################################################################

read -e -i "Y" -p "Install OpenSSL ? [Y/n]: " input_install_openssl

if [ $input_install_openssl == "Y" ] || [ $input_install_openssl == "y" ]
then

  openssl_address="https://www.openssl.org/source/openssl-1.1.0f.tar.gz"
  read -e -i "$openssl_address" -p "Enter the download address for OpenSSL (tar.gz): " input_openssl_address
  openssl_address="${input_openssl_address:-$openssl_address}"

  openssl_install_tmp_dir="/var/tmp/openssl_build"
  read -e -i "$openssl_install_tmp_dir" -p "Enter temporary directory for OpenSSL installation: " input_openssl_install_tmp_dir
  openssl_install_tmp_dir="${input_openssl_install_tmp_dir:-$openssl_install_tmp_dir}"

  # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
  wgetAndDecompress $openssl_install_tmp_dir openssl_src $openssl_address

  ./config -Wl,--enable-new-dtags,-rpath,'$(LIBRPATH)' no-comp no-zlib no-zlib-dynamic shared

  make
  make test
  sed -i 's# libcrypto.a##;s# libssl.a##;/INSTALL_LIBS/s#libcrypto.a##' Makefile
  make MANSUFFIX=ssl install

  ldconfig
  ldconfig -p | grep libcrypto

  whereis openssl
  openssl version -v

  pauseToContinue

  needrestart -r l

fi

#####################################################################################################################
#
# INSTALL zlib (Tested with 1.2.11 - http://www.zlib.net/zlib-1.2.11.tar.gz)
#
#####################################################################################################################

read -e -i "Y" -p "Install zlib ? [Y/n]: " input_install_zlib

if [ $input_install_zlib == "Y" ] || [ $input_install_zlib == "y" ]
then

  zlib_address="http://www.zlib.net/zlib-1.2.11.tar.gz"
  read -e -i "$zlib_address" -p "Enter the download address for zlib (tar.gz): " input_zlib_address
  zlib_address="${input_zlib_address:-$zlib_address}"

  zlib_install_tmp_dir="/var/tmp/zlib_build"
  read -e -i "$zlib_install_tmp_dir" -p "Enter temporary directory for zlib installation: " input_zlib_install_tmp_dir
  zlib_install_tmp_dir="${input_zlib_install_tmp_dir:-$zlib_install_tmp_dir}"

  # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
  wgetAndDecompress $zlib_install_tmp_dir zlib_src $zlib_address

  ./configure --shared

  make
  make install

  ldconfig

pauseToContinue

fi

#####################################################################################################################
#
# INSTALL LZ4 (Tested with v1.7.5 - https://github.com/lz4/lz4/archive/v1.7.5.tar.gz)
#
#####################################################################################################################

read -e -i "Y" -p "Install lz4 ? [Y/n]: " input_install_lz4

if [ $input_install_lz4 == "Y" ] || [ $input_install_lz4 == "y" ]
then

  lz4_address="https://github.com/lz4/lz4/archive/v1.7.5.tar.gz"
  read -e -i "$lz4_address" -p "Enter the download address for lz4 (tar.gz): " input_lz4_address
  lz4_address="${input_lz4_address:-$lz4_address}"

  lz4_install_tmp_dir="/var/tmp/lz4_build"
  read -e -i "$lz4_install_tmp_dir" -p "Enter temporary directory for libssh2 installation: " input_lz4_install_tmp_dir
  lz4_install_tmp_dir="${input_lz4_install_tmp_dir:-$lz4_install_tmp_dir}"

  wgetAndDecompress $lz4_install_tmp_dir lz4_src $lz4_address

  make
  make install

  ldconfig

  lz4 -V

pauseToContinue

fi

#####################################################################################################################
#
# INSTALL libssh2 (Tested with 1.8.0 - https://libssh2.org/download/libssh2-1.8.0.tar.gz)
#
#####################################################################################################################

read -e -i "Y" -p "Install libssh2 ? [Y/n]: " input_install_libssh2

if [ $input_install_libssh2 == "Y" ] || [ $input_install_libssh2 == "y" ]
then

  libssh2_address="https://libssh2.org/download/libssh2-1.8.0.tar.gz"
  read -e -i "$libssh2_address" -p "Enter the download address for libssh2 (tar.gz): " input_libssh2_address
  libssh2_address="${input_libssh2_address:-$libssh2_address}"

  libssh2_install_tmp_dir="/var/tmp/libssh2_build"
  read -e -i "$libssh2_install_tmp_dir" -p "Enter temporary directory for libssh2 installation: " input_libssh2_install_tmp_dir
  libssh2_install_tmp_dir="${input_libssh2_install_tmp_dir:-$libssh2_install_tmp_dir}"

  wgetAndDecompress $libssh2_install_tmp_dir libssh2_src $libssh2_address

  ./configure --with-openssl --with-libssl-prefix=/usr/local --with-libz --with-libz-prefix=/usr/local

  make
  make install

  ldconfig

pauseToContinue

fi

#####################################################################################################################
#
# INSTALL Nghttp2: HTTP/2 C Library
# (Tested with v1.23.1 - https://github.com/nghttp2/nghttp2/releases/download/v1.23.1/nghttp2-1.23.1.tar.gz)
#
#####################################################################################################################

read -e -i "Y" -p "Install Nghttp2 ? [Y/n]: " input_install_nghttp2

if [ $input_install_nghttp2 == "Y" ] || [ $input_install_nghttp2 == "y" ]
then

  nghttp2_address="https://github.com/nghttp2/nghttp2/releases/download/v1.23.1/nghttp2-1.23.1.tar.gz"
  read -e -i "$nghttp2_address" -p "Enter the download address for Nghttp2 (tar.gz): " input_nghttp2_address
  nghttp2_address="${input_nghttp2_address:-$nghttp2_address}"

  nghttp2_install_tmp_dir="/var/tmp/nghttp2_build"
  read -e -i "$nghttp2_install_tmp_dir" -p "Enter temporary directory for Nghttp2 installation: " input_nghttp2_install_tmp_dir
  nghttp2_install_tmp_dir="${input_nghttp2_install_tmp_dir:-$nghttp2_install_tmp_dir}"

  wgetAndDecompress $nghttp2_install_tmp_dir nghttp2_src $nghttp2_address

  ./configure

  make
  make install

  ldconfig

pauseToContinue

fi

#####################################################################################################################
#
# INSTALL curl (Tested with 7.54.1 - https://curl.haxx.se/download/curl-7.54.1.tar.gz)
#
#####################################################################################################################

read -e -i "Y" -p "Install curl ? [Y/n]: " input_install_curl

if [ $input_install_curl == "Y" ] || [ $input_install_curl == "y" ]
then

  curl_address="https://curl.haxx.se/download/curl-7.54.1.tar.gz"
  read -e -i "$curl_address" -p "Enter the download address for CURL (tar.gz): " input_curl_address
  curl_address="${input_curl_address:-$curl_address}"

  curl_install_tmp_dir="/var/tmp/curl_build"
  read -e -i "$curl_install_tmp_dir" -p "Enter temporary directory for CURL installation: " input_curl_install_tmp_dir
  curl_install_tmp_dir="${input_curl_install_tmp_dir:-$curl_install_tmp_dir}"

  # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
  wgetAndDecompress $curl_install_tmp_dir curl_src $curl_address

  ./buildconf

  ./configure --enable-versioned-symbols --enable-threaded-resolver --with-ssl=/usr/local/ssl --with-libssl-prefix=/usr/local --with-zlib=/usr/local/zlib --with-nghttp2 --with-libssh2

  make
  make install

  ldconfig

  curl -V



pauseToContinue

fi

#####################################################################################################################
#
# INSTALL GnuTLS 3.5.13 (https://www.gnupg.org/ftp/gcrypt/gnutls/v3.5/gnutls-3.5.13.tar.xz)
# - Optional
#
#####################################################################################################################

read -e -i "n" -p "Install GnuTLS [Opcional] ? [Y/n]: " input_install_gnutls

if [ $input_install_gnutls == "Y" ] || [ $input_install_gnutls == "y" ]
then

  apt-get -y build-dep nettle
  apt-get -y build-dep p11-kit

  gnutls_address="https://www.gnupg.org/ftp/gcrypt/gnutls/v3.5/gnutls-3.5.13.tar.xz"
  read -e -i "$gnutls_address" -p "Enter the download address for GnuTLS (tar.gz): " input_gnutls_address
  gnutls_address="${input_gnutls_address:-$gnutls_address}"

  gnutls_install_tmp_dir="/var/tmp/gnutls_build"
  read -e -i "$gnutls_install_tmp_dir" -p "Enter temporary directory for GnuTLS installation: " input_gnutls_install_tmp_dir
  gnutls_install_tmp_dir="${input_gnutls_install_tmp_dir:-$gnutls_install_tmp_dir}"

  # GnuTLS Dependencies: Nettle 3.3

    # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
    wgetAndDecompress '/var/tmp/nettle_build' nettle_src 'https://ftp.gnu.org/gnu/nettle/nettle-3.3.tar.gz'

    ./configure

    make
    make install

    chmod -v 755 /usr/lib/lib{hogweed,nettle}.so

    ldconfig

    pauseToContinue

  # GnuTLS Dependencies: Libtasn1 >= 4.9

    # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
    wgetAndDecompress '/var/tmp/libtasn1_build' libtasn1_src 'http://ftp.gnu.org/gnu/libtasn1/libtasn1-4.12.tar.gz'

    ./configure

    make
    make install

    ldconfig

    pauseToContinue

  # GnuTLS Dependencies: p11-kit >= 0.23.1

    # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
    wgetAndDecompress '/var/tmp/p11kit_build' p11kit_src 'http://p11-glue.freedesktop.org/releases/p11-kit-0.23.2.tar.gz'

    ./configure --with-trust-paths=/etc/ssl/certs

    make
    make install

    ldconfig

    pauseToContinue

  # Compile GnuTLS

    # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
    wgetAndDecompress $gnutls_install_tmp_dir gnutls_src $gnutls_address

    ./configure --enable-shared --with-default-trust-store-file=`curl-config --ca`

    make
    make install

    ldconfig

pauseToContinue

fi

#####################################################################################################################
#
# INSTALL cmake (Tested with 3.8.2 - https://cmake.org/files/v3.8/cmake-3.8.2.tar.gz)
#
#####################################################################################################################

read -e -i "Y" -p "Install cmake ? [Y/n]: " input_install_cmake

if [ $input_install_cmake == "Y" ] || [ $input_install_cmake == "y" ]
then

  cmake_address="https://cmake.org/files/v3.8/cmake-3.8.2.tar.gz"
  read -e -i "$cmake_address" -p "Enter the download address for cmake (tar.gz): " input_cmake_address
  cmake_address="${input_cmake_address:-$cmake_address}"

  cmake_install_tmp_dir="/var/tmp/cmake_build"
  read -e -i "$cmake_install_tmp_dir" -p "Enter temporary directory for cmake installation: " input_cmake_install_tmp_dir
  cmake_install_tmp_dir="${input_cmake_install_tmp_dir:-$cmake_install_tmp_dir}"

  # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
  wgetAndDecompress $cmake_install_tmp_dir cmake_src $cmake_address

  ./bootstrap

  make
  make install

  ldconfig

  cmake --version

pauseToContinue

fi
#####################################################################################################################
#
# INSTALL libcrack2  (Tested with 2.9.6 - https://github.com/cracklib/cracklib/archive/cracklib-2.9.6.tar.gz)
#
#####################################################################################################################

read -e -i "Y" -p "Install libcrack2 ? [Y/n]: " input_install_libcrack2

if [ $input_install_libcrack2 == "Y" ] || [ $input_install_libcrack2 == "y" ]
then

  libcrack2_address="https://github.com/cracklib/cracklib/archive/cracklib-2.9.6.tar.gz"
  read -e -i "$libcrack2_address" -p "Enter the download address for libcrack2 (tar.gz): " input_libcrack2_address
  libcrack2_address="${input_libcrack2_address:-$libcrack2_address}"

  libcrack2_install_tmp_dir="/var/tmp/libcrack2_build"
  read -e -i "$libcrack2_install_tmp_dir" -p "Enter temporary directory for libcrack2 installation: " input_libcrack2_install_tmp_dir
  libcrack2_install_tmp_dir="${input_libcrack2_install_tmp_dir:-$libcrack2_install_tmp_dir}"

  wgetAndDecompress $libcrack2_install_tmp_dir libcrack2_src $libcrack2_address

  cd ./src

  sed -i '/skipping/d' util/packer.c

  mkdir -p /usr/local/lib/cracklib/pw_dict

  ./autogen.sh

  ./configure --prefix=/usr/local

  make
  make install
  make installcheck

  ldconfig

  pauseToContinue

  cd ../words

  make all

  install -v -m644 -D  ./cracklib-words.gz /usr/share/dict/cracklib-words.gz
  gunzip -v /usr/share/dict/cracklib-words.gz
  ln -v -sf cracklib-words /usr/share/dict/words
  install -v -m755 -d /usr/local/lib/cracklib
  #create-cracklib-dict /usr/share/dict/cracklib-words /usr/share/dict/cracklib-extra-words
  create-cracklib-dict /usr/share/dict/cracklib-words

pauseToContinue

fi

#####################################################################################################################
#
# INSTALL LibXML2  (Tested with 2.9.4 - http://xmlsoft.org/sources/libxml2-2.9.4.tar.gz)
#
#####################################################################################################################

read -e -i "Y" -p "Install LibXML2 ? [Y/n]: " input_install_libXML2

if [ $input_install_libXML2 == "Y" ] || [ $input_install_libXML2 == "y" ]
then

  libXML2_address="http://xmlsoft.org/sources/libxml2-2.9.4.tar.gz"
  read -e -i "$libXML2_address" -p "Enter the download address for LibXML2 (tar.gz): " input_libXML2_address
  libXML2_address="${input_libXML2_address:-$libXML2_address}"

  libXML2_install_tmp_dir="/var/tmp/libXML2_build"
  read -e -i "$libXML2_install_tmp_dir" -p "Enter temporary directory for LibXML2 installation: " input_libXML2_install_tmp_dir
  libXML2_install_tmp_dir="${input_libXML2_install_tmp_dir:-$libXML2_install_tmp_dir}"

  wgetAndDecompress $libXML2_install_tmp_dir libXML2_src $libXML2_address

  ./configure --prefix=/usr/local --with-history

  make
  make install

  ldconfig

  pauseToContinue

fi

#####################################################################################################################
#
# INSTALL libxslt  (Tested with 1.1.29 - http://xmlsoft.org/sources/libxslt-1.1.29.tar.gz)
#
#####################################################################################################################

read -e -i "Y" -p "Install libxslt ? [Y/n]: " input_install_libxslt

if [ $input_install_libxslt == "Y" ] || [ $input_install_libxslt == "y" ]
then

  libxslt_address="http://xmlsoft.org/sources/libxslt-1.1.29.tar.gz"
  read -e -i "$libxslt_address" -p "Enter the download address for libxslt (tar.gz): " input_libxslt_address
  libxslt_address="${input_libxslt_address:-$libxslt_address}"

  libxslt_install_tmp_dir="/var/tmp/libxslt_build"
  read -e -i "$libxslt_install_tmp_dir" -p "Enter temporary directory for libxslt installation: " input_libxslt_install_tmp_dir
  libxslt_install_tmp_dir="${input_libxslt_install_tmp_dir:-$libxslt_install_tmp_dir}"

  wgetAndDecompress $libxslt_install_tmp_dir libxslt_src $libxslt_address

  ./configure --prefix=/usr/local

  make
  make install

  ldconfig

  pauseToContinue

fi

#####################################################################################################################
#
# INSTALL jemalloc - https://github.com/jemalloc/jemalloc/archive/5.0.1.tar.gz
#
#####################################################################################################################

read -e -i "Y" -p "Install jemalloc ? [Y/n]: " input_install_jemalloc

if [ $input_install_jemalloc == "Y" ] || [ $input_install_jemalloc == "y" ]
then

  jemalloc_address="https://github.com/jemalloc/jemalloc/archive/5.0.1.tar.gz"
  read -e -i "$jemalloc_address" -p "Enter the download address for jemalloc (tar.gz): " input_jemalloc_address
  jemalloc_address="${input_jemalloc_address:-$jemalloc_address}"

  jemalloc_install_tmp_dir="/var/tmp/jemalloc_build"
  read -e -i "$jemalloc_install_tmp_dir" -p "Enter temporary directory for jemalloc installation: " input_jemalloc_install_tmp_dir
  jemalloc_install_tmp_dir="${input_jemalloc_install_tmp_dir:-$jemalloc_install_tmp_dir}"

  # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
  wgetAndDecompress $jemalloc_install_tmp_dir jemalloc_src $jemalloc_address

  ./autogen.sh

  ./configure --prefix=/usr/local --with-xslroot=/usr/share/xml/docbook/stylesheet/docbook-xsl/

  make
  make dist
  make install

  ldconfig

  pauseToContinue

fi

#####################################################################################################################
#
# INSTALL MariaDB 10.2.6 - https://mariadb.com/kb/en/mariadb/generic-build-instructions/
#
#####################################################################################################################

read -e -i "Y" -p "Install MariaDB ? [Y/n]: " input_install_mariadb

if [ $input_install_mariadb == "Y" ] || [ $input_install_mariadb == "y" ]
then

  mariadb_address="https://downloads.mariadb.org/f/mariadb-10.2.6/source/mariadb-10.2.6.tar.gz?serve"
  read -e -i "$mariadb_address" -p "Enter the download address for MariaDB (tar.gz): " input_mariadb_address
  mariadb_address="${input_mariadb_address:-$mariadb_address}"

  mariadb_install_tmp_dir="/var/tmp/mariadb_build"
  read -e -i "$mariadb_install_tmp_dir" -p "Enter temporary directory for MariaDB installation: " input_mariadb_install_tmp_dir
  mariadb_install_tmp_dir="${input_mariadb_install_tmp_dir:-$mariadb_install_tmp_dir}"

  # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
  wgetAndDecompress $mariadb_install_tmp_dir mariadb_src $mariadb_address

  groupadd mysql
  # useradd -c "MySQL Server" -g mysql -s /bin/false mysql
	adduser --system --no-create-home --disabled-login --disabled-password --group mysql

  cmake . -DBUILD_CONFIG=mysql_release \
  -DCMAKE_C_FLAGS="-I/usr/local/include -I/usr/include/i386-linux-gnu" \
  -DWITH_INNODB_LZ4=ON -DWITH_INNODB_LZMA=OFF -DWITH_INNODB_LZO=OFF -DWITH_INNODB_BZIP2=OFF \
  -DWITH_ZLIB=system -DWITH_SSL=system -DWITH_JEMALLOC=system \
  -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_spanish_ci \
  -DWITH_DEBUG=0 -DWITH_VALGRIND=0 -DPLUGIN_EXAMPLE=NO

  make
  make install

  export PATH=$PATH:/usr/local/mysql/bin
  echo "export PATH=$PATH:/usr/local/mysql/bin" >> /etc/profile
  source /etc/profile

  cd /usr/local/mysql

  chown -R root .
  chown -R mysql mysql

  cp ./support-files/my-medium.cnf /etc/my.cnf
  cp /etc/mysql/my.cnf /etc/mysql/my.cnf.back

  # setting /etc/mysql/my.cnf
  sed -i 's#lc-messages-dir.*=.*/usr/share/mysql#lc-messages-dir  = /usr/local/mysql/share#g' /etc/mysql/my.cnf
  sed -i 's#basedir.*=.*/usr#basedir  = /usr/local/mysql#g' /etc/mysql/my.cnf
  sed -i 's#datadir.*=.*/var/lib/mysql#datadir  = /usr/local/mysql/data#g' /etc/mysql/my.cnf
  # Evaluate: Modify query_cache_size (=0)
  # Evaluate: Modify query_cache_type (=0)
  # Evaluate: Modify query_cache_limit (> 1M, or use smaller result sets)

  # setting /etc/my.cnf
  sed -i 's#socket.*=.*/tmp/mysql.sock#socket  = /var/run/mysqld/mysqld.sock#g' /etc/my.cnf
  ## setting [mysqld] section
  perl -i -pe "BEGIN{undef $/;} s/^\[mysqld\]$/[mysqld]\n\nperformance_schema = ON\n/sgm" /etc/my.cnf

  my_print_defaults --mysqld

  pauseToContinue

  # log dir
  mkdir -p /var/log/mysql/
  touch /var/log/mysql/error.log
  chown -R mysql:mysql /var/log/mysql/

  # socket
  mkdir -p /var/run/mysqld/
  chown -R mysql:mysql /var/run/mysqld/

  # datadir
  mkdir -p /usr/local/mysql/data

  ./scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data --socket=/var/run/mysqld/mysqld.sock --verbose

  # datadir own
  chown -R mysql:mysql /usr/local/mysql/data

  cp ./support-files/mysql.server /etc/init.d/mysql
  chmod +x /etc/init.d/mysql
  update-rc.d mysql defaults

  ldconfig

  service mysql start

  ./bin/mysql_secure_installation --socket=/var/run/mysqld/mysqld.sock

  ./bin/mysqladmin -u root -p password

  service mysql restart

  service mysql status

  pauseToContinue

  # http://www.askapache.com/linux/mariadb-lz4-compression-howto-centos/
  mysql -p -Ntbe 'set global innodb_compression_algorithm=lz4;set global innodb_compression_level=3'
  mysql -p -Ntbe 'SHOW VARIABLES WHERE Variable_name LIKE "have_%" OR Variable_name LIKE "%_compression_%"'

  pauseToContinue

  wget http://mysqltuner.pl/ -O /usr/local/mysql/mysql-test/mysqltuner.pl
  wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/basic_passwords.txt -O /usr/local/mysql/mysql-test/basic_passwords.txt
  wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/vulnerabilities.csv -O /usr/local/mysql/mysql-test/vulnerabilities.csv

  read -e -i "Y" -p "Run Test Tuner MariaDB ? [Y/n]: " input_install_mariadb_test_tuner

  if [ $input_install_mariadb_test_tuner == "Y" ] || [ $input_install_mariadb_test_tuner == "y" ]
  then
     perl /usr/local/mysql/mysql-test/mysqltuner.pl --cvefile=/usr/local/mysql/mysql-test/vulnerabilities.csv
  fi

  cd ./mysql-test

  read -e -i "n" -p "Run Test MariaDB ? [Y/n]: " input_install_mariadb_test

  if [ $input_install_mariadb_test == "Y" ] || [ $input_install_mariadb_test == "y" ]
  then
    perl ./mysql-test-run.pl
  fi

pauseToContinue

fi

#####################################################################################################################
#
# INSTALL PHP (Tested with 7.1.6 - https://github.com/php/php-src/archive/php-7.1.6.tar.gz)
# use config file from: https://github.com/kasparsd/php-7-debian/
#
#####################################################################################################################

read -e -i "Y" -p "Install PHP ? [Y/n]: " input_install_php

if [ $input_install_php == "Y" ] || [ $input_install_php == "y" ]
then

	adduser --system --no-create-home --disabled-login --disabled-password --group www-data

  php_address="https://github.com/php/php-src/archive/php-7.1.6.tar.gz"
  read -e -i "$php_address" -p "Enter the download address for PHP 7 (tar.gz): " input_php_address
  php_address="${input_php_address:-$php_address}"

  php_install_tmp_dir="/var/tmp/php_build"
  read -e -i "$php_install_tmp_dir" -p "Enter temporary directory for nginx installation: " input_php_install_tmp_dir
  php_install_tmp_dir="${input_php_install_tmp_dir:-$php_install_tmp_dir}"

  # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
  wgetAndDecompress $php_install_tmp_dir php_src $php_address

  mkdir -p /usr/local/php7

  ./buildconf --force

  CONFIGURE_STRING="--prefix=/usr/local/php7 \
  --enable-huge-code-pages \
  --with-config-file-scan-dir=/usr/local/php7/etc/conf.d \
  --without-pear \
  --enable-bcmath \
  --with-bz2 \
  --enable-calendar \
  --enable-intl \
  --enable-exif \
  --enable-dba \
  --enable-ftp \
  --with-gettext \
  --with-gd \
  --with-jpeg-dir \
  --enable-mbstring \
  --with-mcrypt \
  --with-mhash \
  --enable-mysqlnd=shared \
  --with-mysqli=shared,mysqlnd \
  --with-pdo-mysql=shared,mysqlnd \
  --with-mysql-sock=/var/run/mysqld/mysqld.sock \
  --with-openssl \
  --enable-pcntl \
  --with-pspell \
  --enable-shmop \
  --enable-soap \
  --enable-sockets \
  --enable-sysvmsg \
  --enable-sysvsem \
  --enable-sysvshm \
  --enable-wddx \
  --with-zlib \
  --enable-zip \
  --with-readline \
  --with-curl \
  --enable-simplexml \
  --enable-xmlreader \
  --enable-xmlwriter \
  --enable-fpm \
  --with-fpm-user=www-data \
  --with-fpm-group=www-data"

  ./configure $CONFIGURE_STRING

  make
  make install

  # Create a dir for storing PHP module conf
  mkdir /usr/local/php7/etc/conf.d

  # Symlink php-fpm to php7-fpm
  ln -s /usr/local/php7/sbin/php-fpm /usr/local/php7/sbin/php7-fpm

  # Add config files
  cp php.ini-production /usr/local/php7/lib/php.ini-production
  cp php.ini-development /usr/local/php7/lib/php.ini-development

  cp php.ini-production /usr/local/php7/lib/php.ini

  touch /usr/local/php7/etc/php-fpm.d/www.conf
  echo '[www]' > /usr/local/php7/etc/php-fpm.d/www.conf
  echo 'user = www-data' >> /usr/local/php7/etc/php-fpm.d/www.conf
  echo 'group = www-data' >> /usr/local/php7/etc/php-fpm.d/www.conf
  echo 'listen = 127.0.0.1:9007' >> /usr/local/php7/etc/php-fpm.d/www.conf
  echo 'pm = dynamic' >> /usr/local/php7/etc/php-fpm.d/www.conf
  echo 'pm.max_children = 5' >> /usr/local/php7/etc/php-fpm.d/www.conf
  echo 'pm.start_servers = 2' >> /usr/local/php7/etc/php-fpm.d/www.conf
  echo 'pm.min_spare_servers = 1' >> /usr/local/php7/etc/php-fpm.d/www.conf
  echo 'pm.max_spare_servers = 3' >> /usr/local/php7/etc/php-fpm.d/www.conf

  touch /usr/local/php7/etc/php-fpm.conf
  echo '[global]' > /usr/local/php7/etc/php-fpm.conf
  echo 'pid = /var/run/php7-fpm.pid' >> /usr/local/php7/etc/php-fpm.conf
  echo 'error_log = /var/log/php7-fpm.log' >> /usr/local/php7/etc/php-fpm.conf
  echo 'include=/usr/local/php7/etc/php-fpm.d/*.conf' >> /usr/local/php7/etc/php-fpm.conf

  touch /usr/local/php7/etc/conf.d/modules.ini
  echo '# Zend OPcache' > /usr/local/php7/etc/conf.d/modules.ini
  echo 'zend_extension=opcache.so' >> /usr/local/php7/etc/conf.d/modules.ini

  # Add the init script
  wget https://raw.githubusercontent.com/kasparsd/php-7-debian/master/conf/php7-fpm.init -O /etc/init.d/php7-fpm
  chmod +x /etc/init.d/php7-fpm
  update-rc.d php7-fpm defaults

  ldconfig

  service php7-fpm start

  needrestart -r l

pauseToContinue

fi

#####################################################################################################################
#
# INSTALL nginx (Tested with 1.13.1 - https://nginx.org/download/nginx-1.13.1.tar.gz)
#
#####################################################################################################################

read -e -i "Y" -p "Install nginx ? [Y/n]: " input_install_nginx

if [ $input_install_nginx == "Y" ] || [ $input_install_nginx == "y" ]
then

	adduser --system --no-create-home --disabled-login --disabled-password --group www-data

  nginx_address="https://nginx.org/download/nginx-1.13.1.tar.gz"
  read -e -i "$nginx_address" -p "Enter the download address for CURL (tar.gz): " input_nginx_address
  nginx_address="${input_nginx_address:-$nginx_address}"

  nginx_install_tmp_dir="/var/tmp/nginx_build"
  read -e -i "$nginx_install_tmp_dir" -p "Enter temporary directory for nginx installation: " input_nginx_install_tmp_dir
  nginx_install_tmp_dir="${input_nginx_install_tmp_dir:-$nginx_install_tmp_dir}"

  # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
  wgetAndDecompress $nginx_install_tmp_dir nginx_src $nginx_address

  ./configure \
    --prefix=/usr/share/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/lock/nginx.lock \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --user=www-data \
    --group=www-data \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    --without-http_memcached_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_gzip_static_module \
    --with-http_v2_module \
    --with-ipv6

    make
    make install

    mkdir -p /etc/nginx/ssl/
    openssl dhparam -out /etc/nginx/ssl/dhparam.pem 4096

    # FILE: /etc/nginx/nginx.conf
		rm /etc/nginx/nginx.conf
		cp ${BASEDIR}/files/nginx/nginx.conf /etc/nginx/nginx.conf

		# FILE: /etc/nginx/conf.d/*
		mkdir -p /etc/nginx/conf.d/
		cp ${BASEDIR}/files/nginx/conf.d/mail.conf /etc/nginx/conf.d/mail.conf

		# FILE: /etc/nginx/snippets/*
		mkdir -p /etc/nginx/snippets/
		cp ${BASEDIR}/files/nginx/snippets/diffie-hellman /etc/nginx/snippets/diffie-hellman
		cp ${BASEDIR}/files/nginx/snippets/security /etc/nginx/snippets/security

		# FILE: /etc/nginx/sites-available/*
		mkdir -p /etc/nginx/sites-available/
		cp ${BASEDIR}/files/nginx/sites-available/xxdomainxx.conf /etc/nginx/sites-available/${global_domain}.conf
		# Modify file
		sed -i "s#XXDOMAINXX#${global_domain}#g" /etc/nginx/sites-available/${global_domain}.conf

		# DIR: /etc/nginx/sites-enabled/
		mkdir -p /etc/nginx/sites-enabled/
		ln -s /etc/nginx/sites-available/${global_domain}.conf /etc/nginx/sites-enabled/${global_domain}.conf

		# FILE: /lib/systemd/system/nginx.service
		cp ${BASEDIR}/files/nginx/systemd/nginx.service /lib/systemd/system/nginx.service
		chmod +x /lib/systemd/system/nginx.service

		needrestart -r l

		nginx
    nginx -t
    nginx -V
    nginx -s reload

    pauseToContinue

pauseToContinue

fi

#####################################################################################################################
#
# Let’s Encrypt with NGINX (https://github.com/certbot/certbot)
#
#####################################################################################################################

read -e -i "Y" -p "Install Let’s Encrypt ? [Y/n]: " input_install_letEncrypt

if [ $input_install_letEncrypt == "Y" ] || [ $input_install_letEncrypt == "y" ]
then

  git clone https://github.com/certbot/certbot /opt/letsencrypt
	chmod a+x /opt/letsencrypt/certbot-auto

	mkdir -p /var/www/${global_domain}/letsencrypt
	chgrp www-data /var/www/${global_domain}/letsencrypt

  # FILE: /etc/letsencrypt/configs/my-domain.conf
  mkdir -p /etc/letsencrypt/configs/
	cp ${BASEDIR}/files/letsencrypt/configs/xxdomainxx.conf /etc/letsencrypt/configs/${global_domain}.conf
	# Modify file
	sed -i "s#XXDOMAINXX#${global_domain}#g" /etc/letsencrypt/configs/${global_domain}.conf
	sed -i "s#XXEMAILSUPPORTXX#${global_emailSupport}#g" /etc/letsencrypt/configs/${global_domain}.conf

	cd /opt/letsencrypt/
	./certbot-auto --nginx --config /etc/letsencrypt/configs/${global_domain}.conf certonly

	mkdir -p /var/log/letsencrypt/

	# FILE: /etc/letsencrypt/crontab/
	mkdir -p /etc/letsencrypt/crontab/
	cp ${BASEDIR}/files/letsencrypt/crontab/renew‑letsencrypt.sh /etc/letsencrypt/crontab/${global_domain}-renew‑letsencrypt.sh
	# Modify file
	sed -i "s#XXDOMAINXX#${global_domain}#g" /etc/letsencrypt/crontab/${global_domain}-renew‑letsencrypt.sh
	# Add crontab renew‑letsencrypt
	crontab -l | { cat; echo "0 0 1 JAN,MAR,MAY,JUL,SEP,NOV * /etc/letsencrypt/crontab/${global_domain}-renew‑letsencrypt.sh"; } | crontab -

fi


# NOTES:
# PHP 7 OPcache
# Nginx: https://fak3r.com/2015/09/29/howto-build-nginx-with-http-2-support/
# https://www.nginx.com/blog/compiling-dynamic-modules-nginx-plus/
# SSL config @see https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
# MariaDb: https://www.digitalocean.com/community/tutorials/how-to-secure-mysql-and-mariadb-databases-in-a-linux-vps
# http://howtolamp.com/lamp/mysql/5.6/securing/

# TODO:
# Install Let’s Encrypt Client @see https://www.nginx.com/blog/free-certificates-lets-encrypt-and-nginx/
# https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
# https://www.linode.com/docs/security/securing-your-server
# https://easyengine.io/tutorials/nginx/fail2ban/
