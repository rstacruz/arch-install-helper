# Some other things that are less common.

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

