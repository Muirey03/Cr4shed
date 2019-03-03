ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = postinst
postinst_FILES = main.mm
postinst_CODESIGN_FLAGS = -Sent.xml
postinst_CFLAGS = -fobjc-arc
postinst_INSTALL_PATH = /DEBIAN

include $(THEOS_MAKE_PATH)/tool.mk
