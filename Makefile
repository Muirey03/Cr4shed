export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Cr4shed
Cr4shed_FILES = $(wildcard *.m *.mm *.xm)
Cr4shed_CFLAGS = -fobjc-arc
Cr4shed_FRAMEWORKS = AppSupport CoreSymbolication
Cr4shed_LIBRARIES = MobileGestalt rocketbootstrap
Cr4shed_LDFLAGS += -FFrameworks/ -LLibraries/
ADDITIONAL_CFLAGS += -DTHEOS_LEAN_AND_MEAN

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
SUBPROJECTS += cr4shedsb
SUBPROJECTS += cr4shedgui
include $(THEOS_MAKE_PATH)/aggregate.mk
