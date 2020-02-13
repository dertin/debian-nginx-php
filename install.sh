#!/usr/bin/env bash

# Tested on Debian 9.9 32bit / 64bit
# Use at your own risk

#####################################################################################################################
#
# Default software source list
#
#####################################################################################################################
jemalloc_address_default="https://github.com/jemalloc/jemalloc/archive/5.2.1.tar.gz"
cmake_address_default="https://github.com/Kitware/CMake/releases/download/v3.16.4/cmake-3.16.4.tar.gz"
openssl_address_default="https://www.openssl.org/source/openssl-1.1.1d.tar.gz"
python_address_default="https://www.python.org/ftp/python/2.7.17/Python-2.7.17.tgz"
python3_address_default="https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tgz"
zlib_address_default="http://www.zlib.net/zlib-1.2.11.tar.gz"
lz4_address_default="https://github.com/lz4/lz4/archive/v1.9.2.tar.gz"
libzip_address_default="https://libzip.org/download/libzip-1.6.1.tar.gz"
libssh2_address_default="https://www.libssh2.org/download/libssh2-1.9.0.tar.gz"
nghttp2_address_default="https://github.com/nghttp2/nghttp2/releases/download/v1.40.0/nghttp2-1.40.0.tar.gz"
curl_address_default="https://curl.haxx.se/download/curl-7.68.0.tar.gz"
libcrack2_address_default="https://github.com/cracklib/cracklib/archive/v2.9.7.tar.gz"
libXML2_address_default="http://xmlsoft.org/sources/libxml2-2.9.10.tar.gz"
libxslt_address_default="http://xmlsoft.org/sources/libxslt-1.1.34.tar.gz"
php_address_default="https://github.com/php/php-src/archive/php-7.4.2.tar.gz"
nginx_address_default="https://nginx.org/download/nginx-1.17.8.tar.gz"
psol_url="https://www.modpagespeed.com/release_archive/1.13.35.2/psol-1.13.35.2-x64.tar.gz"
#####################################################################################################################
#
# Environment Variables
#
#####################################################################################################################

DEBIAN_VERSION=`cat /etc/debian_version | cut -d . -f 1`
if (( $DEBIAN_VERSION < 9 )); then
    echo "Cancelled: Only run in Debian >= 9"
fi

BASEDIR="$PWD"
MACHINE_TYPE=`uname -m`
TRAVISFOLDNAME=/tmp/.travis_fold_name

NUMCPUS=`nproc`
NUMJOBS=`expr $NUMCPUS + 1`

alias make="make -j${NUMJOBS}"

if [ "$MACHINE_TYPE" == "i386" ]; then
    export CPPFLAGS="-I/usr/local/include -I/usr/include/i386-linux-gnu"
fi

if [ "$MACHINE_TYPE" == "x86_64" ]; then
    export CPPFLAGS="-I/usr/local/include -I/usr/include/x86_64-linux-gnu"
fi

export CFLAGS="-march=native -O2 -ftree-vectorize -pipe"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib"
export LDCONFIG=-L/usr/local/lib
export LIBS="-ldl"

source /etc/profile

#####################################################################################################################
#
# Functions
#
#####################################################################################################################

travis_fold() {
  local action=$1
  local name=$2
  echo -en "travis_fold:${action}:${name}\r"
}

travis_fold_start() {
  travis_fold start $1
  echo $1
  echo -n $1 > $TRAVISFOLDNAME
}

travis_fold_end() {
  travis_fold end "$(cat ${TRAVISFOLDNAME})"
}

