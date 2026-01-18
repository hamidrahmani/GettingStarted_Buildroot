# provide a package "gpio_web" allowing to interacwith bbb over web
## structure
- Buildroot package → compiled binaries only (/usr/bin/gpio_*_bin)
- Rootfs overlay → CGI wrappers, Lighttpd config, static web UI, init script

note:
GPIO via libgpiod is the modern, recommended API (sysfs is deprecated). 
Tools like gpiodetect/gpioinfo help you map the right lines.
Lighttpd’s mod_cgi with cgi.assign = ( "" => "" ) in a /cgi-bin (or aliased) path enables compiled CGI binaries.
## define following structure to host buildroot-packkage files
package/userdefinedapps/
├─ Config.in
├─ userdefinedapps.mk
└─ gpio_web/
   ├─ Config.in
   ├─ gpio_web.mk
   └─ src/
      ├─ gpio_read_bin.c
      └─ gpio_write_bin.c

Files in /src are the programs, which run on HW and interact with gpio and do the actual job.
After compilation of .c files via gpio_web.mk the generated outputs are placed inside /usr/bin/
    - /usr/bin/gpio_read_bin
    - /usr/bin/gpio_write_bin
These files are called wrappers, which get executed from .cgi files in rootfs-overlay/www/cgi-bin/


## define following structure to host overlays files
 ├─ www/
│  ├─ index.html
│  └─ cgi-bin/
│     ├─ gpio_read.cgi
│     ├─ gpio_write.cgi
│     └─ run_job.cgi
├─ etc/lighttpd/lighttpd.conf
└─ etc/init.d/S50lighttpd
|__var/log/lighttpd/
    |__access.log
    |__error.log

Files in /cgi-bin are the programs, which provide interface between gpio and webserver..
Files gpio_read.cgi, gpio_write.cgi and run_job.cgi must be executable. --> chmod +x ....  
      