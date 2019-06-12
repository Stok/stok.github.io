#!/usr/bin/env bash

if [ -z "$1" ]
then
    echo "No disk specified for install (typically use /dev/sda if virtualbox). Quitting."
    exit 1
else
    echo "Formatting disk $1"
fi

sgdisk -og $1
sgdisk -n 1:0:+1024KiB -c 1:"bios" -t 1:ef02 $1
sgdisk -n 2:0:+512MiB -c 2:"boot" -t 2:8300 $1
sgdisk -n 3:0:+4GiB -c 3:"root" -t 3:8300 $1
sgdisk -n 4:0:+1024MiB -c 4:"swap" -t 4:8200 $1
ENDSECTOR=`sgdisk -E $1`
sgdisk -n 5:0:$ENDSECTOR -c 5:"home" -t 5:8300 $1
sgdisk -p $1

# formatting drive
mkfs.ext4 /dev/sda3 #, then y
# mount this new root drive
mount /dev/sda3 /mnt

# Make swap
mkswap /dev/sda4
# turn swap on
swapon /dev/sda4

# Make efi
mkfs.fat -F32 /dev/sda2
# Mount
mount /dev/sda2 /boot

#Update pacman keyring
pacman -Sy archlinux-keyring && pacman -Syyu

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