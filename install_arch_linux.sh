#!/bin/bash


pacman -Sy
pacman -S --noconfirm dialog
# dialog           --clear  "" 0 0 \
#     --and-widget --clear "" 0 0 \
#     --and-widget --clear "" 0 0 \
#     --and-widget --clear "" 0 0 \
#     --and-widget --clear "" 0 0 \
#     --and-widget --clear "" 0 0 \
#     --and-widget --clear "" 0 0 \
#     --and-widget --clear "" 0 0 \
#     --and-widget --clear "" 0 0 \
#     --and-widget --clear "" 0 0 \
echo -e "set EFI boot to true if you are using modern hardware
if you are using a VM or old hardware which is not EFI compatiple set EFI to false"
read -p "EFI boot? (true/false): " EFI && [[ $EFI == [t][r][u][e] ]] || [[ $EFI == [f][a][l][s][e] ]] || exit 1
read -p "choose a name for the Volumegroup default=volgroup0: " VGNAME1
VGNAME1=${VGNAME1:-volgroup0}
read -p "choose a name for the root local volume default=lv_root: "	LVNAMEROOT
LVNAMEROOT=${LVNAMEROOT:-lv_root}
read -p "how much space do you need for the root directory? default=30GB: " ROOTSPACE
ROOTSPACE=${ROOTSPACE:-30GB}
read -p "choose a name for the home local volume default=lv_home: " LVNAMEHOME
LVNAMEHOME=${LVNAMEHOME:-lv_home}
read -p "how much space do you need for the home directory? default=100%FREE: " HOMESPACE
HOMESPACE=${HOMESPACE:-100%FREE}
read -p "pass the path to the drive you wanna install archlinux to example: /dev/sda: " DRIVE
if [ !$DRIVE ]
then
exit 1
fi
read -p "Enter your computername/hostname default=Archlinux: " HOSTNAME
HOSTNAME=${HOSTNAME:-Archlinux}
read -p "Enter a username only lowercase letters allowed default=user: " USER
USER=${USER:-user}
echo "set EFI to $EFI"
echo "set vgname to $VGNAME1"
echo "set lvrootname to $LVNAMEROOT with size $ROOTSPACE"
echo "set lvhomename to $LVNAMEHOME with size $HOMESPACE"
read -p "the disk $DRIVE will be completly formated all data will be lost. 
Are you sure you want to Continue? (yes/No): " confirm && [[ $confirm == [yY][eE][sS] ]] || exit 1
DRIVE1=$DRIVE'1'
DRIVE2=$DRIVE'2'
if [ $EFI = false ]
then
fdisk $DRIVE << EOF
o
n




t

8e
a
write
EOF
pvcreate --dataalignment 1m $DRIVE1
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
vgcreate $VGNAME1 $DRIVE2
fi

lvcreate -L $ROOTSPACE $VGNAME1 -n $LVNAMEROOT
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
sed -i "s/^EFI=.*/EFI=$EFI\nDRIVE=$DRIVE/" install_arch_linux2.sh
echo "#!/bin/bash

EFI=$EFI
DRIVE=$DRIVE"
cat install_arch_linux2.sh >> /mnt/root/instll_arch_linux.sh
arch-chroot /mnt bash -c "cd root && bash install_arch_linux.sh"
umount -a
reboot