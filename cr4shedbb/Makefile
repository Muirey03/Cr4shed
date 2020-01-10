INSTALL_TARGET_PROCESSES = backboardd

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Cr4shedBB

Cr4shedBB_FILES = TweakBB.xm
Cr4shedBB_CFLAGS = -fobjc-arc -I../Include
Cr4shedBB_LIBRARIES = rocketbootstrap
Cr4shedBB_LDFLAGS += -L../Libraries/
ADDITIONAL_CFLAGS += -DTHEOS_LEAN_AND_MEAN

include $(THEOS_MAKE_PATH)/tweak.mk
