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

# formatting root drive
mkfs.ext4 /dev/sda3
# mount this new root drive as root
mount /dev/sda3 /mnt

# formatting home drive
mkfs.ext4 /dev/sda5
# mount
mount /dev/sda5 /mnt/home

# Make swap
mkswap /dev/sda4
# turn swap on
swapon /dev/sda4

# Make efi
mkfs.fat -F32 /dev/sda2
# Mount
mount /dev/sda2 /mnt/boot

#Update pacman keyring
pacman -Sy archlinux-keyring && pacman -Syyu

# Start install
pacstrap /mnt base

# Generating an fstab
genfstab -U /mnt >> /mnt/etc/fstab
#genfstab -U /home >> /mnt/etc/fstab
#cat /mnt/etc/fstab | awk '!x[$0]++' > /mnt/etc/fstab #remove duplicate lines (swap)

# set password
echo "Setting root password. Caution! keyboard will not be reset upon reboot!"
arch-chroot /mnt passwd

# Installing grub
arch-chroot /mnt pacman -S grub os-prober

# Then install
arch-chroot /mnt grub-install $1
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
#(Select the disk, not the partition!)

echo "Done. reboot drive by calling 'reboot'"
echo "IF YOU ARE USING VIRTUALBOX, REMEBER TO RUN arch_virtualbox_config.sh!!"
exit 0
