################################################################################
#
# gpio_web
#
################################################################################

#GPIO_WEB_VERSION = 1.0
#GPIO_WEB_SITE = $(CURDIR)/package/userdefinedapps/gpio_web/src
#GPIO_WEB_SITE_METHOD = local
#define GPIO_WEB_BUILD_CMDS
#	$(MAKE) CROSS_COMPILE=$(TARGET_CROSS) -C $(@D)
#endef

#define GPIO_WEB_INSTALL_TARGET_CMDS
#	$(INSTALL) -D -m 0755 $(@D)/gpio_read_bin $(TARGET_DIR)/usr/bin/gpio_read_bin
#	$(INSTALL) -D -m 0755 $(@D)/gpio_write_bin $(TARGET_DIR)/usr/bin/gpio_write_bin
#endef
#$(eval $(generic-package))



GPIO_WEB_VERSION = 1.0
GPIO_WEB_SITE    = $(TOPDIR)/package/userdefinedapps/gpio_web/src
GPIO_WEB_SITE_METHOD = local
GPIO_WEB_LICENSE = MIT

GPIO_WEB_DEPENDENCIES = lighttpd libgpiod

define GPIO_WEB_BUILD_CMDS
    $(TARGET_MAKE_ENV) $(TARGET_CC) -O2 -o $(@D)/gpio_read_bin  $(@D)/gpio_read_bin.c -lgpiod
    $(TARGET_MAKE_ENV) $(TARGET_CC) -O2 -o $(@D)/gpio_write_bin $(@D)/gpio_write_bin.c -lgpiod
endef

define GPIO_WEB_INSTALL_TARGET_CMDS
    # Binaries
    $(INSTALL) -D -m 0755 $(@D)/gpio_read_bin  $(TARGET_DIR)/usr/bin/gpio_read_bin
    $(INSTALL) -D -m 0755 $(@D)/gpio_write_bin $(TARGET_DIR)/usr/bin/gpio_write_bin
endef

$(eval $(generic-package))

