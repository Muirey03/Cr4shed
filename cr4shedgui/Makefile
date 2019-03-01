GO_EASY_ON_ME=1

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Cr4shed
Cr4shed_FILES = $(wildcard *.m)
Cr4shed_FRAMEWORKS = UIKit CoreGraphics WebKit
Cr4shed_CFLAGS = -fobjc-arc
Cr4shed_CODESIGN_FLAGS = -Sent.xml

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "killall \"Cr4shed\"" || true
