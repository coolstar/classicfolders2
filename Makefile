TARGET = iphone:latest:7.0
ARCHS = arm64
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ClassicFolders2
ClassicFolders2_FILES = iOS13.x iOS11.x iOS10.x iOS8and9.x iOS78SwitcherBugFix.x CSClassicFolderView.x UIImage+ClassicFolders.m CSClassicFolderSettingsManager.m CSClassicFolderTextField.m iOS10BlurRemoval.x BackgroundBlur.x RootFolderBugFix.x Icon.x IconListViewBugFix.x 
ClassicFolders2_FILES += ForceBinds.x
ClassicFolders2_CFLAGS = -Iinclude -include sha1.pch -include DRM.pch
#ClassicFolders2_CFLAGS = -include DRM-dummy.pch
#ClassicFolders2_OBJ_FILES = libcrypto.a
ClassicFolders2_FRAMEWORKS = IOKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += classicfolderssettings
include $(THEOS_MAKE_PATH)/aggregate.mk
