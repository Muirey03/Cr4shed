include $(THEOS)/makefiles/common.mk

TWEAK_NAME = __Cr4shedSB
__Cr4shedSB_FILES = TweakSB.xm ../sharedutils.mm
__Cr4shedSB_FRAMEWORKS = UIKit AppSupport
__Cr4shedSB_CFLAGS = -fobjc-arc
__Cr4shedSB_LIBRARIES = rocketbootstrap notifications MobileGestalt
__Cr4shedSB_LDFLAGS += -F../Frameworks/ -L../Libraries/

include $(THEOS_MAKE_PATH)/tweak.mk
