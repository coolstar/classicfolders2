TARGET=iphone:clang:11.2:8.0
ARCHS = armv7 arm64 arm64e
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ClassicFoldersSettings
ClassicFoldersSettings_FILES = ClassicFoldersSettings.m CSClassicFoldersLogoCell.m
ClassicFoldersSettings_INSTALL_PATH = /Library/PreferenceBundles
ClassicFoldersSettings_FRAMEWORKS = UIKit
ClassicFoldersSettings_PRIVATE_FRAMEWORKS = Preferences
ClassicFoldersSettings_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ClassicFoldersSettings.plist$(ECHO_END)
