#!/usr/bin/env bash

if [ -z "$1" ]
then
      echo "Formatting disk $1"
else
      echo "No disk specified for install (typically use /dev/sda if virtualbox. Quitting."
      exit 1
fi

sgdisk -og $1
sgdisk -n 1:2048:4095 -c 1:"bios" -t 1:ef02 $1
sgdisk -n 2:4096:413695 -c 2:"boot" -t 2:8300 $1
sgdisk -n 3:413696:8802303 -c 3:"root" -t 3:8300 $1
sgdisk -n 3:8802303:10899455 -c 3:"swap" -t 3:8200 $1
ENDSECTOR=`sgdisk -E $1`
sgdisk -n 4:10899456:$ENDSECTOR -c 4:"home" -t 4:8300 $1
sgdisk -p $1

exit 0