#!/usr/bin/env bash

mount /dev/sda3 /mnt

arch-chroot /mnt cp /etc/netctl/examples/ethernet-dhcp /etc/netctl/virtualbox-ethernet
arch-chroot /mnt sed -i 's/eth0/enp0s3/g' /etc/netctl/virtualbox-ethernet
arch-chroot /mnt sed -i 's/A basic dhcp ethernet connection/Enabling ethernet connection for virtualbox/g' /etc/netctl/virtualbox-ethernet

umount /mnt
echo "Once you've rebooted, remember to run: netctl start virtualbox-ethernet"