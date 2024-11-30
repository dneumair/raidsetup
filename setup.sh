#!/bin/bash

echo "setting up raid1"

diskA="/dev/nvme0n1"
diskB="/dev/nvme2n1"

sfdisk /dev/nvme0n1 << EOF
label: gpt
label-id: $(uuidgen)
device: /dev/sdX
unit: sectors

# Partition table entries
/dev/nvme0n1p1 : start=2048, size=1048576, type=U, name="EFI System Partition"
/dev/nvme0n1p2 : start=1048576, type=83, name="Linux Filesystem"
EOF
mkfs.fat -F32 /dev/sdX1 # EFI partition

sfdisk /dev/nvme2n1 << EOF
label: gpt
label-id: $(uuidgen)
device: /dev/sdX
unit: sectors

# Partition table entries
/dev/nvme2n1p1 : start=2048, size=1048576, type=U, name="EFI System Partition"
/dev/nvme2n1p2 : start=1048576, type=83, name="Linux Filesystem"
EOF
mkfs.fat -F32 /dev/sdX1 # EFI partition
