# basic knowledge
## about ip adress
## show ip
    - ip addr show
## add static and manually
- on running system
    ip addr add 192.168.1.44/24 dev eth0
    ip link set eth0 up
- before boot the system add following lines inside the file /etc/network/interfaces
    auto eth0
    iface eth0 inet static
        address 192.168.1.50
        netmask 255.255.255.0
        gateway 192.168.1.1

## add dynamic and manually
- before boot the system add following lines inside the file /etc/network/interfaces
    auto eth0
    iface eth0 inet dhcp

## starting the network manually
/etc/init.d/S40network start
/etc/init.d/S40network stot
/etc/init.d/S40network restart

## using rootfs-ovrelay
- add the file /etc/network/interfaces inside the rootfs-overlay folder.build the image and boot the system