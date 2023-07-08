ifeq ($(ROOTLESS),1)
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless
else
ARCHS = armv7 arm64 arm64e
TARGET = iphone:clang:latest:10.0
endif

include $(THEOS)/makefiles/common.mk

FRAMEWORK_NAME = FRPreferences

FRPreferences_FILES = $(wildcard *.m)
FRPreferences_PUBLIC_HEADERS = $(wildcard *.h)
FRPreferences_INSTALL_PATH = /Library/Frameworks
FRPreferences_CFLAGS = -fobjc-arc

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
FRPreferences_LDFLAGS += -install_name @rpath/FRPreferences.framework/FRPreferences
endif

include $(THEOS_MAKE_PATH)/framework.mk
