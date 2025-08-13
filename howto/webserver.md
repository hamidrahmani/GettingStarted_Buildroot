# lighttpd
## setting up for qemu
There is 3 ways to setup and activate webserver lighttpd on buildroot
1. using overlay concept of filesystem
2. using custom packages
3. over menuconfig --> in some buildroot versions it might not be available

1. verlay is a concept whichs used to add or override files in the final image. 
Note: Buildroot must be informed that overlay concenpt is using --> make menuconfig --> system configuration --> Root filesystem overlay directories. here the path /board/qemu/rootfs_overlay must be copied. The required files musst be placed in corresponding folder inside /board/qemu/rootfs_overlay. 

For example if we want to use lighttpd then the following folder must be created inside the /board/qemu/rootfs_overlay/
- etc/lighttpd/lighttpd.conf
- www/index.html

----------------------------------
a simple lighttpd file can be like:
server.document-root = "/www"
server.port = 8080
server.modules = (
    "mod_staticfile"
)
index-file.names = ( "index.html" )
dir-listing.activate = "enable"

----------------------------------
a simple index.html file can be like:
Welcome to Lighttpd on Buildroot!

Sofar we have just created needed files in overlay. After conducting commadn "make" buildroot builds whole image but not your lighttpd because it is not selected as a package over menuconfig. 
Note: Buildroot just build packages which are actively selected over menuconfig.
In order to get the lighttpd (overlayed folder) build we need to instruct buildroot explicitly: "make lighttpd-rebuild".
After rebuild it need to be integrated into finale image: "make"

Important note: qemu needs to be informed to forward port 8080 to the host "-net nic -net user,hostfwd=tcp::8080-:8080". Since we use the auto-generated script "start-qemu.sh" we need to instruct buildroot to adjust it. It can be done as follow:
--> open the /board/qemu/arm-versatile/readme.txt file and add the user,hostfwd=tcp::8080-:8080 at the end.

Know we can run the script which boots the qemu correctly and finaly request the lighttdp webserver either 
- directly over web-brwoser --> http://localhost:8080 or 
- over terminal --> curl http://localhost:8080

 
 ## setting up for beaglebone
