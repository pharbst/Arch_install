# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    install_arch_linux.sh                              :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: pharbst <pharbst@student.42heilbronn.de    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2022/09/18 19:09:13 by pharbst           #+#    #+#              #
#    Updated: 2022/09/26 05:18:18 by pharbst          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#!/bin/bash

#RUNNING THE SCRIPT BLIND CAN RESULT IN UNWANTED DATA LOSS
#READ ALL COMMENTS THEY CAN BE IMPORTANT AND CHANGE VARIABLES AS YOU NEED THEM
#this script works only with a LAN connection
#for install over wlan set up a internetconnection urself and run the script afterwards
#depending on the hardware and internetconnection the key refresh for pacman could take up to 1h grap yourself a cup of coffe and make yourself comfortable


echo -e "set EFI boot to true if you are using modern hardware
if you are using a VM or old hardware which is not EFI compatiple set EFI to false"
read -p "EFI boot? (true/false): " EFI && [[ $EFI == [t][r][u][e] ]] || [[ $EFI == [f][a][l][s][e] ]] || exit 1
echo "set EFI to $EFI"
read -p "pass the path to the drive you wanna install archlinux to example: /dev/sda: " DRIVE
read -p "the disk $DRIVE will be completly formated all data will be lost. 
Are you shure you want to Continue? (yes/No): " confirm && [[ $confirm == [yY][eE][sS] ]] || exit 1
DRIVE1=$DRIVE'1'
DRIVE2=$DRIVE'2'
if [ $EFI = false ]
then
fdisk $DRIVE <<EOF
o
n




t

8e
a
write
EOF
echo "$DRIVE1"
pvcreate --dataalignment 1m $DRIVE1
read -p "choose a name for the Volumegroup default=volgroup0: " VGNAME1
VGNAME1=${VGNAME1:-volgroup0}
echo "creating volume group with name $VGNAME1 on disk $DRIVE1"
vgcreate $VGNAME1 $DRIVE1
fi

if [ $EFI = true ]
then
pvremove $DRIVE2
fdisk $DRIVE << EOF
g
n
1
2048
+128M
t
1
n
2


t
2
30
write
EOF
pvcreate --dataalignment 1m $DRIVE2
read -p "choose a name for the Volumegroup default=volgroup0: " VGNAME1
VGNAME1=${VGNAME1:-volgroup0}
vgcreate $VGNAME1 $DRIVE2
fi

read -p "choose a name for the root local volume default=lv_root: "	LVNAMEROOT
LVNAMEROOT=${LVNAMEROOT:-lv_root}
read -p "how much space do you need for the root directory? default=30GB: " ROOTSPACE
ROOTSPACE=${ROOTSPACE:-30GB}
lvcreate -L $ROOTSPACE $VGNAME1 -n $LVNAMEROOT
read -p "choose a name for the home local volume default=lv_home: " LVNAMEHOME
LVNAMEHOME=${LVNAMEHOME:-lv_home}
read -p "how much space do you need for the home directory? default=100%FREE: " HOMESPACE
HOMESPACE=${HOMESPACE:-100%FREE}
lvcreate -l $HOMESPACE $VGNAME1 -n $LVNAMEHOME
modprobe dm_mod
vgchange -ay
if [ $EFI = true ]
then
mkfs.fat -F32 $DRIVE1
fi
mkfs.ext4 /dev/$VGNAME1/$LVNAMEROOT
mkfs.ext4 /dev/$VGNAME1/$LVNAMEHOME
mount /dev/$VGNAME1/$LVNAMEROOT /mnt
mkdir /mnt/home
mkdir /mnt/etc
mount /dev/$VGNAME1/$LVNAMEHOME /mnt/home
genfstab -U -p /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
pacstrap -i /mnt base << EOF

EOF
sed -i "s/^EFI=.*/EFI=$EFI
DRIVE=$DRIVE
DRIVE1=$DRIVE1/" install_arch_linux2.sh
cp install_arch_linux2.sh /mnt/root
echo "the second part of the install script is in the root directory 
use <cd root> or <cd  > to get there with ls u can check if it is really there"
arch-chroot /mnt
umount -a
reboot
