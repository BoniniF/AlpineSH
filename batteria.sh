#!/bin/sh

echo ""
echo ""
echo ""
echo -ne "\e[1A"

while true ; do

B=$(cat /sys/class/power_supply/BAT0/capacity)

echo -ne "\r"

if [ $B -eq 100 ]; then

echo -ne "ਈ\e[7m100\e[0m"


elif [ "$B" -ge 20 ]; then

echo -ne "ਈ█\e[7m$B\e[0m"


elif [ "$B" -lt 20 ] && [ "$B" -ge 10 ]; then

echo -ne "ਈ\e[41m█$B\e[0m"


elif [ "$B" -lt 10 ]; then

echo -ne "ਈ\e[41m██$B\e[0m"

fi

sleep 5

done
# ਈ███ cat /sys/class/power_supply/BAT0/capacity
