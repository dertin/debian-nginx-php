## Only for temporary test of service travis-ci

apt-get -y update
apt-get -y upgrade
apt-get -y dist-upgrade

apt-get -y install coreutils build-essential expect perl file sudo cron xsltproc docbook-xsl docbook-xml \
libpcre3 libpcre3-dev golang libtiffxx5 libexpat1-dev libfreetype6-dev \
pkg-config libfontconfig1-dev libjpeg62-turbo-dev xorg-sgml-doctools \
x11proto-core-dev libxau-dev libxdmcp-dev needrestart g++ make binutils autoconf automake autotools-dev libtool \
libbz2-dev zlib1g-dev libcunit1-dev libxml2-dev libev-dev libevent-dev libjansson-dev libc-ares-dev \
libjemalloc-dev libsystemd-dev libspdylay-dev cython python3-dev python-setuptools libaio-dev libncurses5-dev \
m4 libunistring-dev libgmp-dev trousers libidn2-0 libunbound-dev \
bison libmcrypt-dev libicu-dev libltdl-dev libjpeg-dev libpng-dev libpspell-dev libreadline-dev \
uuid-dev gnulib libc6-dev libc-dbg libpam0g-dev libmsgpack-dev libstemmer-dev libbsd-dev \
autoconf-archive gnu-standards gettext debian-keyring \
g++-multilib  gcc-multilib flex liblinear-tools liblinear-dev mcrypt \
gcj-jdk valgrind valgrind-mpi valkyrie \
libdbi-perl libboost-all-dev rsync net-tools libdbd-mysql-perl \
re2c needrestart wget

if (( $DEBIAN_VERSION >= 9 )); then
    apt-get -y install libstdc++-6-dev gcc-6-locales g++-6-multilib
    #TODO: compile kytea libkytea-dev
else
    apt-get -y install libstdc++-4.9-dev gcc-4.9-locales g++-4.9-multilib
    apt-get -y install kytea libkytea-dev
fi

apt-get -y upgrade
apt-get -y autoremove

apt-get -y install libssl-dev

apt-get -y remove --purge --auto-remove curl
apt-get -y remove --purge --auto-remove cmake*

apt-get -y build-dep curl
apt-get -y build-dep zlib
apt-get -y build-dep openssl

apt-get -y upgrade
apt-get -y autoremove

echo "Travis CI OK"
