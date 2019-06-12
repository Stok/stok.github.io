#!/usr/bin/env bash

# chroot in to new system
# arch-chroot /mnt
# Then run this script.

if [ -z "$1" ]
then
    echo "No disk specified for grub install (typically use /dev/sda if virtualbox). Quitting."
    exit 1
else
    echo "Installing grub $1"
fi


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
exit
