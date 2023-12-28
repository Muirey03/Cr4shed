include $(THEOS)/makefiles/common.mk

TOOL_NAME = cr4shedd
cr4shedd_FILES = $(wildcard *.mm) ../Shared/sharedutils.mm
cr4shedd_INSTALL_PATH = /usr/libexec
cr4shedd_CODESIGN_FLAGS = -Sent.plist
cr4shedd_CFLAGS = -fobjc-arc -I../Include
cr4shedd_LIBRARIES = mryipc MobileGestalt
cr4shedd_EXTRA_FRAMEWORKS = Cephei

include $(THEOS_MAKE_PATH)/tool.mk

internal-stage::
ifneq ($(THEOS_PACKAGE_SCHEME),)
	@sed -i 's@/usr/libexec/$(TOOL_NAME)@$(THEOS_PACKAGE_INSTALL_PREFIX)/usr/libexec/$(TOOL_NAME)@' \
		$(THEOS_STAGING_DIR)/Library/LaunchDaemons/com.muirey03.$(TOOL_NAME).plist
endif