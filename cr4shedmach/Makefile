INSTALL_TARGET_PROCESSES = ReportCrash

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Cr4shedMach

Cr4shedMach_FILES = $(wildcard *.xm *.mm ../Shared/*.mm)
Cr4shedMach_CFLAGS = -fobjc-arc -I../Include
Cr4shedMach_PRIVATE_FRAMEWORKS = CoreSymbolication
Cr4shedMach_EXTRA_FRAMEWORKS = Cephei
Cr4shedMach_LIBRARIES = MobileGestalt mryipc

include $(THEOS_MAKE_PATH)/tweak.mk
