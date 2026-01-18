
# Wifi configuration 
## assumption
bbb + usb wifi dongle with realtek rtl8188eu chipset

## verify either wifi is available
- run command --> ip link 
if no wifi interface appears then need to be configured 

## discover the wifi hardware 
- run command --> lsusb 
or better 
- rum command --> dmesg | grep -i rtl
output shows the exact usb dongle model and correcponding firmware as follow: 
[    9.716904] usb 1-1: Dumping efuse for RTL8188EU (0x200 bytes):
[    9.996243] usb 1-1: RTL8188EU rev D (TSMC) romver 0, 1T1R, TX queues 2, WiFi=1, BT=0, GPS=0, HI PA=0
[   10.006054] usb 1-1: RTL8188EU MAC: cc:28:aa:68:d5:3d
[   10.011668] usb 1-1: rtl8xxxu: Loading firmware rtlwifi/rtl8188eufw.bin
[   10.027403] usb 1-1: Direct firmware load for rtlwifi/rtl8188eufw.bin failed with error -2
[   10.035954] usb 1-1: request_firmware(rtlwifi/rtl8188eufw.bin) failed
[   10.048602] rtl8xxxu 1-1:1.0: probe with driver rtl8xxxu failed with error -11
[   10.057188] usbcore: registered new interface driver rtl8xxxu
as the output shows the required firmware is rtlwifi/rtl8188eufw.bin is not loaded.

## Steps to configure wifi in buildroot
1- Kernel driver for the wifi chipset
2- Firmware for the wifi chipset
3- Userspace wifi tools --> wpa_supplicant, iw, ifconfig/ip
4- Network configuration --> /etc/network/interfaces
5- web server -->  Target packages --> Networking applications --> lighttpd

### 1- select wifi driver
run make linux-manuconfig --> device drivers --> network device support --> wireless lan --> realtek devices --> realtek 802.11n usb wireless
and also --> Include support for untested Realtek 8xxx USB devices

### 2- select wifi firmware 
run make menuconfig --> Target packages -->  Hardware handling --> Firmware --> linux-firmware --> wifi firmware --> realtek81xx

### 3- user space wifi configuration
- run make menuconfig --> Target packages --> network applications --> wpa_supplicant, wireless_tools, iw, dhcp
- create config file --> /etc/wpa_supplicant.conf and fill with 
    ctrl_interface=/var/run/wpa_supplicant 
    update_config=1
    country=DE
    network={
        ssid="name of the router"
        psk="passwort of router"
        key_mgmt=WPA-PSK
    }

### 4- network configuration
- create /etc/network/interfaces and fill with 
    auto lo
    iface lo inet loopback

    auto eth0
    iface eth0 inet dhcp

    auto wlan0
    iface wlan0 inet manual // use manual to avoid dhcp client auto start
        wpa-conf /etc/wpa_supplicant.conf
        metric 50

-note: if manual control if wlan0 is required then create startup scrips: 
    - nano /etc/init.d/S51wifi_start and fill with
        #!/bin/sh
        ip link set wlan0 up
        wpa_supplicant -i wlan0 -c /etc/wpa_supplicant.conf -B
        udhcpc -i wlan0
    - make it executable --> chmod +x /etc/init.d/S51wifi_start
    - start the wifi --> /etc/init.d/S51wifi_start

### 5- web server configuration
- run make menuconfig --> Target packages --> Networking applications --> lighttpd

## final verification wifi configuration
### 1- verify the driver and firmware loaded correctly
after building the kernel flashing the the sdcard insert it in bbb and boot. 
run command --> dmesg | grep -i rtl
now the right driver and firmware should be appears in the log as follow:
[    9.718241] usb 1-1: Dumping efuse for RTL8188EU (0x200 bytes):
[    9.997229] usb 1-1: RTL8188EU rev D (TSMC) romver 0, 1T1R, TX queues 2, WiFi=1, BT=0, GPS=0, HI PA=0
[   10.007060] usb 1-1: RTL8188EU MAC: cc:28:aa:68:d5:3d
[   10.012703] usb 1-1: rtl8xxxu: Loading firmware rtlwifi/rtl8188eufw.bin
[   10.523613] usbcore: registered new interface driver rtl8xxxu
[   10.995691] RTW: rtl8188eu v5.2.2.4_25483.20171222
[   11.001679] usbcore: registered new interface driver rtl8188eu

### 2- make sure the interface is up and ip assigned 
ip addr show wlan0 --> should show the wlan0 interface with ip address assigned from the router.

