################################################################################
#
# greeting2
#
################################################################################

GREETING2_VERSION = 1.0
GREETING2_SITE = $(CURDIR)/package/userApps/greeting2
GREETING2_SITE_METHOD = local
define GREETING2_BUILD_CMDS
	$(TARGET_CC) $(@D)/greeting2.c -o $(@D)/greeting2
endef

define GREETING2_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/greeting2 $(TARGET_DIR)/usr/bin/greeting2
endef
$(eval $(generic-package))

