ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Cr4shed
Cr4shed_FILES = Tweak.xm
Cr4shed_FRAMEWORKS = UIKit
Cr4shed_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
