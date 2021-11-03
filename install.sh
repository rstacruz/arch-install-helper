#!/usr/bin/env bash
# --------------------------------------------------------------------------------
# Arch install helper script
# https://github.com/rstacruz/arch-install-helper
#
# Instructions:
# - Download this file while booted in Arch ISO. (`curl -sL https://git.io/JP9Fj -o install.sh`)
# - Edit the values below. (`vim install.sh`)
# - Set up the disk's partitions and mount everything in /mnt.
# - Save it and run it.
# --------------------------------------------------------------------------------

# Edit these things
export TIME_ZONE="Australia/Melbourne"
export SYSTEM_HOSTNAME="vm-arch"

# Your user
export USERNAME="rsc"
export PASSWORD="123456"
export ROOT_PASSWORD="123456"

# Locales
export LOCALES="en_US.UTF-8 UTF-8" # and "en_US ISO-8859-1"
export LANG="en_US.UTF-8"

# Packages to install (base)
export PACKAGES="base linux linux-firmware"
PACKAGES+=" base-devel"

# Packages to install (optionals)
PACKAGES+=" git sudo openssh" # dev tools
PACKAGES+=" xorg" # xorg
PACKAGES+=" firefox" # browser
PACKAGES+=" xfce4 ttf-inconsolata ttf-dejavu ttf-croscore" # xfce4
PACKAGES+=" lightdm lightdm-gtk-greeter" # lightdm
#PACKAGES+=" neovim tig neovim tmux the_silver_searcher" # some common dev tools
#PACKAGES+=" chromium"
#PACKAGES+=" fish pkgfile" # fish shell
#PACKAGES+=" gnome gnome-tweaks gdm" # gnome
#PACKAGES+=" docker docker-compose" # docker
#PACKAGES+=" networkmanager" # for laptops
#PACKAGES+=" intel-ucode" # intel processors
#PACKAGES+=" amd-ucode" # amd processors

# --------------------------------------------------------------------------------

# Ensure that there's something in /mnt
if ! findmnt /mnt &>/dev/null; then
  echo "Can't continue:"
  echo "Mount a drive to /mnt before running this."
  exit 1
fi

# Enable parallel downloads
sed '/ParallelDownloads/s/^#//g' -o /etc/pacman.conf

# Install packages
pacstrap /mnt $PACKAGES

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Set timezone
arch-chroot /mnt sh -c "
  ln -sf '/usr/share/zoneinfo/$TIME_ZONE' /etc/localtime
  hwclock --systohc
"

# Locale
arch-chroot /mnt sh -c "
  echo '$LOCALES' >> /etc/locale.gen
  echo 'LANG=$LANG' > /etc/locale.conf
  locale-gen
"

# Hostname
arch-chroot /mnt sh -c "
  echo '$SYSTEM_HOSTNAME' > /etc/hostname
  echo '127.0.0.1 localhost' >> /etc/hosts
  echo '::1 localhost' >> /etc/hosts
  echo '127.0.1.1 $SYSTEM_HOSTNAME.localdomain $SYSTEM_HOSTNAME' >> /etc/hosts
"

# Root password
arch-chroot /mnt sh -c "
  (echo '$ROOT_PASSWORD'; echo '$ROOT_PASSWORD') | passwd
"

# Add user
arch-chroot /mnt sh -c "
  useradd -Nm -g users -G wheel,sys,audio,input,video,network,rfkill '$USERNAME'
  (echo '$PASSWORD'; echo 'PASSWORD') | passwd '$USERNAME'
"

# Sudo
arch-chroot /mnt sh -c "
  echo '%wheel ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
"

# --------------------------------------------------------------------------------
# Bootloader setup
# --------------------------------------------------------------------------------

# ===== GRUB (BIOS mode) =====
DRIVE="/dev/sda"
arch-chroot /mnt sh -c "
  pacman -S --needed --noconfirm grub
  grub-install '$DRIVE'
  grub-mkconfig -o /boot/grub/grub.cfg
"

# --------------------------------------------------------------------------------
# Optional features:
# uncomment blocks here that you may like
# --------------------------------------------------------------------------------

# ===== DHCP for networking (recommended for VM's) =====
# Enabling this will enable the dhcpcd@<interface> service. Use
# `ip addr` to find this interface name. VMWare Player usually has
# ens33.
#
#DHCP_INTERFACE=ens33
#arch-chroot /mnt sh -c "
#  pacman -S --needed --noconfirm dhcpcd
#  systemctl enable 'dhcpcd@$DHCP_INTERFACE'
#"

# ===== NetworkManager (recommended for laptops) =====
#
#arch-chroot /mnt sh -c "
#  pacman -S --needed --noconfirm networkmanager
#  systemctl enable NetworkManager.service
#  systemctl mask NetworkManager-wait-online.service
#"

# ===== Time synchronization =====
# Synchronizes the time via NTP.
# See: https://wiki.archlinux.org/title/Systemd-timesyncd
#
#arch-chroot /mnt sh -c "
#  systemctl enable --now systemd-timesyncd.service
#"

# ===== Pacman customizations =====
#
#arch-chroot /mnt sh -c "
#  sed -i '/Color/s/^#//g' /etc/pacman.conf
#  sed -i '/VerbosePkgLists/s/^#//g' /etc/pacman.conf
#  sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
#"

# ===== VMWare tools (open-vm-tools) =====
# Recommended for VMWare guests.
# See: https://wiki.archlinux.org/title/VMware/Install_Arch_Linux_as_a_guest
#
#arch-chroot /mnt sh -c "
#  pacman -S --needed --noconfirm xf86-video-vmware open-vm-tools
#  systemctl enable vmtoolsd.service
#  systemctl enable vmware-vmblock-fuse.service
#"

# ===== VirtualBox tools =====
# Recommended for VirtualBox guests.
#
#arch-chroot /mnt sh -c "
#  pacman -S --needed --noconfirm linux-headers virtualbox-guest-utils
#  sudo systemctl enable vboxservice.service
#"

# ===== Swap file via systemd-swap =====
# Automate swap file creation.
# See: https://wiki.archlinux.org/title/Swap#systemd-swap
#
#arch-chroot /mnt sh -c "
#  pacman -S --noconfirm --needed systemd-swap
#  sed -i 's/swapfc_enabled=0/swapfc_enabled=1/' /etc/systemd/swap.conf
#  systemctl enable systemd-swap
#"

# ===== Disable PC speaker beeps =====
# See: https://wiki.archlinux.org/title/Kernel_module#Using_files_in_/etc/modprobe.d/_2
#
#arch-chroot /mnt sh -c "
#  echo 'blacklist pcspkr' > /etc/modprobe.d/blacklist.conf
#"

# ===== Autologin to tty1 =====
# Great for VM's that won't use a display manager.
# See: https://wiki.archlinux.org/title/Getty#Virtual_console
#
#arch-chroot /mnt sh -c "
#  mkdir -p /etc/systemd/system/getty@tty1.service.d
#  (
#    echo '[Service]'
#    echo 'ExecStart='
#    echo 'ExecStart=-/usr/bin/agetty --autologin $USERNAME --noclear %I \$TERM'
#  ) | tee /etc/systemd/system/getty@tty1.service.d/override.conf
#  systemctl enable getty@tty1
#"

echo ''
echo 'Done! Type "reboot" to reboot :)'
