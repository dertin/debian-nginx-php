#!/usr/bin/env bash

sudo systemctl stop apt-daily.service apt-daily.timer apt-daily-upgrade.service apt-daily-upgrade.timer
sudo systemctl kill --kill-who=all apt-daily.service apt-daily-upgrade.service

while sleep 1; do
    if [ $(pgrep apt | wc -l) -lt 1 ] ; then
        echo "apt process done"
        break
    else
        echo "apt process has not done yet"
    fi
done
