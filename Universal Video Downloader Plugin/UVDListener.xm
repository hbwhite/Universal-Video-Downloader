//
//  UVDListener.xm
//  Universal Video Downloader
//
//  Created by Harrison White on 7/25/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "UVDAlertViewHandler.h"

// YouTube App Classes
// Adds support for the non-native YouTube app.

#import "YouTube/YTStream.h"

// These are files loaded by several different apps when a video isn't acutally playing, most likely as a video player test.
#define kFilesToIgnoreArray                     [NSArray arrayWithObjects:@"file://localhost/file:/fw-no-this-file.mp4", @"file://localhost/dev/null", nil]

static NSString *kPreferencesFilePathStr        = @"/private/var/mobile/Library/Preferences/com.harrisonapps.Universal-Video-Downloader.plist";

static NSString *kDidAcceptUserAgreementKey     = @"Did Accept User Agreement";
static NSString *kEnableAllApplicationsKey      = @"Enable All Applications";
static NSString *kEnabledApplicationsArrayKey   = @"Enabled Applications";

NSMutableArray *cachedVideoFileURLsArray = [[NSMutableArray arrayWithObjects:nil]retain];

static void videoDidLoadWithVideoFileURL(NSURL *videoFileURL) {
    if ([[NSFileManager defaultManager]fileExistsAtPath:kPreferencesFilePathStr]) {
        NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPreferencesFilePathStr];
        if (preferences) {
            if ([[preferences objectForKey:kDidAcceptUserAgreementKey]boolValue]) {
                BOOL applicationIsEnabled = NO;
                
                if ((![preferences objectForKey:kEnableAllApplicationsKey]) || (([preferences objectForKey:kEnableAllApplicationsKey]) && ([[preferences objectForKey:kEnableAllApplicationsKey]boolValue]))) {
                    applicationIsEnabled = YES;
                }
                else {
                    NSArray *enabledApplicationsArray = [preferences objectForKey:kEnabledApplicationsArrayKey];
                    if (enabledApplicationsArray) {
                        if ([enabledApplicationsArray containsObject:[[NSBundle mainBundle]bundleIdentifier]]) {
                            applicationIsEnabled = YES;
                        }
                    }
                }
                
                if (applicationIsEnabled) {
                    if (videoFileURL) {
                        NSString *urlString = [videoFileURL absoluteString];
                        if (urlString) {
                            if ([urlString length] > 0) {
                                if (![kFilesToIgnoreArray containsObject:urlString]) {
                                    if (![cachedVideoFileURLsArray containsObject:urlString]) {
                                        [cachedVideoFileURLsArray addObject:urlString];
                                        
                                        // For some reason, if I release this, even with -autorelease, it automatically gets released a second time by something else, causing the app to crash when the user interacts with the download alert.
                                        UVDAlertViewHandler *alertViewHandler = [[UVDAlertViewHandler alloc]initWithCachedVideoFileURLsArray:cachedVideoFileURLsArray];
                                        [alertViewHandler showAlert];
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

%hook AVPlayer

+ (id)playerWithURL:(NSURL *)URL {
    videoDidLoadWithVideoFileURL(URL);
    
    return %orig;
}

- (id)initWithURL:(NSURL *)URL {
    videoDidLoadWithVideoFileURL(URL);
    
    return %orig;
}

+ (id)playerWithPlayerItem:(AVPlayerItem *)playerItem {
    if (playerItem) {
        AVAsset *asset = [playerItem asset];
        if ([asset isKindOfClass:[AVURLAsset class]]) {
            AVURLAsset *urlAsset = (AVURLAsset *)asset;
            videoDidLoadWithVideoFileURL([urlAsset URL]);
        }
    }
    
    return %orig;
}

- (id)initWithPlayerItem:(AVPlayerItem *)playerItem {
    if (playerItem) {
        AVAsset *asset = [playerItem asset];
        if ([asset isKindOfClass:[AVURLAsset class]]) {
            AVURLAsset *urlAsset = (AVURLAsset *)asset;
            videoDidLoadWithVideoFileURL([urlAsset URL]);
        }
    }
    
    return %orig;
}

%end

%hook AVPlayerItem

+ (AVPlayerItem *)playerItemWithURL:(NSURL *)URL {
    videoDidLoadWithVideoFileURL(URL);
    
    return %orig;
}

- (id)initWithURL:(NSURL *)URL {
    videoDidLoadWithVideoFileURL(URL);
    
    return %orig;
}

// Safety Net

- (void)setURI:(NSString *)URI {
    if (URI) {
        NSURL *formattedURI = [NSURL URLWithString:URI];
        videoDidLoadWithVideoFileURL(formattedURI);
    }
    
    %orig;
}

%end

%hook AVAsset

+ (id)assetWithURL:(NSURL *)URL {
    videoDidLoadWithVideoFileURL(URL);
    
    return %orig;
}

+ (AVURLAsset *)URLAssetWithURL:(NSURL *)URL options:(NSDictionary *)options {
    videoDidLoadWithVideoFileURL(URL);
    
    return %orig;
}

- (id)initWithURL:(NSURL *)URL options:(NSDictionary *)options {
    videoDidLoadWithVideoFileURL(URL);
    
    return %orig;
}

// Safety Net

- (void)setURL:(NSURL *)URL {
    videoDidLoadWithVideoFileURL(URL);
    
    %orig;
}

%end

%hook MPMoviePlayerViewController

- (id)initWithContentURL:(NSURL *)contentURL {
    videoDidLoadWithVideoFileURL(contentURL);
    
    return %orig;
}

%end

%hook MPMoviePlayerController

- (id)initWithContentURL:(NSURL *)url {
    videoDidLoadWithVideoFileURL(url);
    
    return %orig;
}

- (void)setContentURL:(NSURL *)contentURL {
    videoDidLoadWithVideoFileURL(contentURL);
    
    %orig;
}

// Safety Net

- (void)setURI:(NSString *)URI {
    if (URI) {
        NSURL *formattedURI = [NSURL URLWithString:URI];
        videoDidLoadWithVideoFileURL(formattedURI);
    }
    
    %orig;
}

%end

// MediaPlayer Private Classes
// Adds support for the Safari app and the native YouTube app.

%hook MPAVItem

// iOS 4

- (id)initWithPath:(NSString *)path error:(id *)error {
    if (path) {
        NSURL *url = [NSURL URLWithString:path];
        videoDidLoadWithVideoFileURL(url);
    }
    
    return %orig;
}

// iOS 5

- (id)initWithAsset:(AVURLAsset *)asset {
    if (asset) {
        videoDidLoadWithVideoFileURL([asset URL]);
    }
    
    return %orig;
}

- (id)initWithURL:(NSURL *)url options:(id)options {
    videoDidLoadWithVideoFileURL(url);
    
    return %orig;
}

- (id)initWithURL:(NSURL *)url {
    videoDidLoadWithVideoFileURL(url);
    
    return %orig;
}

%end

// YouTube App Classes
// Adds support for the non-native YouTube app.

%hook YTPlayerController

- (void)setAndPlayVideoStream:(YTStream *)videoStream {
    if (videoStream) {
        // I don't perform this selector safety check on the AVFoundation framework's classes because I believe that they're much more stable than these ones.
        if ([videoStream respondsToSelector:@selector(URL)]) {
            NSURL *url = [videoStream URL];
            if (url) {
                if ([url isKindOfClass:[NSURL class]]) {
                    videoDidLoadWithVideoFileURL(url);
                }
            }
        }
    }
    
    %orig;
}

%end

// This resolves conflicts with Gremlin.
%ctor {
    NSString *bundleIdentifier = [[NSBundle mainBundle]bundleIdentifier];
    if ((![bundleIdentifier hasPrefix:@"com.harrisonapps"]) && (![bundleIdentifier isEqualToString:@"co.cocoanuts.gremlind"])) {
        %init;
    }
}
