#!/bin/bash

echo "setting up raid1"

diskA="/dev/nvme0n1"
diskB="/dev/nvme2n1"
efiPart=${diskA}p1
efiPart2=${diskB}p1
efiMountPoint="/tmp/efi"

btrfsPart=${diskA}p2
btrfsId=$(uuidgen)
btrfsMountPoint="/tmp/btrfs"
newroot="/tmp/newroot"

suite="noble"
linuxVer="6.8.1-49-generic"

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
# download grub and setup minimal grub.cfg
###############################################################################
apt update -y
apt install grub-efi-amd64 -y

# copy into the default uefi path so that the firmware can find and load it
mkdir -p ${efiMountPoint}/EFI/BOOT/
cp /usr/lib/grub/x86_64-efi/monolithic/grubx64.efi ${efiMountPoint}/EFI/BOOT/BOOTX64.efi

cat << EOF > ${efiMountPoint}/EFI/BOOT/grub.cfg
set timeout=5
menuentry "ubuntu" {
    insmod part_dos
    insmod part_btrfs
    search --no-floppy --set=root --fs-uuid ${btrfsId}
    linux /@/boot/vm-linuz-${linuxVer} root=UUID=${btrfsId} ro rootflags=subvol=@,degraded
    initrd /@/boot/initrd.img-${linuxVer}
}
EOF

# copy over the efi as backup
dd if=$efiPart of=$efiPart2


###############################################################################
# format and mount btrfs
###############################################################################
mkfs.btrfs -f --label btrfsraid --uuid $btrfsId -m raid1 -d raid1 $btrfsPart ${diskB}p2
mkdir -vp $btrfsMountPoint
mount -vt btrfs $btrfsPart $btrfsMountPoint

###############################################################################
# setup btrfs and chroot fs
###############################################################################
btrfs subvolume create $btrfsMountPoint/@
btrfs subvolume create $btrfsMountPoint/@home
btrfs subvolume create $btrfsMountPoint/@var
btrfs subvolume create $btrfsMountPoint/@snapshots
btrfs subvolume create $btrfsMountPoint/@logs

mkdir -vp $newroot
mount -vt btrfs -o subvol=@ $btrfsPart $newroot

mkdir -vp $newroot/home
mount -vt btrfs -o subvol=@home $btrfsPart $newroot/home

mkdir -vp $newroot/snapshots
mount -vt btrfs -o subol=@snapshots $btrfsPart $newroot/.snapshots

mkdir -vp $newroot/var
mount -vt btrfs -o subvol=@var $btrfsPart $newroot/var

mkdir -vp $newroot/var/logs
mount -vt btrfs -o subvol=@ogs $btrfsPart $newroot/var/logs

mkdir -vp $newroot/dev
mount --bind /dev $newroot/dev
mkdir -vp $newroot/sys
mount --bind /sys $newroot/sys
mkdir -vp $newroot/proc
mount --bind /proc $newroot/proc

###############################################################################
# install debootstrap
###############################################################################

apt install debootstrap
debootstrap $suite $newroot
