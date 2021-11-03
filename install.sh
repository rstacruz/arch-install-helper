#!/usr/bin/env bash
# https://github.com/rstacruz/arch-install-helper

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

# Packages to install
export PACKAGES="base linux linux-firmware"

# Other packages to install
PACKAGES+=" base-devel"
PACKAGES+=" vim git sudo openssh" # dev tools
PACKAGES+=" xorg" # xorg
PACKAGES+=" tig neovim tmux"
PACKAGES+=" firefox" # browser
PACKAGES+=" xfce4 ttf-inconsolata ttf-dejavu ttf-croscore" # xfce4
PACKAGES+=" lightdm lightdm-gtk-greeter" # lightdm
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
#
#arch-chroot /mnt sh -c "
#  pacman -S --needed --noconfirm \
#    xf86-video-vmware open-vm-tools
#  systemctl enable vmtoolsd.service
#  systemctl enable vmware-vmblock-fuse.service
#"

# ===== VirtualBox tools =====
#
#arch-chroot /mnt sh -c "
#  pacman -S --needed --noconfirm \
#    linux-headers virtualbox-guest-utils
#  sudo systemctl enable vboxservice.service
#"

# ===== Swap file via systemd-swap =====
#
#arch-chroot /mnt sh -c "
#  pacman -S --noconfirm --needed systemd-swap
#  sed -i 's/swapfc_enabled=0/swapfc_enabled=1/' /etc/systemd/swap.conf
#  systemctl enable systemd-swap
#"

# ===== Swap file =====
#
#SWAP_SIZE="8G"
#arch-chroot /mnt sh -c "
#  fallocate -l $SWAP_SIZE /swapfile
#  chmod 600 /swapfile
#  mkswap /swapfile
#  echo '/swapfile none swap defaults 0 0' | tee -a /etc/fstab
#"

# ===== Alternate keymap =====
# For those using dvorak or colemak.
#
#KEYMAP="dvorak"
#arch-chroot /mnt sh -c "
#  echo 'KEYMAP=$KEYMAP' > /etc/vconsole.conf
#"

echo ''
echo 'Done! Type "reboot" to reboot :)'
