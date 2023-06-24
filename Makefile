export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:10.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 0Cr4shed
0Cr4shed_FILES = $(wildcard *.m *.mm *.xm Shared/*.mm)
0Cr4shed_CFLAGS = -fobjc-arc -std=c++11 -IInclude
0Cr4shed_FRAMEWORKS = CoreSymbolication
0Cr4shed_LIBRARIES = MobileGestalt mryipc
0Cr4shed_LDFLAGS += -FFrameworks/ -LLibraries/

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "ldrestart"
SUBPROJECTS += cr4shedgui
SUBPROJECTS += cr4shedmach
SUBPROJECTS += cr4shedjetsam
SUBPROJECTS += frpreferences
SUBPROJECTS += cr4shedd
include $(THEOS_MAKE_PATH)/aggregate.mk
