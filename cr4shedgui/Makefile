TARGET = iphone:clang:latest:11.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Cr4shed
Cr4shed_FILES = $(wildcard *.m) ../sharedutils.mm
Cr4shed_LDFLAGS += -F../Frameworks/ -L../Libraries/
Cr4shed_LIBRARIES = MobileGestalt
Cr4shed_FRAMEWORKS = UIKit CoreGraphics WebKit UserNotifications FRPreferences Cephei MessageUI
Cr4shed_CFLAGS = -fobjc-arc -I../Frameworks -I..
Cr4shed_CODESIGN_FLAGS = -Sent.xml

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "killall \"Cr4shed\"" || true
