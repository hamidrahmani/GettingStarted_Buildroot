### steps to create an buildroot image for arm running in QEMU board
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

### steps to create an buildroot image on sdcard for arm running on beagleboneblack
    - # sets up the .config file with default options suitable for running the kernel on beaglebone board. This must done before building the kernel.
        make beaglebone_defconfig
    - # change the default option if needed
        make menuconfig    
    - #build the imgae
        make

Note: after the build process there shold be several files created under /output/image/  --> most important file is sdcard.img
    - #copy the sdcard.img file on sdcard
        sudo dd if=output/images/sdcard.img of=/dev/sdX bs=4M status=progress && sync --> be sure the correct dev/ are selecte. most probably this is /dev/sdb.
    - #boot the beageboneblack --> insert the sdcard into BBB and press the sw2 before power-on.


### how to integrate the costumer application into buildroot
    - create your application directory inside buildroot package directory
        - mkdir package/userApps
    - register the application package in buildroot
        - nano package/Config.in
    - configure your application as buildroot package and also building all .mk files insode userApps
        - nano package/userApps/Config.in
        - nano package/userApps/userApps.mk
    - instruct buildroot to build and install the application into target filesystem
        - nano package/userApps/userApps.mk
    - select the application package in GUI to be a activated in .config file
        - make menucondig
    - build the image
        - make

Note: if the application package has sub-directories for different kinds of application there must be some changes inside the Config.in and userApps.mk files
