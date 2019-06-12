#!/usr/bin/env bash

#Set timezone:
timedatectl set-timezone Europe/Paris

if [ -z "$1" ]
then
    echo "No disk specified for install (typically use /dev/sda if virtualbox). Quitting."
    exit 1
else
    echo "Formatting disk $1"
fi

sgdisk -og $1
sgdisk -n 1:2048:4095 -c 1:"bios" -t 1:ef02 $1
sgdisk -n 2:4096:413695 -c 2:"boot" -t 2:8300 $1
sgdisk -n 3:413696:8802303 -c 3:"root" -t 3:8300 $1
sgdisk -n 4:8802304:10899455 -c 4:"swap" -t 3:8200 $1
ENDSECTOR=`sgdisk -E $1`
sgdisk -n 5:10899456:$ENDSECTOR -c 5:"home" -t 4:8300 $1
sgdisk -p $1

# formatting drive
mkfs.ext4 /dev/sda2, then y

# mount this new drive
mount /dev/sda2 /mnt

# Start install
pacstrap /mnt base

# Generating an fstab
genfstab -U /mnt >> /mnt/etc/fstab

# chroot in to new system
arch-chroot /mnt

# setting time
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc

# set password
passwd

# Installing grub
pacman –S grub os-prober

# Then install
grub-install $1
grub-mkconfig -o /boot/grub/grub.cfg
#(Select the disk, not the partition!)

echo "Done. reboot drive by calling 'reboot'"

exit 0