#!/bin/bash

echo "=== SD Card Formatter and Flasher for BeagleBone Black ==="

# Prompt for SD card device
read -p "Enter the SD card device (e.g., /dev/sdX or /dev/mmcblkX): " sdcard
echo "You entered: $sdcard"
read -p "Are you sure this is the correct device? This will erase all data on it! (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Operation cancelled."
    exit 1
fi

# Check if sdcard.img exists
if [ ! -f sdcard.img ]; then
    echo "Error: sdcard.img not found in the current directory."
    exit 1
fi

echo "Unmounting partitions..."
for part in $(lsblk -ln $sdcard | awk '{print $1}'); do
    sudo umount /dev/$part 2>/dev/null
done

echo "Wiping existing partition table..."
sudo dd if=/dev/zero of=$sdcard bs=1M count=10

echo "Creating new partition..."
sudo parted $sdcard --script mklabel msdos
sudo parted $sdcard --script mkpart primary fat32 1MiB 100%
sudo parted $sdcard --script set 1 boot on

echo "Formatting partition..."
partition="${sdcard}1"
sudo mkfs.vfat -F 32 $partition

echo "Flashing sdcard.img to SD card..."
sudo dd if=sdcard.img of=$sdcard bs=4M status=progress conv=fsync

echo "Syncing and ejecting..."
sync
sudo eject $sdcard

echo "=== Operation completed successfully. ==="
