#!/bin/bash

# BeagleBone Black SD-Karten-Flash-Skript

echo "⚠️ WARNUNG: Dieses Skript löscht alle Daten auf der angegebenen SD-Karte!"
read -p "Bitte gib das Gerät deiner SD-Karte an (z. B. /dev/sdb): " DEVICE

if [ ! -b "$DEVICE" ]; then
    echo "❌ Gerät $DEVICE existiert nicht."
    exit 1
fi

echo "🔄 Partitioniere SD-Karte..."
sudo parted $DEVICE --script mklabel msdos
sudo parted $DEVICE --script mkpart primary fat32 1MiB 65MiB
sudo parted $DEVICE --script mkpart primary ext4 65MiB 100%

BOOT_PART=${DEVICE}1
ROOT_PART=${DEVICE}2

echo "🧼 Formatiere Partitionen..."
sudo mkfs.vfat -F 32 $BOOT_PART
sudo mkfs.ext4 $ROOT_PART

echo "📂 Mounten der Partitionen..."
mkdir -p /mnt/sdboot /mnt/sdroot
sudo mount $BOOT_PART /mnt/sdboot
sudo mount $ROOT_PART /mnt/sdroot

echo "📁 Kopiere Boot-Dateien..."
sudo cp MLO u-boot.img zImage am335x-bone.dtb /mnt/sdboot/

echo "📁 Installiere Root-Dateisystem..."
read -p "Ist rootfs.ext4 ein Image (i) oder ein Tar-Archiv (t)? [i/t]: " ROOT_TYPE

if [ "$ROOT_TYPE" == "i" ]; then
    echo "📦 Schreibe rootfs.ext4 direkt auf die Partition..."
    sudo dd if=rootfs.ext4 of=$ROOT_PART bs=4M status=progress
elif [ "$ROOT_TYPE" == "t" ]; then
    echo "📦 Entpacke rootfs.ext4 auf die Partition..."
    sudo tar -xpf rootfs.ext4 -C /mnt/sdroot
else
    echo "❌ Ungültige Eingabe. Bitte 'i' oder 't' eingeben."
    exit 1
fi

echo "✅ Synchronisiere und entferne Mounts..."
sync
sudo umount /mnt/sdboot /mnt/sdroot
rm -r /mnt/sdboot /mnt/sdroot

echo "🎉 SD-Karte erfolgreich vorbereitet für BeagleBone Black!"
