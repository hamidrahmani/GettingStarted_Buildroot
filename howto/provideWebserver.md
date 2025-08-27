### steps to provide the lighttpd webserver 
#### running on  arm QEMU board
##### appproach1: minimal webserver using the default setup 
    - enable the Lighttpd package in Buildroot (BR2_PACKAGE_LIGHTTPD)
        - either selecting the Lighttpd package in make menuconfig under "Target packages" → "Networking applications" → "lighttpd".
        - or BR2_PACKAGE_LIGHTTPD=y in .config file
    - built image
    - place index.html in /var/www/html/ inside the target rootfs
    - set up QEMU port forwarding to access the web server from your host --> -net user hostfwd=tcp::8080-:80
Note: if qemu-start.sh script is used the the approprite line must be the looks like that --> 
        exec qemu-system-arm -M versatilepb -kernel zImage -dtb versatile-pb.dtb -drive file=rootfs.ext2,if=scsi,format=raw -append "rootwait root=/dev/sda console=ttyAMA0,115200" -net nic,model=rtl8139 -net user,hostfwd=tcp::8080-:80 ${EXTRA_ARGS} "$@"
    - run the script to boot the QEMU
    - call the page
        - either over terminal --> curl http://localhost:8080/index.html
        - or in web browser --> http://localhost:8080/index.html 

##### appproach2: custom webserver using the rootfs-layout
    - enable the Lighttpd package in Buildroot (BR2_PACKAGE_LIGHTTPD)
    - Place the web content like index.html in an overlay directory
        - board/qemu/rootfs-overlay/var/www/html/index.html
        - board/qemu/rootfs-overlay/var/www/..... -> for other files or structures
    - instruct buildroot to use your files
        - go to: System configuration → Root filesystem overlay directories
        - enter the path to your overlay directory --> board/qemu/rootfs-overlay
    - built image 
    - set up QEMU port forwarding to access the web server from your host --> -net user hostfwd=tcp::8080-:80
    - run the script to boot the QEMU
    - call the page
        - either over terminal --> curl http://localhost:8080/index.html
        - or in web browser --> http://localhost:8080/index.html 

##### appproach3: custom webserver using the user package 



##### running on boardbeaglebone board
    - provide configuration file for beagelbone --> make beaglebone_defconfig
    - enable the Lighttpd package in Buildroot (BR2_PACKAGE_LIGHTTPD)
    - Place the web content like index.html in an overlay directory
        - board/beaglebone/rootfs-overlay/var/www/html/index.html
        - board/beaglebone/rootfs-overlay/var/www/..... -> for other files or structures
    - instruct buildroot to use your files
        - go to: System configuration → Root filesystem overlay directories
        - enter the path to your overlay directory --> board/beaglebone/rootfs-overlay
    - built image 
    - install the sdcard.img into sdcard (see coresponding .sh) and boot the beaglebone
    - call the page
        - either over terminal --> curl http://<beaglebone-ip>/index.html
        - or in web browser --> http://<beaglebone-ip>/index.html
 
Note: 
- check the ip address of the board --> ip addr
- if no ip address is assigned --> ifconfig eth0 192.168.1.100 netmask 255.255.255.0 up 
- check if lighttpd is running --> ps | grep lighttpd
- check the lighttpd configuration --> cat /etc/lighttpd/lighttpd.conf
    - root-document
    - port
