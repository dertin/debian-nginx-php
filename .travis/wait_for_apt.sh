#!/usr/bin/env bash

SUDO=''
if (( $EUID != 0 )); then
    SUDO='sudo'
fi

$SUDO systemctl stop apt-daily.service apt-daily.timer apt-daily-upgrade.service apt-daily-upgrade.timer
$SUDO systemctl kill --kill-who=all apt-daily.service apt-daily-upgrade.service

$SUDO lsof /var/lib/dpkg/lock

while sleep 1; do
    if [ $($SUDO pgrep apt | wc -l) -lt 1 ] ; then
        echo "apt process done"
        break
    else
        echo "apt process has not done yet"
    fi
done