function wgetAndDecompress() {

  local dirTmp=$1
  local folderTmp=$2
  local downloadAddress=$3

  if [ -z $dirTmp ] || [ -z $folderTmp ] || [ -z $downloadAddress ]
  then
    read -n 1 -s -p "Critical error in wgetAndDecompress() - create directories" && echo -e "\n"
    exit 1
  fi

  # tar.gz or tar.xz -> .tar
  mkdir -p $dirTmp
  wget --no-check-certificate -O $dirTmp/$folderTmp.tar $downloadAddress

  if [ ! -f $dirTmp/$folderTmp.tar ]
  then
      read -n 1 -s -p "Critical error in wgetAndDecompress() - file download" && echo -e "\n"
      exit 1
  fi

  mkdir -p $dirTmp/$folderTmp
  rm -Rf ${dirTmp:?}/$folderTmp/*
  tar -xvf $dirTmp/$folderTmp.tar -C $dirTmp/$folderTmp --strip-components=1 > /dev/null
  cd $dirTmp/$folderTmp || exit 1

}

function pauseToContinue() {
  if [ "$AutoDebug" != "Y" ]
  then
    read -n 1 -s -p "Press any key to continue" && echo -e "\n"
  fi
}

# use: askOption question defaultOption skipQuestion
function askOption() {

  local question="$1"
  local defaultOption="$2"
  local skipQuestion="$3"
  returnOption="$defaultOption"

  if [ "$skipQuestion" != "Y" ]
  then
    returnOption="$defaultOption"
    read -e -i "$defaultOption" -p "$question" userOption
    returnOption="${userOption:-$defaultOption}"
  fi

  echo "$returnOption"

}

function service_stop() {
  # Func askOption (question, defaultOption, skipQuestion)
  input_install_service_stop="$(askOption "Stop All Services? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_service_stop == "Y" ] || [ $input_install_service_stop == "y" ]
  then

    service nginx stop
    service php7-fpm stop

  fi
}

function clear_compile() {

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_clear_compile="$(askOption "Clear Compile ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_clear_compile == "Y" ] || [ $input_install_clear_compile == "y" ]
  then

    rm -rf /var/tmp/*_build

    apt-get -y remove libxau-dev libxdmcp-dev xorg-sgml-doctools \
    docbook-xsl docbook-xml needrestart autoconf autogen autopoint \
    automake m4 bison build-essential g++ pkg-config \
    autotools-dev libtool expect \
    libcunit1-dev x11proto-core-dev file \
    libenchant-dev gnu-standards \
    autoconf-archive g++-multilib gcc-multilib \
    libstdc++-6-dev gcc-6-locales \
    g++-6-multilib valgrind valgrind-mpi \
    valkyrie gcj-jdk flex tk-dev
    # libjemalloc-dev
    apt-get -y autoremove
    apt-get clean
    ccache -C

  fi


}

function essential_install() {
  #####################################################################################################################
  #
  # Install Essential
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_delete_build="$(askOption "Delete building directories ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_delete_build == "Y" ] || [ $input_delete_build == "y" ]
  then
    rm -rf /var/tmp/*_build
  fi

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_essential="$(askOption "Install Essential ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_essential == "Y" ] || [ $input_install_essential == "y" ]
  then

    # Build Essential
    sed -i '/^#\sdeb-src /s/^#//' "/etc/apt/sources.list"

    apt-get -y update

    chmod 666 /etc/environment
    truncate -s 0 /etc/environment
    echo -e "LC_ALL=en_US.UTF-8\n" >> /etc/environment
    echo -e "LC_CTYPE=UTF-8\n" >> /etc/environment
    echo -e "LANG=en_US.UTF-8\n" >> /etc/environment
    chmod 644 /etc/environment
    apt-get -y install locales
    locale-gen en_US.UTF-8

    apt-get -y upgrade
    apt-get -y dist-upgrade

    # TODO: check this: Packages that can be deleted after the script is finished.
    apt-get -y install libxau-dev libxdmcp-dev xorg-sgml-doctools \
    docbook-xsl docbook-xml needrestart autoconf autogen autopoint \
    automake m4 bison build-essential g++ pkg-config \
    autotools-dev libtool expect \
    libcunit1-dev x11proto-core-dev file \
    libenchant-dev gnu-standards \
    autoconf-archive g++-multilib gcc-multilib \
    libstdc++-6-dev gcc-6-locales \
    g++-6-multilib valgrind valgrind-mpi \
    valkyrie gcj-jdk flex tk-dev
    # libjemalloc-dev

    # TODO: check this: Important packages that must be installed.
    apt-get -y install coreutils binutils ccache uuid-dev wget \
    mcrypt cython perl libpcre3 bzip2 xsltproc \
    trousers libidn2-0 libtiffxx5 libexpat1-dev \
    libc-dbg gettext debian-keyring liblinear-tools \
    libdbi-perl rsync net-tools libdbd-mysql-perl \
    re2c qt4-qmake golang python-setuptools \
    libc-ares-dev libpcre3-dev libxml2-dev libxslt1-dev \
    libfreetype6-dev libfontconfig1-dev \
    libjpeg62-turbo-dev libjpeg-dev libpng-dev \
    libbz2-dev zlib1g-dev libzip-dev \
    libjansson-dev libmcrypt-dev \
    libgmp-dev libev-dev libevent-dev \
    libsqlite3-dev libgdbm-dev libdb-dev \
    libsystemd-dev libspdylay-dev \
    libaio-dev libncurses5-dev libncursesw5-dev libboost-all-dev \
    libunistring-dev libunbound-dev libqt4-dev \
    libicu-dev libltdl-dev libreadline-dev \
    libaspell-dev libpspell-dev \
    libc6-dev libpam0g-dev libmsgpack-dev libstemmer-dev libbsd-dev \
    liblinear-dev libssl-dev libboost-dev libboost-thread-dev \
    python-dev python3-dev python3-venv libffi-dev unzip git libonig-dev

    if [ -f /usr/lib/ccache ]; then
        export PATH=/usr/lib/ccache:$PATH
        echo "export PATH=$PATH" >> /etc/profile
        source /etc/profile
    fi

    apt-get -y upgrade
    apt-get -y autoremove

    apt-get -y remove --purge --auto-remove curl
    apt-get -y remove --purge --auto-remove cmake*

    apt-get -y build-dep curl
    apt-get -y build-dep zlib
    apt-get -y build-dep openssl

    apt-get -y upgrade
    apt-get -y autoremove

    apt-get clean

    if [ "$ProgramName" != "travis" ]
    then
      tzselect
      dpkg-reconfigure tzdata
    fi

    pauseToContinue

    # Func askOption (question, defaultOption, skipQuestion)
    input_install_reboot="$(askOption "Reboot ? [y/N]: " "N" $AutoDebug)"

    if [ $input_install_reboot == "Y" ] || [ $input_install_reboot == "y" ]
    then
      reboot
      exit 0
    fi

  fi
}

function jemalloc_install() {
  #####################################################################################################################
  #
  # INSTALL jemalloc 5.1.0 - https://github.com/jemalloc/jemalloc/archive/5.1.0.tar.gz
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_jemalloc="$(askOption "Install jemalloc ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_jemalloc == "Y" ] || [ $input_install_jemalloc == "y" ]
  then

    # Func askOption (question, defaultOption, skipQuestion)
    jemalloc_address="$(askOption "Enter the download address for jemalloc (tar.gz): " $jemalloc_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    jemalloc_install_tmp_dir="$(askOption "Enter temporary directory for jemalloc compilation: " "/var/tmp/jemalloc_build" $AutoDebug)"

    # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
    wgetAndDecompress $jemalloc_install_tmp_dir jemalloc_src $jemalloc_address

    ./autogen.sh

    ./configure --prefix=/usr/local --with-xslroot=/usr/share/xml/docbook/stylesheet/docbook-xsl/

    make
    make dist
    make install

    echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf

    ldconfig

    pauseToContinue

  fi
}

function cmake_install() {
  #####################################################################################################################
  #
  # INSTALL cmake (Tested with 3.13.4 - https://cmake.org/files/v3.13/cmake-3.13.4.tar.gz)
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_cmake="$(askOption "Install cmake ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_cmake == "Y" ] || [ $input_install_cmake == "y" ]
  then

    # Func askOption (question, defaultOption, skipQuestion)
    cmake_address="$(askOption "Enter the download address for cmake (tar.gz): " $cmake_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    cmake_install_tmp_dir="$(askOption "Enter temporary directory for cmake compilation: " "/var/tmp/cmake_build" $AutoDebug)"

    # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
    wgetAndDecompress $cmake_install_tmp_dir "cmake_src" $cmake_address

    ./bootstrap

    make
    make install

    ldconfig

    cmake --version

    pauseToContinue

  fi
}

function openssl_install() {
  #####################################################################################################################
  #
  # INSTALL OpenSSL (Tested with 1.1.1a - https://www.openssl.org/source/openssl-1.1.1a.tar.gz)
  # config file: /usr/local/ssl/openssl.cnf
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_openssl="$(askOption "Install OpenSSL ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_openssl == "Y" ] || [ $input_install_openssl == "y" ]
  then

    # Func askOption (question, defaultOption, skipQuestion)
    openssl_address="$(askOption "Enter the download address for OpenSSL (tar.gz): " $openssl_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    openssl_install_tmp_dir="$(askOption "Enter temporary directory for OpenSSL compilation: " "/var/tmp/openssl_build" $AutoDebug)"

    # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
    wgetAndDecompress $openssl_install_tmp_dir "openssl_src" $openssl_address
    ./config -Wl,--enable-new-dtags,-rpath,'$(LIBRPATH)' no-comp no-zlib no-zlib-dynamic enable-ec_nistp_64_gcc_128 enable-tls1_3 shared

    make
    make test
    make MANSUFFIX=ssl install

    echo "export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt" >> /etc/profile
    echo "export SSL_CERT_DIR=/etc/ssl/certs/" >> /etc/profile
    source /etc/profile

    ldconfig
    ldconfig -p | grep libcrypto

    whereis openssl
    openssl version -v

    pauseToContinue

    needrestart -r l

  fi
}

function python2_install() {

  #####################################################################################################################
  #
  # INSTALL Python (Tested with 2.7.15 - https://www.python.org/ftp/python/2.7.15/Python-2.7.15.tar.xz)
  #
  #####################################################################################################################

  input_install_python="$(askOption "Install Python2 ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_python == "Y" ] || [ $input_install_python == "y" ]
  then

    # Func askOption (question, defaultOption, skipQuestion)
    python_address="$(askOption "Enter the download address for Python2 (tar.gz): " $python_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    python_install_tmp_dir="$(askOption "Enter temporary directory for Python2 compilation: " "/var/tmp/python_build" $AutoDebug)"

    # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
    wgetAndDecompress $python_install_tmp_dir "python_src" $python_address

    if [ "$ProgramName" != "travis" ]
    then
      ./configure --prefix=/usr/local --enable-shared --enable-optimizations
    else
      ./configure --prefix=/usr/local --enable-shared
    fi

    make
    make install

    wget https://bootstrap.pypa.io/get-pip.py
    chmod +x get-pip.py
    python get-pip.py

    python --version
    pip install --upgrade pip virtualenv setuptools wheel pyopenssl
    pip -V

  fi

}

function python3_install() {

  #####################################################################################################################
  #
  # INSTALL Python (Tested with 3.7.2 - https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tgz)
  #
  #####################################################################################################################

  input_install_python="$(askOption "Install Python3 ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_python == "Y" ] || [ $input_install_python == "y" ]
  then

    # Func askOption (question, defaultOption, skipQuestion)
    python_address="$(askOption "Enter the download address for Python3 (tar.gz): " $python3_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    python_install_tmp_dir="$(askOption "Enter temporary directory for Python3 compilation: " "/var/tmp/python3_build" $AutoDebug)"

    # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
    wgetAndDecompress $python_install_tmp_dir "python3_src" $python_address

    if [ "$ProgramName" != "travis" ]
    then
      ./configure --prefix=/usr/local --enable-shared --enable-optimizations
    else
      ./configure --prefix=/usr/local --enable-shared
    fi

    make
    make altinstall

    python3.8 --version
    python3.8 -m pip install --upgrade pip virtualenv setuptools wheel pyopenssl
    python3.8 -m pip -V

  fi

}

function zlib_install() {
  #####################################################################################################################
  #
  # INSTALL zlib (Tested with 1.2.11 - http://www.zlib.net/zlib-1.2.11.tar.gz)
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_zlib="$(askOption "Install zlib ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_zlib == "Y" ] || [ $input_install_zlib == "y" ]
  then

    # Func askOption (question, defaultOption, skipQuestion)
    zlib_address="$(askOption "Enter the download address for zlib (tar.gz): " $zlib_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    zlib_install_tmp_dir="$(askOption "Enter temporary directory for zlib compilation: " "/var/tmp/zlib_build" $AutoDebug)"

    # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
    wgetAndDecompress $zlib_install_tmp_dir "zlib_src" $zlib_address

    ./configure --shared

    make
    make install

    ldconfig

    pauseToContinue

  fi
}

function lz4_install() {
  #####################################################################################################################
  #
  # INSTALL LZ4 (Tested with v1.8.3 - https://github.com/lz4/lz4/archive/v1.8.3.tar.gz)
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_lz4="$(askOption "Install lz4 ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_lz4 == "Y" ] || [ $input_install_lz4 == "y" ]
  then

    # Func askOption (question, defaultOption, skipQuestion)
    lz4_address="$(askOption "Enter the download address for lz4 (tar.gz): " $lz4_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    lz4_install_tmp_dir="$(askOption "Enter temporary directory for lz4 compilation: " "/var/tmp/lz4_build" $AutoDebug)"

    wgetAndDecompress $lz4_install_tmp_dir "lz4_src" $lz4_address

    make
    make install

    ldconfig

    lz4 -V

    pauseToContinue

  fi
}

function libzip_install() {
  #####################################################################################################################
  #
  # INSTALL libzip (Tested with 1.5.1 - https://libzip.org/download/libzip-1.5.1.tar.gz)
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_libzip="$(askOption "Install libzip ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_libzip == "Y" ] || [ $input_install_libzip == "y" ]
  then

    # Func askOption (question, defaultOption, skipQuestion)
    libzip_address="$(askOption "Enter the download address for libzip (tar.gz): " $libzip_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    libzip_install_tmp_dir="$(askOption "Enter temporary directory for libzip compilation: " "/var/tmp/libzip_build" $AutoDebug)"

    # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
    wgetAndDecompress $libzip_install_tmp_dir "libzip_src" $libzip_address

    mkdir build
    cd build
    cmake ..
    make
    make test
    make install

    ldconfig

    pauseToContinue

  fi
}

function libssh2_install() {
  #####################################################################################################################
  #
  # INSTALL libssh2 (Tested with 1.8.0 - https://libssh2.org/download/libssh2-1.8.0.tar.gz)
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_libssh2="$(askOption "Install libssh2 ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_libssh2 == "Y" ] || [ $input_install_libssh2 == "y" ]
  then

    # Func askOption (question, defaultOption, skipQuestion)
    libssh2_address="$(askOption "Enter the download address for libssh2 (tar.gz): " $libssh2_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    libssh2_install_tmp_dir="$(askOption "Enter temporary directory for libssh2 compilation: " "/var/tmp/libssh2_build" $AutoDebug)"

    wgetAndDecompress $libssh2_install_tmp_dir "libssh2_src" $libssh2_address

    ./configure --with-openssl --with-libssl-prefix=/usr/local --with-libz --with-libz-prefix=/usr/local

    make
    make install

    ldconfig

    pauseToContinue

  fi
}

function nghttp2_install() {
  #####################################################################################################################
  #
  # INSTALL Nghttp2: HTTP/2 C Library
  # (Tested with v1.36.0 - https://github.com/nghttp2/nghttp2/releases/download/v1.36.0/nghttp2-1.36.0.tar.gz)
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_nghttp2="$(askOption "Install Nghttp2 ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_nghttp2 == "Y" ] || [ $input_install_nghttp2 == "y" ]
  then

    # Func askOption (question, defaultOption, skipQuestion)
    nghttp2_address="$(askOption "Enter the download address for Nghttp2 (tar.gz): " $nghttp2_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    nghttp2_install_tmp_dir="$(askOption "Enter temporary directory for Nghttp2 compilation: " "/var/tmp/nghttp2_build" $AutoDebug)"

    wgetAndDecompress $nghttp2_install_tmp_dir "nghttp2_src" $nghttp2_address

    ./configure

    make
    make install

    ldconfig

    pauseToContinue

  fi
}

function curl_install() {
  #####################################################################################################################
  #
  # INSTALL curl (Tested with 7.63.0 - https://curl.haxx.se/download/curl-7.63.0.tar.gz)
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_curl="$(askOption "Install curl ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_curl == "Y" ] || [ $input_install_curl == "y" ]
  then

    # Func askOption (question, defaultOption, skipQuestion)
    curl_address="$(askOption "Enter the download address for CURL (tar.gz) ? [Y/n]: " $curl_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    curl_install_tmp_dir="$(askOption "Enter temporary directory for CURL compilation: " "/var/tmp/curl_build" $AutoDebug)"

    # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
    wgetAndDecompress $curl_install_tmp_dir "curl_src" $curl_address

    ./buildconf

    ./configure --enable-versioned-symbols --enable-threaded-resolver --with-libssl-prefix=/usr/local --with-ca-path=/etc/ssl/certs --with-ssl --with-zlib --with-nghttp2 --with-libssh2

    make
    make install

    ldconfig

    curl -V

    pauseToContinue

  fi
}

function libcrack2_install() {
  #####################################################################################################################
  #
  # INSTALL libcrack2  (Tested with 2.9.6 - https://github.com/cracklib/cracklib/archive/cracklib-2.9.6.tar.gz)
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_libcrack2="$(askOption "Install libcrack2 ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_libcrack2 == "Y" ] || [ $input_install_libcrack2 == "y" ]
  then

    # Func askOption (question, defaultOption, skipQuestion)
    libcrack2_address="$(askOption "Enter the download address for libcrack2 (tar.gz): " $libcrack2_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    libcrack2_install_tmp_dir="$(askOption "Enter temporary directory for libcrack2 compilation: " "/var/tmp/libcrack2_build" $AutoDebug)"

    wgetAndDecompress $libcrack2_install_tmp_dir "libcrack2_src" $libcrack2_address

    cd ./src || exit 1

    sed -i '/skipping/d' util/packer.c

    mkdir -p /usr/local/lib/cracklib/pw_dict

    ./autogen.sh

    ./configure --prefix=/usr/local

    make
    make install
    make installcheck

    ldconfig

    pauseToContinue

    cd ../words || exit 1

    make all

    install -v -m644 -D  ./cracklib-words.gz /usr/share/dict/cracklib-words.gz
    gunzip -v /usr/share/dict/cracklib-words.gz
    ln -v -sf cracklib-words /usr/share/dict/words
    install -v -m755 -d /usr/local/lib/cracklib
    #create-cracklib-dict /usr/share/dict/cracklib-words /usr/share/dict/cracklib-extra-words
    create-cracklib-dict /usr/share/dict/cracklib-words

    pauseToContinue

  fi
}

function libxml2_install() {
  #####################################################################################################################
  #
  # INSTALL LibXML2  (Tested with 2.9.9 - http://xmlsoft.org/sources/libxml2-2.9.9.tar.gz)
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_libXML2="$(askOption "Install LibXML2 ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_libXML2 == "Y" ] || [ $input_install_libXML2 == "y" ]
  then

    # Func askOption (question, defaultOption, skipQuestion)
    libXML2_address="$(askOption "Enter the download address for LibXML2 (tar.gz): " $libXML2_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    libXML2_install_tmp_dir="$(askOption "Enter temporary directory for LibXML2 compilation: " "/var/tmp/libXML2_build" $AutoDebug)"

    wgetAndDecompress $libXML2_install_tmp_dir "libXML2_src" $libXML2_address

    ./configure --prefix=/usr/local --with-history

    make
    make install

    ldconfig

    pauseToContinue

  fi
}

function libxslt_install() {
  #####################################################################################################################
  #
  # INSTALL libxslt  (Tested with 1.1.33 - http://xmlsoft.org/sources/libxslt-1.1.33.tar.gz)
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_libxslt="$(askOption "Install libxslt ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_libxslt == "Y" ] || [ $input_install_libxslt == "y" ]
  then

    # Func askOption (question, defaultOption, skipQuestion)
    libxslt_address="$(askOption "Enter the download address for libxslt (tar.gz): " $libxslt_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    libxslt_install_tmp_dir="$(askOption "Enter temporary directory for libxslt compilation: " "/var/tmp/libxslt_build" $AutoDebug)"

    wgetAndDecompress $libxslt_install_tmp_dir "libxslt_src" $libxslt_address

    ./configure --prefix=/usr/local

    make
    make install

    ldconfig

    pauseToContinue

  fi
}

function mariadb_install() {
  #
  # -- This function is little tested by the main developer. --
  #
  #####################################################################################################################
  #
  # INSTALL MariaDB 10.4 - http://espejito.fder.edu.uy/mariadb/repo/10.4/debian stretch main
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_mariadb="$(askOption "Install MariaDB Client? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_mariadb == "Y" ] || [ $input_install_mariadb == "y" ]
  then

    apt-get -y install software-properties-common dirmngr
    apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
    add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://espejito.fder.edu.uy/mariadb/repo/10.4/debian stretch main'
    apt-get -y update
    apt-get -y install libmariadb-dev mariadb-client
    ln -s /usr/bin/mariadb_config /usr/bin/mysql_config

    pauseToContinue

  fi
}

function php_install() {
  #####################################################################################################################
  #
  # INSTALL PHP (Tested with 7.3.2 - https://github.com/php/php-src/archive/php-7.3.2.tar.gz)
  # use config file from: https://github.com/kasparsd/php-7-debian/
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_php="$(askOption "Install PHP ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_php == "Y" ] || [ $input_install_php == "y" ]
  then

    adduser --system --no-create-home --disabled-login --disabled-password --group www-data

    # Func askOption (question, defaultOption, skipQuestion)
    php_address="$(askOption "Enter the download address for PHP 7 (tar.gz): " $php_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    php_install_tmp_dir="$(askOption "Enter temporary directory for php compilation: " "/var/tmp/php_build" $AutoDebug)"

    # Func wgetAndDecompress (dirTmp, folderTmp, downloadAddress)
    wgetAndDecompress $php_install_tmp_dir "php_src" $php_address

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
    --enable-gd \
    --with-jpeg \
    --enable-mbstring \
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
    --with-zlib \
    --enable-zip \
    --with-readline \
    --with-curl \
    --enable-simplexml \
    --enable-xmlreader \
    --enable-xmlwriter \
    --enable-fpm \
    --with-fpm-user=www-data \
    --with-fpm-group=www-data \
    --with-libxml=/usr/local \
    --enable-wddx \
    --disable-rpath \
    --enable-inline-optimization \
    --enable-mbregex \
    --with-xsl \
    --enable-opcache \
    --enable-static"

    ./configure $CONFIGURE_STRING

    make

    make install

    # Socket
    mkdir -p /run/php

    # Create a dir for storing PHP module conf
    mkdir /usr/local/php7/etc/conf.d

    # Symlink php-fpm to php7-fpm
    ln -s /usr/local/php7/sbin/php-fpm /usr/local/php7/sbin/php7-fpm

    # Generate backup configuration file php.ini
    cp php.ini-production /usr/local/php7/lib/php.ini-production
    cp php.ini-development /usr/local/php7/lib/php.ini-development
    # PHP configuration file
    cp php.ini-production /usr/local/php7/lib/php.ini
    # Enable PDO extension for mysql and extension mysqli, mysqlnd
    echo -e 'extension=mysqlnd.so\n' >> /usr/local/php7/lib/php.ini
    echo -e 'extension=mysqli.so\n' >> /usr/local/php7/lib/php.ini
    echo -e 'extension=pdo_mysql.so\n' >> /usr/local/php7/lib/php.ini
    echo -e 'openssl.cafile=/etc/ssl/certs/ca-certificates.crt\n' >> /usr/local/php7/lib/php.ini
    echo -e 'curl.cainfo=/etc/ssl/certs/ca-certificates.crt\n' >> /usr/local/php7/lib/php.ini
    # It is important that we prevent Nginx from passing requests to the PHP-FPM backend if the file does not exists
    sed -ie 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /usr/local/php7/lib/php.ini

    cp ${BASEDIR}/files/php7/etc/php-fpm.d/www.conf /usr/local/php7/etc/php-fpm.d/www.conf

    cp ${BASEDIR}/files/php7/etc/php-fpm.conf /usr/local/php7/etc/php-fpm.conf

    cp ${BASEDIR}/files/php7/etc/conf.d/modules.ini /usr/local/php7/etc/conf.d/modules.ini

    # Add the init script
    cp ${BASEDIR}/files/php7/etc/init.d/php7-fpm /etc/init.d/php7-fpm
    chmod +x /etc/init.d/php7-fpm
    update-rc.d php7-fpm defaults

    export PATH=$PATH:/usr/local/php7/bin
    echo "export PATH=$PATH" >> /etc/profile
    source /etc/profile

    chmod 666 /etc/environment
    echo -e "PATH=$PATH\n" >> /etc/environment
    chmod 644 /etc/environment

    ln -s /usr/local/php7/bin/php /usr/sbin/php

    /usr/local/php7/bin/php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    /usr/local/php7/bin/php composer-setup.php --install-dir=/usr/local/bin --filename=composer

    ldconfig

    service php7-fpm start
    service php7-fpm status

    needrestart -r l

    pauseToContinue

  fi
}

function nginx_install() {
  #####################################################################################################################
  #
  # INSTALL nginx (Tested with 1.15.8 - https://nginx.org/download/nginx-1.15.8.tar.gz)
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_nginx="$(askOption "Install nginx ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_install_nginx == "Y" ] || [ $input_install_nginx == "y" ]
  then

    adduser --system --no-create-home --disabled-login --disabled-password --group www-data
    usermod -a -G www-data root
    usermod -a -G www-data admin
    mkdir -p /var/ngx_pagespeed_cache
    chown -R www-data:www-data /var/ngx_pagespeed_cache

    # download ngx_pagespeed:

    # Func askOption (question, defaultOption, skipQuestion)
    nginx_address="$(askOption "Enter the download address for nginx (tar.gz): " $nginx_address_default $AutoDebug)"

    # Func askOption (question, defaultOption, skipQuestion)
    nginx_install_tmp_dir="$(askOption "Enter temporary directory for nginx compilation: " "/var/tmp/nginx_build" $AutoDebug)"

    wgetAndDecompress $nginx_install_tmp_dir "nginx_src" $nginx_address

    # Module pagespeed
    NPS_VERSION=1.13.35.2-stable
    wget https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}.zip
    unzip v${NPS_VERSION}.zip
    nps_dir=$(find . -name "*pagespeed-ngx-${NPS_VERSION}" -type d)
    cd "$nps_dir"
    [ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
    wget ${psol_url}
    tar -xzvf $(basename ${psol_url})

    cd ..

    # Module Naxsi
    # wget https://github.com/nbs-system/naxsi/archive/master.zip
    # unzip master.zip

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
      --with-file-aio \
      --with-http_realip_module \
      --with-http_sub_module \
      --with-ld-opt="-L/usr/local/lib -Wl,-rpath,/usr/local/lib -ljemalloc" \
      --with-cc-opt="-m64 -march=native -DTCP_FASTOPEN=23 -g -O3 -fstack-protector-strong -fuse-ld=gold --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -gsplit-dwarf" \
      --add-module="${nginx_install_tmp_dir}/nginx_src/${nps_dir}"
      # --add-module="${nginx_install_tmp_dir}/nginx_src/naxsi-master/naxsi_src"

    make
    make install

    mkdir -p /etc/nginx/ssl/

    # is discarded for rapid tests
    if [ "$ProgramName" != "travis" ]
    then
      openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
    fi

    mkdir -p /var/www/${global_domain}/htdocs
    chgrp www-data /var/www/${global_domain}/htdocs

    # FILE: /etc/nginx/nginx.conf
    rm /etc/nginx/nginx.conf
    cp ${BASEDIR}/files/nginx/nginx.conf /etc/nginx/nginx.conf

    # FILE: /etc/nginx/conf.d/*
    mkdir -p /etc/nginx/conf.d/
    cp ${BASEDIR}/files/nginx/conf.d/mail.conf /etc/nginx/conf.d/mail.conf

    # FILE: /etc/nginx/snippets/*
    mkdir -p /etc/nginx/snippets/
    cp -r ${BASEDIR}/files/nginx/snippets/* /etc/nginx/snippets/
    # Modify file
    sed -i "s#XXDOMAINXX#${global_domain}#g" /etc/nginx/snippets/diffie-hellman

    # FILE: /etc/nginx/sites-available/*
    mkdir -p /etc/nginx/sites-available/
    cp ${BASEDIR}/files/nginx/sites-available/xxdomainxx.conf /etc/nginx/sites-available/${global_domain}.conf
    # Modify file
    sed -i "s#XXDOMAINXX#${global_domain}#g" /etc/nginx/sites-available/${global_domain}.conf

    # DIR: /etc/nginx/sites-enabled/
    mkdir -p /etc/nginx/sites-enabled/
    ln -s /etc/nginx/sites-available/${global_domain}.conf /etc/nginx/sites-enabled/${global_domain}.conf

    # FILE: /lib/systemd/system/nginx.service
    #cp ${BASEDIR}/files/nginx/systemd/nginx.service /lib/systemd/system/nginx.service
    #chmod +x /lib/systemd/system/nginx.service
    #update-rc.d nginx defaults

    # FILE: /etc/init.d/nginx
    cp ${BASEDIR}/files/nginx/init.d/nginx /etc/init.d/nginx
    chmod +x /etc/init.d/nginx
    update-rc.d nginx defaults

    needrestart -r l

    service nginx start
  	service nginx status

  	pauseToContinue

  fi
}

function letsencrypt_install(){
    #####################################################################################################################
    #
    # Let’s Encrypt with NGINX (https://github.com/certbot/certbot)
    #
    #####################################################################################################################

    # Func askOption (question, defaultOption, skipQuestion)
    input_install_letEncrypt="$(askOption "Install Let’s Encrypt ? [Y/n]: " "Y" $AutoDebug)"

    if [ $input_install_letEncrypt == "Y" ] || [ $input_install_letEncrypt == "y" ]
    then

        mkdir -p /opt/letsencrypt/
        cd /opt/letsencrypt/ || exit 1

        wget https://dl.eff.org/certbot-auto -P /opt/letsencrypt/
        chmod a+x /opt/letsencrypt/certbot-auto

        # [TESTING] patches
        cp -r ${BASEDIR}/files/letsencrypt/patches/* /opt/letsencrypt/
        patch /opt/letsencrypt/certbot-auto -i /opt/letsencrypt/certbot-auto.patch -o /opt/letsencrypt/certbot-auto-patched
        chmod a+x /opt/letsencrypt/certbot-auto-patched

        if [ "$ProgramName" != "travis" ]
        then
          letsencrypt_config
        fi

    fi
}

function letsencrypt_config() {
  #####################################################################################################################
  #
  # Let’s Encrypt with NGINX (https://github.com/certbot/certbot)
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_config_letEncrypt="$(askOption "Configure Let’s Encrypt ? [Y/n]: " "Y" $AutoDebug)"

  if [ $input_config_letEncrypt == "Y" ] || [ $input_config_letEncrypt == "y" ]
  then

    mkdir -p /var/www/${global_domain}/letsencrypt
    chgrp www-data /var/www/${global_domain}/letsencrypt

  	# FILE: /etc/letsencrypt/configs/my-domain.conf
  	mkdir -p /etc/letsencrypt/configs/
    cp ${BASEDIR}/files/letsencrypt/configs/xxdomainxx.conf /etc/letsencrypt/configs/${global_domain}.conf
    # Modify file
    sed -i "s#XXDOMAINXX#${global_domain}#g" /etc/letsencrypt/configs/${global_domain}.conf
    sed -i "s#XXEMAILSUPPORTXX#${global_emailSupport}#g" /etc/letsencrypt/configs/${global_domain}.conf

    cd /opt/letsencrypt/ || exit 1
    ./certbot-auto --config /etc/letsencrypt/configs/${global_domain}.conf certonly

    mkdir -p /var/log/letsencrypt/

    # FILE: /etc/letsencrypt/crontab/
    mkdir -p /etc/letsencrypt/crontab/
    cp ${BASEDIR}/files/letsencrypt/crontab/renewLetsEncrypt.sh /etc/letsencrypt/crontab/${global_domain}-renewLetsEncrypt.sh

    # Modify file
    # sed -i "s#XXDOMAINXX#${global_domain}#g" /etc/letsencrypt/crontab/${global_domain}-renewLetsEncrypt.sh

    # Permission for execution
    chmod +x /etc/letsencrypt/crontab/${global_domain}-renewLetsEncrypt.sh
    # Add crontab renew‑letsencrypt
    crontab -l | { cat; echo "0 0 * * * /etc/letsencrypt/crontab/${global_domain}-renewLetsEncrypt.sh"; } | crontab -

    input_config_letEncrypt_isOK="$(askOption "Let’s Encrypt configuration is correct? ? [Y/n]: " "Y" $AutoDebug)"
    if [ $input_config_letEncrypt_isOK == "Y" ] || [ $input_config_letEncrypt_isOK == "y" ]
    then
      # Enabled certificates in configuration file
      sed -i "s/#REMOVE_AFTER_CONFIGURING_LE#//g" /etc/nginx/sites-enabled/${global_domain}.conf
    else
      echo "[warning] Remember to remove the comments '#REMOVE_AFTER_CONFIGURING_LE#' from the file '/etc/nginx/sites-enabled/${global_domain}.conf' after you set up your certificate."
    fi
    # Reload nginx
    service nginx reload

  fi
}

function blackfire_install() {
  #####################################################################################################################
  #
  # blackfire.io - Only Agent - (https://blackfire.io)
  #
  #####################################################################################################################

  # Func askOption (question, defaultOption, skipQuestion)
  input_install_blackfire="$(askOption "Install blackfire.io Agent [Opcional] ? [y/N]: " "N" $AutoDebug)"

  if [ $input_install_blackfire == "Y" ] || [ $input_install_blackfire == "y" ]
  then

  	wget -O - https://packagecloud.io/gpg.key | sudo apt-key add -
  	echo "deb http://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list
  	apt-get update

  	apt-get install blackfire-agent
  	blackfire-agent -register

  	/etc/init.d/blackfire-agent restart

  	apt-get install blackfire-php

  	service nginx reload
  	service php7-fpm reload

  fi
}


#####################################################################################################################
#
# main
#
#####################################################################################################################

ProgramName="$1"
AutoDebug="$2" # If the value is "Y" the script works in automatic mode with the default options for debug

# Func askOption (question, defaultOption, skipQuestion)
global_domain="$(askOption "Enter the domian: " "domian.com" $AutoDebug)"
# Func askOption (question, defaultOption, skipQuestion)
global_emailSupport="$(askOption "Enter email support: " "email@email.com" $AutoDebug)"

# installation options
case "$ProgramName" in
        "essential")
            essential_install
            ;;
        "jemalloc")
            jemalloc_install
            ;;
        "openssl")
            openssl_install
            ;;
        "python")
            python2_install
            ;;
        "python3")
            python3_install
            ;;
        "zlib")
            zlib_install
            ;;
        "lz4")
            lz4_install
            ;;
        "libssh2")
            libssh2_install
            ;;
        "nghttp2")
            nghttp2_install
            ;;
        "curl")
            curl_install
            ;;
        "cmake")
            cmake_install
            ;;
        "libzip")
            libzip_install
            ;;
        "libcrack2")
            libcrack2_install
            ;;
        "libxml2")
            libxml2_install
            ;;
        "libxslt")
            libxslt_install
            ;;
        "mariadb")
            mariadb_install
            ;;
        "php")
            php_install
            ;;
        "nginx")
            nginx_install
            ;;
        "letsencrypt")
            letsencrypt_install
            ;;
        "blackfire")
            blackfire_install
            ;;
        "all")
            service_stop
            essential_install
            jemalloc_install
            openssl_install
            zlib_install
            lz4_install
            cmake_install
            libzip_install
            python2_install
            python3_install
            libssh2_install
            nghttp2_install
            curl_install
            libcrack2_install
            libxml2_install
            libxslt_install
            mariadb_install
            php_install
            nginx_install
            letsencrypt_install
            blackfire_install
            clear_compile
            ;;
        "travis")
            export DEBIAN_FRONTEND=noninteractive

            travis_fold_start essential
              essential_install 2>&1 > /dev/null
            travis_fold_end

            travis_fold_start jemalloc
              jemalloc_install 2>&1 > /dev/null
            travis_fold_end

            travis_fold_start openssl
              openssl_install 2>&1 > /dev/null
            travis_fold_end

            travis_fold_start zlib
              zlib_install 2>&1 > /dev/null
            travis_fold_end

            travis_fold_start lz4
              lz4_install 2>&1 > /dev/null
            travis_fold_end

            travis_fold_start cmake
              cmake_install
            travis_fold_end

            travis_fold_start libzip
              libzip_install 2>&1 > /dev/null
            travis_fold_end

            travis_fold_start python2
              python2_install  2>&1 > /dev/null
            travis_fold_end

            travis_fold_start python3
              python3_install  2>&1 > /dev/null
            travis_fold_end

            travis_fold_start libssh2
              libssh2_install 2>&1 > /dev/null
            travis_fold_end

            travis_fold_start nghttp2
              nghttp2_install 2>&1 > /dev/null
            travis_fold_end

            travis_fold_start curl
              curl_install 2>&1 > /dev/null
            travis_fold_end

            travis_fold_start libcrack2
              libcrack2_install 2>&1 > /dev/null
            travis_fold_end

            travis_fold_start libxml2
              libxml2_install 2>&1 > /dev/null
            travis_fold_end

            travis_fold_start libxslt
              libxslt_install 2>&1 > /dev/null
            travis_fold_end

            travis_fold_start mariadb
             mariadb_install 2>&1 > /dev/null
            travis_fold_end

            travis_fold_start php
              php_install
            travis_fold_end

            travis_fold_start nginx
              nginx_install 2>&1 > /dev/null
            travis_fold_end

            travis_fold_start letsencrypt
              letsencrypt_install
            travis_fold_end

            # blackfire_install

            travis_fold_start clear_compile
              clear_compile 2>&1 > /dev/null
            travis_fold_end
            ;;
        *)
            echo $"Usage: sudo $0 {all|program_name} {N|Y}(Automatic mode)"
            exit 1

esac
