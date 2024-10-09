#!/bin/bash

# Set keyboard layout (optional)
loadkeys us

# Update the system clock
timedatectl set-ntp true

# Partition the disk (replace /dev/sda with your disk)
fdisk /dev/sda << EOF
g
n


+512M    # Boot partition
n


         # Root partition (use the rest of the disk)
w
EOF

# Format partitions
mkfs.ext4 /dev/sda2  # root partition
mkfs.ext4 /dev/sda1  # boot partition

# Mount partitions
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# Install base packages with Linux Zen, Intel microcode, and Alacritty
pacstrap /mnt base linux-zen linux-zen-headers vim nano intel-ucode alacritty

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Change root into the new system
arch-chroot /mnt << EOF
# Set the timezone
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc

# Localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network configuration
echo "myhostname" > /etc/hostname
cat << EOT >> /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    myhostname.localdomain myhostname
EOT

# Install essential packages
pacman -S --noconfirm networkmanager gnome gnome-extra

# Enable services
systemctl enable NetworkManager

# Set up the bootloader
pacman -S --noconfirm grub os-prober
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Install a splash screen
pacman -S --noconfirm plymouth
echo "HOOKS=(base udev plymouth autodetect modconf block filesystems keyboard fsck)" >> /etc/mkinitcpio.conf
mkinitcpio -P

# Set the default runlevel to graphical
systemctl set-default graphical.target

# Exit chroot
exit
EOF

# Unmount and reboot
umount -R /mnt
reboot
