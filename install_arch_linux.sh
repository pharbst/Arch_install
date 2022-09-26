# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    install_arch_linux.sh                              :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: pharbst <pharbst@student.42heilbronn.de    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2022/09/18 19:09:13 by pharbst           #+#    #+#              #
#    Updated: 2022/09/26 04:02:02 by pharbst          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#!/bin/bash

#RUNNING THE SCRIPT BLIND CAN RESULT IN UNWANTED DATA LOSS
#READ ALL COMMENTS THEY CAN BE IMPORTANT AND CHANGE VARIABLES AS YOU NEED THEM
#this script works only with a LAN connection
#for install over wlan set up a internetconnection urself and run the script afterwards
#depending on the hardware and internetconnection the key refresh for pacman could take up to 1h grap yourself a cup of coffe and make yourself comfortable


EFI="false"					#set to true if you can use efi
DRIVE=						#path to Drive
DRIVE1=$DRIVE'1'			#path to drive 1st partition normally its the path to drive with a 1 or p1 added at the end
DRIVE2=$DRIVE'2'			#path to drive 1st partition normally its the path to drive with a 2 or p2 added at the end 
VGNAME1="volgroup0"			#name of the volumegroup
LVNAMEROOT="lv_root"		#name of the logical volume for the root directory // keep in mind that that is the space where you install your programms so it shouldn't be smaller than 30 GB also depends what you wanna do with the os
ROOTSPACE="30GB"			#size of the root directory
HOMESPACE="100%FREE"
LVNAMEHOME="lv_home"		#name of the logical volume for the home directory


echo -e "set EFI boot to true if you are using modern hardware
if you are using a VM or old hardware which is not EFI compatiple set EFI to false"
read -p "EFI boot? (true/false): " EFI
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
read -p "choose a name for the Volumegroup default=$VGNAME1: " VGNAME1
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
read -p "choose a name for the Volumegroup default=$VGNAME1: " VGNAME1
vgcreate $VGNAME1 $DRIVE2
fi

read -p "how much space do you need for the root directory? default=$ROOTSPACE: " ROOTSPACE
read -p "choose a name for the root local volume default=$LVNAMEROOT: "	LVNAMEROOT
lvcreate -L $ROOTSPACE $VGNAME1 -n $LVNAMEROOT
read -p "how much space do you need for the home directory? default=$HOMESPACE: " ROOTSPACE
read -p "choose a name for the home local volume default=$LVNAMEHOME: " LVNAMEHOME
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
# genfstab -U -p /mnt >> /mnt/etc/fstab
# cat /mnt/etc/fstab
# # pacman-key --refresh-keys							#uncomment when pacstrap fails or running an old iso restart machine before ruinning script again refreshing keys is timeconsuming can take up to 1h in a VM
# pacstrap -i /mnt
# # pacstrap -i /mnt base
# cp install_arch_linux2.sh /mnt/root
# arch-chroot /mnt
