#!/bin/bash

echo "setting up raid1"

diskA="/dev/nvme0n1"
diskB="/dev/nvme2n1"

setupDisk() {

fdisk "${1:-"provide disk parameter"}" <<EOF
g       # Create a new GPT partition table
n       # Create a new partition (EFI)
1       # Partition number 1
        # Default - start at beginning of disk
+512M   # Size of 512MB
t       # Change partition type
1       # Partition number 1
uefi

n       # Create a new partition (Linux)
2       # Partition number 2
        # Default - start immediately after previous partition
        # Use the rest of the disk

w       # Write changes to disk and exit
EOF
}

setupDisk $diskA
setupDisk $diskB
