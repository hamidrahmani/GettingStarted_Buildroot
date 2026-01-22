#!/bin/sh
./make_keys_and_sign.sh --image ../buildroot/output/images/zImage --overlay ../overlays/beaglebone/rootfs-overlay/boot/

../scripts/make_keys_and_sign.sh --image output/images/zImage --overlay ../overlays/beaglebone/rootfs-overlay/boot/