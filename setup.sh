#!/bin/bash

echo "setting up raid1"

diskA="/dev/nvme0n1"
diskB="/dev/nvme2n1"

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