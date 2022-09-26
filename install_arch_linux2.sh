# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    install_arch_linux2.sh                             :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: pharbst <pharbst@student.42heilbronn.de    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2022/09/20 18:46:08 by pharbst           #+#    #+#              #
#    Updated: 2022/09/26 05:02:05 by pharbst          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #



#!/bin/bash

EFI=
DRIVE=
DRIVE1=
USER=


pacman -S linux linux-headers linux-firmware nano base-devel openssh networkmanager wpa_supplicant wireless_tools netctl dialog lvm2 git wget ufw sudo << EOF

EOF
hwclock --systohc
read -p "Enter your computername/hostname default=localhost: " HOSTNAME
HOSTNAME=${HOSTNAME:-localhost}
echo $HOSTNAME > /etc/hostname
echo "127.0.0.1	localhost
::1		localhost
127.0.1.1	$HOSTNAME" > /etc/hosts
# ufw allow $SSHPORT
# sed -i '13s/#Port22/Port$SSHPORT/' /etc/ssh/sshd_config
systemctl enable sshd
systemctl enable NetworkManager
sed -i -e 's/^HOOKS.*/HOOKS=(base udev autodetect modconf block lvm2 filesystems keyboard fsck)/g' /etc/mkinitcpio.conf
mkinitcpio -p linux
sed -i -e 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
read -p "Enter a username default=user" USER
USER=${USER:-user}
useradd -m -g users -G wheel $USER
echo "enter sudo password"
passwd
echo "enter userpassword"
passwd $USER
EDITOR=nano
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers
if [ $EFI = false ]
then
pacman -S grub dosfstools os-prober mtools
echo "Grub installation"
grub-install --target=i386-pc --recheck $DRIVE
echo "DONE"
fi

if [ $EFI = true ]
then
pacman -S grub efibootmgr dosfstools os-prober mtools
mkdir /boot/EFI
mount $DRIVE1 /boot/EFI
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
fi
if [ !/boot/grub/locale ]
then
echo "grub/locale does not exist creating directory"
mkdir /boot/grub/locale
fi
echo "copy locale file in /boot/grub/locale"
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
echo "make grubconfig file"
grub-mkconfig -o /boot/grub/grub.cfg
# exit
