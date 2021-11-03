# Arch installer script

A small script to make it easier to install Arch Linux on VM's.

Boot the Arch Linux installer. Get online. (for VM's - you're probably already online.)

```sh
root@archiso:~$ ping 8.8.8.8
```

Set up your partitions and mount things to /mnt.

```sh
lsblk
# ^ find the block devices (sda is what we want in this example)
#   NAME   MAJ:MIN SIZE   RO TYPE
#   loop0  7:0     673.1M 1  loop
#   sda    8:0     32G    0  disk

cfdisk /dev/sda
# ^ partition the disk:
#   - Set label type: `gpt`
#   - Add new partition: 1M
#   - Change type to: BIOS boot
#   - Add new partition: (remaining size)
#   - Type: Linux filesystem
#   - "Write" then "Quit"

mkfs.ext4 /dev/sda2
mount /dev/sda2 /mnt
```

In the Archiso, Download this file and edit it.

```sh
curl -sL https://git.io/JPEr0 -o install.sh
vim install.sh
```

Save it and run it.

```sh
bash install.sh
```
