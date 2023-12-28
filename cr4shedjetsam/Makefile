INSTALL_TARGET_PROCESSES = ReportMemoryException

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Cr4shedJetsam
Cr4shedJetsam_FILES = $(wildcard *.xm *.mm ../Shared/*.mm) ../cr4shedmach/mach_utils.mm
Cr4shedJetsam_CFLAGS = -fobjc-arc -I../Include
Cr4shedJetsam_PRIVATE_FRAMEWORKS = CoreSymbolication
Cr4shedJetsam_EXTRA_FRAMEWORKS = Cephei
Cr4shedJetsam_LIBRARIES = MobileGestalt mryipc

include $(THEOS_MAKE_PATH)/tweak.mk
