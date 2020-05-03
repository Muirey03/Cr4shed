export ARCHS = arm64 armv7 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 0Cr4shed
0Cr4shed_FILES = $(wildcard *.m *.mm *.xm Shared/*.mm)
0Cr4shed_CFLAGS = -fobjc-arc -std=c++11 -IInclude
0Cr4shed_FRAMEWORKS = CoreSymbolication
0Cr4shed_LIBRARIES = MobileGestalt mryipc
0Cr4shed_LDFLAGS += -FFrameworks/ -LLibraries/
ADDITIONAL_CFLAGS += -DTHEOS_LEAN_AND_MEAN

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
SUBPROJECTS += cr4shedgui
SUBPROJECTS += cr4shedmach
SUBPROJECTS += frpreferences
SUBPROJECTS += cr4shedd
include $(THEOS_MAKE_PATH)/aggregate.mk
