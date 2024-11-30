#!/bin/bash

echo "setting up raid1"

diskA="/dev/nvme0n1"
diskB="/dev/nvme2n1"
efiPart=${diskA}p1
btrfsPart=${diskA}p2
btrfsId=$(uuidgen)

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



mkfs.btrfs -f --label btrfsraid --uuid $btrfsId -m raid1 -d raid1 $btrfsPart ${diskB}p2
mkdir /dev/raid1
mount -t btrfs $btrfsPart /dev/raid1

