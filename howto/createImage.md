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


### how to integrate the costumer application into buildroot
    - create your application directory inside buildroot package directory
        - mkdir package/userApps
    - register the application package in buildroot
        - nano package/Config.in
    - configure your application as buildroot package. This will happen inside the Config.in file 
        - nano package/userApps/Config.in
    - instruct buildroot to build and install the application into target filesystem
        - nano package/userApps/userApps.mk
    - select the application package to be a activated in .config file
        - make menucondig
    - build the image
        - make

Note: if the application package has sub-directories for different kinds of application there must be some changes inside the Config.in and userApps.mk files
