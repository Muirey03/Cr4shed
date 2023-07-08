ifeq ($(ROOTLESS),1)
export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:15.0
export THEOS_PACKAGE_SCHEME = rootless
else
export ARCHS = armv7 arm64 arm64e
export TARGET = iphone:clang:latest:10.0
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 0Cr4shed
0Cr4shed_FILES = $(wildcard *.m *.mm *.xm Shared/*.mm)
0Cr4shed_CFLAGS = -fobjc-arc -std=c++11 -IInclude
0Cr4shed_PRIVATE_FRAMEWORKS = CoreSymbolication
0Cr4shed_EXTRA_FRAMEWORKS = Cephei
0Cr4shed_LIBRARIES = MobileGestalt mryipc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += cr4shedmach cr4shedjetsam cr4shedd frpreferences cr4shedgui

include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "ldrestart"