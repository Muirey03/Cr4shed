GO_EASY_ON_ME=1

ARCHS = armv7 arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Cr4shedSB
Cr4shedSB_FILES = Tweak.xm
Cr4shedSB_FRAMEWORKS = UIKit AppSupport
Cr4shedSB_CFLAGS = -fobjc-arc
Cr4shedSB_LIBRARIES = rocketbootstrap bulletin
Cr4shedSB_LDFLAGS += -F../Frameworks/ -L../Libraries/

include $(THEOS_MAKE_PATH)/tweak.mk
