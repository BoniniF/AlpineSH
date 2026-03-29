#!/bin/sh

echo ""
echo ""
echo ""
echo -ne "\e[1A"
led=0

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

elif [ "$B" -lt 5 ]; then

echo -ne "ਈ\e[41m██$B\e[0m"
echo $led > /sys/class/leds/input0::capslock/brightness
if [ $led -eq  0 ]; then
led=1
else
led=0
fi

fi

sleep 5

done
# ਈ███ cat /sys/class/power_supply/BAT0/capacity
