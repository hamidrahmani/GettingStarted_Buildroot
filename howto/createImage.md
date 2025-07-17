steps to create an buildroot image for arm running in QEMU board
    - #install the qmeu base package and the QEMU system emulator for ARM architectures
        sudo apt update
        sudo apt install qemu qemu-system-arm

    - # sets up the .config file with default options suitable for running the kernel on QEMU's ARM Versatile board. This must done before building the kernel.
        make qemu_arm_versatile_defconfig
    - # change the default option if needed
        make menuconfig    
    - #build the imgae
        make

Note: after the build process there shold be 4 files under /output/image/  --> rootfs.ext2, start-qemu.sh, versatile-pb.dtb, zImage, ./start-qmeu.sh
    - #run the qemu
        ./start-qemu.sh