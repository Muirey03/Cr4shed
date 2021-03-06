include $(THEOS)/makefiles/common.mk

TOOL_NAME = cr4shedd
cr4shedd_FILES = $(wildcard *.mm) ../Shared/sharedutils.mm
cr4shedd_INSTALL_PATH = /usr/libexec
cr4shedd_CODESIGN_FLAGS = -Sent.plist
cr4shedd_CFLAGS = -fobjc-arc -I../Include
cr4shedd_LIBRARIES = mryipc notifications MobileGestalt
cr4shedd_LDFLAGS += -F../Frameworks/ -L../Libraries/
ADDITIONAL_CFLAGS += -DTHEOS_LEAN_AND_MEAN

include $(THEOS_MAKE_PATH)/tool.mk
