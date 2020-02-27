INSTALL_TARGET_PROCESSES = ReportCrash

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Cr4shedMach

Cr4shedMach_FILES = $(wildcard *.xm *.mm ../Shared/*.mm)
Cr4shedMach_CFLAGS = -fobjc-arc -I../Include
Cr4shedMach_LDFLAGS += -F../Frameworks/ -L../Libraries/
Cr4shedMach_FRAMEWORKS = CoreSymbolication
Cr4shedMach_LIBRARIES = MobileGestalt notifications mryipc
ADDITIONAL_CFLAGS += -DTHEOS_LEAN_AND_MEAN

include $(THEOS_MAKE_PATH)/tweak.mk
