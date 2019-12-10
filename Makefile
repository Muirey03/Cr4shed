export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = __Cr4shed
__Cr4shed_FILES = $(wildcard *.m *.mm *.xm)
__Cr4shed_CFLAGS = -fobjc-arc -std=c++11
__Cr4shed_FRAMEWORKS = AppSupport CoreSymbolication
__Cr4shed_LIBRARIES = MobileGestalt
__Cr4shed_LDFLAGS += -FFrameworks/ -LLibraries/
ADDITIONAL_CFLAGS += -DTHEOS_LEAN_AND_MEAN -DROCKETBOOTSTRAP_LOAD_DYNAMIC

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
SUBPROJECTS += cr4shedsb
SUBPROJECTS += cr4shedgui
SUBPROJECTS += cr4shedmach
SUBPROJECTS += frpreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
