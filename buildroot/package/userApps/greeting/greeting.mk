################################################################################
#
# greeting
#
################################################################################

GREETING_VERSION = 1.0
GREETING_SITE = $(CURDIR)/package/userApps/greeting/src
GREETING_SITE_METHOD = local
define GREETING_BUILD_CMDS
	$(MAKE) CROSS_COMPILE=$(TARGET_CROSS) -C $(@D)
endef

define GREETING_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/greeting $(TARGET_DIR)/usr/bin/greeting
endef
$(eval $(generic-package))

