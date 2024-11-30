#!/bin/bash

echo "setting up raid1"

diskA="/dev/nvme0n1"
diskB="/dev/nvme2n1"
efiPart=${diskA}p1
efiMountPoint="/tmp/efi"

btrfsPart=${diskA}p2
btrfsId=$(uuidgen)
btrfsMountPoint="/tmp/btrfs"


###############################################################################
# wipe disks and setup partitions
###############################################################################
sfdisk --wipe always --delete $diskA
sfdisk --wipe always --delete $diskB

sfdisk $diskA << EOF
size=512M, type=U
size=+
EOF

sfdisk $diskB << EOF
size=512M, type=U
size=+
EOF


###############################################################################
# format efi and mount
###############################################################################
mkfs.vfat $efiPart
mkdir -p $efiMountPoint
mount -t vfat $efiPart /tmp/efi

###############################################################################
# format and mount btrfs
###############################################################################
mkfs.btrfs -f --label btrfsraid --uuid $btrfsId -m raid1 -d raid1 $btrfsPart ${diskB}p2
mkdir -p $btrfsMountPoint
mount -t btrfs $btrfsPart /tmp/raid1


###############################################################################
# download grub and setup minimal grub.cfg
###############################################################################
apt update -y
apt install grub-efi-amd64 -y

# copy into the default uefi path so that the firmware can find and load it
mkdir -p /tmp/efi/EFI/BOOT/
cp /usr/lib/grub/x86_64-efi/monolithic/grubx64.efi /tmp/efi/EFI/BOOT/BOOTX64.efi

cat << EOF >> /tmp/efi/EFI/BOOT/grub.cfg
menuentry 'ubuntu' {
    insmod part_dos
    insmod part_btrfs
    search --no-floppy --set=root --fs-uuid ${btrfsId}
    linux /@/boot/vm-linuz-6.8.0-31-generic root=UUID=${btrfsId} ro rootflags=subvol=@,degraded
    initrd /@/boot/initrd.img-6.8.0-31-generic
}
EOF