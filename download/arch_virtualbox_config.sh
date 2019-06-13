#!/usr/bin/env bash

arch-chroot /mnt cp /etc/netctl/examples/ethernet-dhcp /etc/netctl/virtualbox-ethernet
arch-chroot /mnt sed -i 's/eth0/enp0s3/g' /etc/netctl/virtualbox-ethernet
arch-chroot /mnt sed -i 's/A basic dhcp ethernet connection/Enabling ethernet connection for virtualbox' /etc/netctl/virtualbox-ethernet
arch-chroot /mnt netctl start virtualbox-ethernet