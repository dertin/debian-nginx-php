#!/usr/bin/env bash

SUDO=''
if (( $EUID != 0 )); then
    SUDO='sudo'
fi

$SUDO systemctl list-unit-files | grep apt

$SUDO systemctl stop apt-daily.timer
$SUDO systemctl disable apt-daily.timer
$SUDO systemctl stop apt-daily-upgrade.timer
$SUDO systemctl disable apt-daily-upgrade.timer
$SUDO systemctl mask apt-daily.service
$SUDO systemctl mask apt-daily-upgrade.service

$SUDO pgrep apt | wc -l

while sleep 1; do
    if [ $($SUDO pgrep apt | wc -l) -lt 1 ] ; then
        echo "apt process done"
        break
    else
        echo "apt process has not done yet"
    fi
done

$SUDO ps ax | grep apt
$SUDO killall apt apt-get
$SUDO ps ax | grep apt
