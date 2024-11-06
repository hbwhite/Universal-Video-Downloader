//
//  AppDelegate.h
//  Universal Video Downloader
//
//  Created by Harrison White on 3/18/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#import "VideoDownloadOptionsViewController.h"

#define kAdUnitID                   @"a14fd78d250bd6a"

#define kAdDidShowNotification		@"kAdDidShowNotification"
#define kAdDidHideNotification	@"kAdDidHideNotification"

enum {
    kDownloadStateDownloading   = 0,
    kDownloadStateWaiting       = 1,
    kDownloadStatePaused        = 2,
    kDownloadStateFailed        = 3
};
typedef NSUInteger kDownloadState;

@class RootViewController;
@class HTTPServer;
@class ASINetworkQueue;
@class ASIHTTPRequest;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, VideoDownloadOptionsViewControllerDelegate> {
    RootViewController *rootViewController;
    UIWindow *window;
    
    UITableView *theTableView;
    
    ASINetworkQueue *currentDownload;
    NSMutableArray *downloadsArray;
    NSMutableArray *pendingDownloadArray;
    UIActionSheet *optionsActionSheet;
    NSInteger activeDownloadCount;
    
    NSTimer *downloadUpdateTimer;
    
    NSMutableString *pendingVideoDirectoryFilePath;
    NSMutableArray *pendingAudioTracksArray;
    NSMutableArray *pendingVideosArray;
    NSMutableDictionary *pendingVideoFileURLsDictionary;
    BOOL pendingVideoIsVideoStream;
    
    NSDecimalNumberHandler *decimalNumberHandler;
    
    HTTPServer *httpServer;
    
    BOOL viewIsVisible;
    
    BOOL wasLaunchedExternally;
    
    UIBackgroundTaskIdentifier backgroundTask;
    BOOL isRunningInBackground;
}

@property (nonatomic, retain) RootViewController *rootViewController;
@property (nonatomic, retain) UIWindow *window;

@property (nonatomic, retain) UITableView *theTableView;

@property (nonatomic, assign) ASINetworkQueue *currentDownload;
@property (nonatomic, retain) NSMutableArray *downloadsArray;
@property (nonatomic, retain) NSMutableArray *pendingDownloadArray;
@property (nonatomic, assign) UIActionSheet *optionsActionSheet;
@property (nonatomic) NSInteger activeDownloadCount;

@property (nonatomic, assign) NSTimer *downloadUpdateTimer;

@property (nonatomic, retain) NSMutableString *pendingVideoDirectoryFilePath;
@property (nonatomic, retain) NSMutableArray *pendingAudioTracksArray;
@property (nonatomic, retain) NSMutableArray *pendingVideosArray;
@property (nonatomic, retain) NSMutableDictionary *pendingVideoFileURLsDictionary;
@property (readwrite) BOOL pendingVideoIsVideoStream;

@property (nonatomic, retain) NSDecimalNumberHandler *decimalNumberHandler;

@property (nonatomic, retain) HTTPServer *httpServer;

@property (readwrite) BOOL viewIsVisible;

@property (readwrite) BOOL wasLaunchedExternally;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (readwrite) BOOL isRunningInBackground;

- (void)runBasicSetup;
- (void)startServer;
- (void)showWelcomeAlert;
- (void)deleteSavedPendingVideoDirectoryFilePath;
- (void)presentVideoDownloadOptionsViewControllerWithPendingVideoDirectoryFilePath:(NSString *)path usingSavedVideoDirectoryFilePath:(BOOL)isUsingSavedVideoDirectoryFilePath;
- (void)createDownloadWithParameters:(NSArray *)downloadParameters;
- (void)dismissRootViewControllerModalViewController;
- (void)updateDownloads;
- (void)updateDownloadElements;
- (void)updateCurrentDownload;
- (NSString *)megaBytesStringFromBytes:(unsigned long long)bytes;
- (NSString *)stringFromDecimalNumber:(NSDecimalNumber *)decimalNumber;
- (void)deleteDownload;
- (void)setDownloadPaused:(NSNumber *)paused;

@end
