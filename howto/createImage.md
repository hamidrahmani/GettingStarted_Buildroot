# steps to create an image running on QEMU board using buildroot 
    - install the QEMU package and QEMU emulator for ARM architectures
        sudo apt update
        sudo apt install qemu qemu-system-arm

    - sets up the .config file with default options suitable for running the kernel on QEMU. This must be done before building the kernel.
        make qemu_arm_versatile_defconfig
    - change the default option if needed
        make menuconfig    
    - build the imgae
        make

Note: after the build process done there shold be 5 files under /output/image/  --> 
            1. rootfs.ext2, 
            2. start-qemu.sh, 
            3. versatile-pb.dtb, 
            4. zImage, 
            5. ./start-qmeu.sh 
    - run the script to execute qemu board with needed parameters
        ./start-qemu.sh

# steps to create an image running on Beaglebone board using buildroot
    - set up the .config file with default options suitable for running the kernel on beaglebone board. This must be done before building the kernel.
        make beaglebone_defconfig
    - change the default option if needed
        make menuconfig    
    - build the imgae
        make

# note
    After the build process is done several files are available under /output/image/. The most important file is sdcard.img.
    - copy the sdcard.img file on sdcard
        sudo dd if=output/images/sdcard.img of=/dev/sdX bs=4M status=progress && sync --> be sure the correct dev/ is selected. This is most probably /dev/sdb.
    - boot the beagebone board from sd-card --> insert the sdcard and restart the board bbb.


# how to integrate the costumer application into buildroot
    - create your application directory inside buildroot package directory
        - mkdir package/userApps
    - register the application package in buildroot
        - nano package/Config.in
    - configure your application as buildroot package and also building all .mk files inside userApps
        - nano package/userApps/Config.in
        - nano package/userApps/userApps.mk
    - instruct buildroot to build and install the application into target filesystem
        - nano package/userApps/userApps.mk
    - select the application package in GUI to be a activated in .config file
        - make menucondig
    - build the image
        - make
    - note: if the application package has sub-directories changes are nededed inside the Config.in and userApps.mk files
