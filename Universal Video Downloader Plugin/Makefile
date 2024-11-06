SYSROOT = /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.0.sdk
ARCHS = armv7 armv7s arm64

include /Users/Harrison/theos/makefiles/common.mk

TWEAK_NAME = UniversalVideoDownloader
UniversalVideoDownloader_FILES = UVDListener.xm UVDAlertViewHandler.m UVDVideoProcessor.m UVDAuthenticationDialog.m UVDDataCompressor.m UVDDataDecompressor.m UVDHTTPRequest.m UVDInputStream.m UVDReachability.m
UniversalVideoDownloader_FRAMEWORKS = UIKit Foundation AVFoundation MediaPlayer CFNetwork SystemConfiguration MobileCoreServices CoreGraphics
UniversalVideoDownloader_LDFLAGS = -lz

include $(THEOS_MAKE_PATH)/tweak.mk