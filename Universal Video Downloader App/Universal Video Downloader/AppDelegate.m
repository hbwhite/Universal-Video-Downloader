//
//  AppDelegate.m
//  Universal Video Downloader
//
//  Created by Harrison White on 3/18/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "RootViewController.h"
#import "UserAgreementViewController.h"
#import "VideosViewController.h"
#import "DownloadsViewController.h"
#import "DownloadCell.h"
#import "MBProgressHUD.h"

#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"

#import "HTTPServer.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

#define DOWNLOAD_STATE_INDEX                            0
#define CREATION_TIME_INDEX                             1
#define VIDEO_TITLE_INDEX                               2
#define DOWNLOAD_DIRECTORY_FILE_NAME_INDEX              3

#define MAXIMUM_CONCURRENT_DOWNLOADS                    3
#define DOWNLOAD_TIMEOUT_IN_SECONDS                     30
#define DOWNLOAD_ATTEMPTS                               3

#define FAILED_COLOR_RED                                (180.0 / 255.0)
#define FAILED_COLOR_GREEN                              0.1372549
#define FAILED_COLOR_BLUE                               (15.0 / 255.0)

#define ROW_HEIGHT                                      90

#define DOWNLOAD_TIMER_UPDATE_INTERVAL_IN_SECONDS       1

#define MB_FLOAT_SIZE                                   1048576.0

#define kFileNameReplacementStringsArray                [NSArray arrayWithObjects:@"/", @"-", nil]

/*
// Simulator Debugging
#warning Don't forget to remove the simulator debugging code.
// Download foundation path modified for safety.
static NSString *kDownloadFoundationPathStr             = @"/Users/Harrison/Desktop/Downloads
static NSString *kTemporaryFileDownloadPathStr          = @"/Users/Harrison/Desktop/Downloads";
static NSString *kDownloadDestinationPathStr            = @"/Users/Harrison/Desktop/Finished_Downloads";
static NSString *kVideoFolderDestinationPath            = @"/Users/Harrison/Desktop/Universal_Video_Downloader";
*/

/*
// Device Debugging
#warning Don't forget to remove the device debugging code.
// Download foundation path modified for safety.
#define kDownloadFoundationPathStr                      [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
#define kTemporaryFileDownloadPathStr                   [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:@"Downloads"]
#define kDownloadDestinationPathStr                     [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:@"Finished_Downloads"]
#define kVideoFolderDestinationPath                     [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
*/


// Deployment
static NSString *kDownloadFoundationPathStr             = @"/private/var/mobile/Library/Universal_Video_Downloader";
static NSString *kTemporaryFileDownloadPathStr          = @"/private/var/mobile/Library/Universal_Video_Downloader/Downloads";
static NSString *kDownloadDestinationPathStr            = @"/private/var/mobile/Library/Universal_Video_Downloader/Finished_Downloads";
static NSString *kVideoFolderDestinationPath            = @"/private/var/mobile/Media/Universal_Video_Downloader";


static NSString *kDefaultsSetKey                        = @"Defaults Set";
static NSString *kDidAcceptUserAgreementKey             = @"Did Accept User Agreement";
static NSString *kWelcomeAlertShownKey                  = @"Welcome Alert Shown";
static NSString *kDownloadAlertsKey                     = @"Download Alerts Enabled";
static NSString *kPendingVideoDirectoryFilePathKey      = @"Pending Video Directory File Path";

// Metadata Keys
static NSString *kIsVideoStreamKey                      = @"Video Stream";
static NSString *kIndexFileNameKey                      = @"Index File Name";
static NSString *kCreationTimeKey                       = @"Creation Time";
static NSString *kDownloadStateKey                      = @"Download State";
static NSString *kAudioTracksKey                        = @"Audio Tracks";
static NSString *kAudioTrackReferenceFileNameKey        = @"Audio Track Reference File Name";
static NSString *kAudioTrackFileURLsDictionaryKey       = @"Audio Track File URLs Dictionary";
static NSString *kVideosKey                             = @"Videos";
static NSString *kVideoReferenceFileNameKey             = @"Video Reference File Name";
static NSString *kVideoFileURLsDictionaryKey            = @"Video File URLs Dictionary";
static NSString *kBandwidthKey                          = @"Bandwidth";
static NSString *kFileURLsDictionaryKey                 = @"File URLs Dictionary";
static NSString *kSizeInBytesKey                        = @"Size In Bytes";
static NSString *kCurrentPlaybackTimeKey                = @"Current Playback Time";
static NSString *kLocalBytesCopiedKey                   = @"Local Bytes Copied";

// Metadata and Download Queue User Info Keys
static NSString *kVideoTitleKey                         = @"Video Title";

// Download Queue User Info Keys
static NSString *kBytesPermanentlyDownloadedSoFarKey    = @"Bytes Permanently Downloaded So Far";
static NSString *kCalculatingTotalSizeKey               = @"Calculating Total Size";
static NSString *kDidFailKey                            = @"Did Fail";

static NSString *kMetadataFileNameStr                   = @"Metadata.plist";

static NSString *kCopyFormatStr                         = @" (%i)";

static NSString *kStringFormatSpecifierStr              = @"%@";
static NSString *kFloatFormatSpecifierStr               = @"%f";
static NSString *kIntegerFormatSpecifierStr             = @"%i";

static NSString *kDecimalStr                            = @".";
static NSString *kTenthAppendStr                        = @"0";
static NSString *kWholeNumberAppendStr                  = @".00";

static NSString *kNullStr                               = @"";

// Log levels: off, error, warn, info, verbose
// static const int ddLogLevel                          = LOG_LEVEL_VERBOSE;
static const int ddLogLevel                             = LOG_LEVEL_OFF;

@implementation AppDelegate

@synthesize rootViewController;
@synthesize window;

@synthesize theTableView;

@synthesize currentDownload;
@synthesize downloadsArray;
@synthesize pendingDownloadArray;
@synthesize optionsActionSheet;
@synthesize activeDownloadCount;

@synthesize downloadUpdateTimer;

@synthesize pendingVideoDirectoryFilePath;
@synthesize pendingAudioTracksArray;
@synthesize pendingVideosArray;
@synthesize pendingVideoFileURLsDictionary;
@synthesize pendingVideoIsVideoStream;

@synthesize decimalNumberHandler;

@synthesize httpServer;

@synthesize viewIsVisible;

@synthesize wasLaunchedExternally;

@synthesize backgroundTask;
@synthesize isRunningInBackground;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // This prevents a conflict between the last pending video and the one that the app was launched to download (if applicable; only one instance of VideoDownloadOptionsViewController can be shown).
    if (launchOptions) {
        NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
        if (url) {
            NSString *urlString = [url absoluteString];
            if (urlString) {
                if ([urlString length] > 0) {
                    wasLaunchedExternally = YES;
                }
            }
        }
    }
    
    window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen]bounds]];
    // Override point for customization after application launch.
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults boolForKey:kDefaultsSetKey]) {
        [defaults setValuesForKeysWithDictionary:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"Defaults" ofType:@"plist"]]];
        [defaults synchronize];
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:kDownloadFoundationPathStr]) {
        if (![fileManager createDirectoryAtPath:kDownloadFoundationPathStr withIntermediateDirectories:NO attributes:nil error:nil]) {
            UIAlertView *errorAlert = [[UIAlertView alloc]
                                       initWithTitle:@"Error Creating Download Foundation Folder"
                                       message:@"The app encountered an error while trying to create the download foundation folder. Please make sure the app has read and write access to the directory at /var/mobile/Library and try again."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [errorAlert show];
            [errorAlert release];
        }
    }
    if (![fileManager fileExistsAtPath:kTemporaryFileDownloadPathStr]) {
        if (![fileManager createDirectoryAtPath:kTemporaryFileDownloadPathStr withIntermediateDirectories:NO attributes:nil error:nil]) {
            UIAlertView *errorAlert = [[UIAlertView alloc]
                                       initWithTitle:@"Error Creating Temporary Download Folder"
                                       message:@"The app encountered an error while trying to create the temporary download folder. Please make sure the app has read and write access to the directory at /var/mobile/Media/Universal_Video_Downloader and try again."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [errorAlert show];
            [errorAlert release];
        }
    }
    if (![fileManager fileExistsAtPath:kDownloadDestinationPathStr]) {
        if (![fileManager createDirectoryAtPath:kDownloadDestinationPathStr withIntermediateDirectories:NO attributes:nil error:nil]) {
            UIAlertView *errorAlert = [[UIAlertView alloc]
                                       initWithTitle:@"Error Creating Download Folder"
                                       message:@"The app encountered an error while trying to create the download folder. Please make sure the app has read and write access to the directory at /var/mobile/Media/Universal_Video_Downloader and try again."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [errorAlert show];
            [errorAlert release];
        }
    }
    if (![fileManager fileExistsAtPath:kVideoFolderDestinationPath]) {
        if (![fileManager createDirectoryAtPath:kVideoFolderDestinationPath withIntermediateDirectories:NO attributes:nil error:nil]) {
            UIAlertView *errorAlert = [[UIAlertView alloc]
                                       initWithTitle:@"Error Creating Media Folder"
                                       message:@"The app encountered an error while trying to create the media folder. Please make sure the app has read and write access to the directory at /var/mobile/Media and try again."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [errorAlert show];
            [errorAlert release];
        }
    }
    
    downloadsArray = [[NSMutableArray alloc]init];
    pendingDownloadArray = [[NSMutableArray alloc]init];
    
    pendingVideoDirectoryFilePath = [[NSMutableString alloc]init];
    pendingAudioTracksArray = [[NSMutableArray alloc]init];
    pendingVideosArray = [[NSMutableArray alloc]init];
    pendingVideoFileURLsDictionary = [[NSMutableDictionary alloc]init];
    
    decimalNumberHandler = [[NSDecimalNumberHandler alloc]
                            initWithRoundingMode:NSRoundPlain
                            scale:2
                            raiseOnExactness:NO
                            raiseOnOverflow:NO
                            raiseOnUnderflow:NO
                            raiseOnDivideByZero:NO];
    
    httpServer = [[HTTPServer alloc]init];
    [self startServer];
    
    theTableView = [[UITableView alloc]initWithFrame:self.window.frame style:UITableViewStylePlain];
    theTableView.dataSource = self;
    theTableView.delegate = self;
    theTableView.rowHeight = ROW_HEIGHT;
    
    rootViewController = [[RootViewController alloc]init];
    window.rootViewController = rootViewController;
    
    [window makeKeyAndVisible];
    
    // When setting the root view controller of an instance UIWindow (which is necessary for autorotation to work properly in iOS 6), modal presentation code must be executed after the window's -makeKeyAndVisible function is called for it to work properly.
    if ([defaults boolForKey:kDidAcceptUserAgreementKey]) {
        // -runBasicSetup includes modal presentation code if there is a pending video.
        [self runBasicSetup];
    }
    else {
        UserAgreementViewController *userAgreementViewController = nil;
        if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            if ([[UIScreen mainScreen]bounds].size.height == 568) {
                userAgreementViewController = [[UserAgreementViewController alloc]initWithNibName:@"UserAgreementViewController_iPhone568" bundle:nil];
            }
            else {
                userAgreementViewController = [[UserAgreementViewController alloc]initWithNibName:@"UserAgreementViewController_iPhone" bundle:nil];
            }
        }
        else {
            userAgreementViewController = [[UserAgreementViewController alloc]initWithNibName:@"UserAgreementViewController_iPad" bundle:nil];
        }
        
        // Modified to use iOS 5's new modal view controller functions when possible.
        if ([rootViewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
            [rootViewController presentViewController:userAgreementViewController animated:NO completion:nil];
        }
        else {
            [rootViewController presentModalViewController:userAgreementViewController animated:NO];
        }
        
        [userAgreementViewController release];
    }
    
    return YES;
}

- (void)runBasicSetup {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults boolForKey:kWelcomeAlertShownKey]) {
        [self showWelcomeAlert];
    }
    
    [self updateDownloads];
    
    NSString *path = [defaults objectForKey:kPendingVideoDirectoryFilePathKey];
    if (path) {
        if ([path length] > 0) {
            // This prevents a conflict between the last pending video and the one that the app was launched to download (if applicable; only one instance of VideoDownloadOptionsViewController can be shown).
            if (!wasLaunchedExternally) {
                [self presentVideoDownloadOptionsViewControllerWithPendingVideoDirectoryFilePath:path usingSavedVideoDirectoryFilePath:YES];
            }
        }
        else {
            // This will probably never happen, but I'm including it so the app will save disk space if it ever does.
            [self deleteSavedPendingVideoDirectoryFilePath];
        }
    }
}

- (void)startServer {
    [httpServer start:nil];
    
    /*
    NSError *error = nil;
	if ([httpServer start:&error]) {
		DDLogInfo(@"Started HTTP Server on port %hu", [httpServer listeningPort]);
	}
	else {
		DDLogError(@"Error starting HTTP Server: %@", error);
	}
    */
    
    /*
    NSError *error = nil;
    [httpServer start:&error];
    if (error) {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Error Starting Local Streaming Server"
                                   message:@"The app encountered an error while trying to start the local streaming server. Video playback may not work properly."
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
    }
    */
}

- (void)showWelcomeAlert {
    UIAlertView *welcomeAlert = [[UIAlertView alloc]
                                 initWithTitle:@"Welcome to the Universal Video Downloader!"
                                 message:@"To get started, select the \"Help\" tab at the bottom of the screen and follow the instructions. We hope you enjoy using the app."
                                 delegate:self
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
    [welcomeAlert show];
    [welcomeAlert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kWelcomeAlertShownKey];
    [defaults synchronize];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return (url != nil);
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if (url) {
        NSString *urlString = [url absoluteString];
        if (urlString) {
            if ([urlString length] > 0) {
                NSRange range = [urlString rangeOfString:@":"];
                NSString *formattedURLString = [urlString substringFromIndex:(range.location + 1)];
                if (formattedURLString) {
                    if ([formattedURLString length] > 0) {
                        [self presentVideoDownloadOptionsViewControllerWithPendingVideoDirectoryFilePath:formattedURLString usingSavedVideoDirectoryFilePath:NO];
                        
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}

- (void)deleteSavedPendingVideoDirectoryFilePath {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kPendingVideoDirectoryFilePathKey];
    [defaults synchronize];
}

- (void)presentVideoDownloadOptionsViewControllerWithPendingVideoDirectoryFilePath:(NSString *)path usingSavedVideoDirectoryFilePath:(BOOL)isUsingSavedVideoDirectoryFilePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:path]) {
        // Return if there isn't a directory pending video directory file path (in case the user manually deleted it) to help prevent the app from crashing when it tries to load files within it.
        return;
    }
    
    NSString *videoMetadataDictionaryFilePath = [path stringByAppendingPathComponent:kMetadataFileNameStr];
    NSDictionary *videoMetadataDictionary = [NSDictionary dictionaryWithContentsOfFile:videoMetadataDictionaryFilePath];
    if (videoMetadataDictionary) {
        if ([[videoMetadataDictionary objectForKey:kIsVideoStreamKey]boolValue]) {
            NSArray *audioTracksArray = [videoMetadataDictionary objectForKey:kAudioTracksKey];
            if ((audioTracksArray) && ([audioTracksArray count] > 0)) {
                if (![pendingAudioTracksArray isEqualToArray:audioTracksArray]) {
                    [pendingAudioTracksArray setArray:audioTracksArray];
                }
            }
            else {
                [pendingAudioTracksArray removeAllObjects];
            }
            
            NSArray *videosArray = [videoMetadataDictionary objectForKey:kVideosKey];
            if ((videosArray) && ([videosArray count] > 0)) {
                BOOL shouldSavePath = YES;
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                
                NSString *currentPath = [defaults objectForKey:kPendingVideoDirectoryFilePathKey];
                if (currentPath) {
                    if ([currentPath isEqualToString:path]) {
                        shouldSavePath = NO;
                    }
                    else {
                        // Delete the previous pending video so it doesn't waste disk space on the user's device (setting a new pending video directory file path will prevent interaction with the previous pending video).
                        [fileManager removeItemAtPath:currentPath error:nil];
                    }
                }
                
                if (shouldSavePath) {
                    [defaults setObject:path forKey:kPendingVideoDirectoryFilePathKey];
                    [defaults synchronize];
                }
                
                if (![pendingVideoDirectoryFilePath isEqualToString:path]) {
                    [pendingVideoDirectoryFilePath setString:path];
                }
                
                if (![pendingVideosArray isEqualToArray:videosArray]) {
                    [pendingVideosArray setArray:videosArray];
                }
                
                pendingVideoIsVideoStream = YES;
                
                VideoDownloadOptionsViewController *videoDownloadOptionsViewController = nil;
                
                if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                    if ([[UIScreen mainScreen]bounds].size.height == 568) {
                        videoDownloadOptionsViewController = [[VideoDownloadOptionsViewController alloc]initWithNibName:@"VideoDownloadOptionsViewController_iPhone568" bundle:nil];
                    }
                    else {
                        videoDownloadOptionsViewController = [[VideoDownloadOptionsViewController alloc]initWithNibName:@"VideoDownloadOptionsViewController_iPhone" bundle:nil];
                    }
                }
                else {
                    videoDownloadOptionsViewController = [[VideoDownloadOptionsViewController alloc]initWithNibName:@"VideoDownloadOptionsViewController_iPad" bundle:nil];
                }
                
                videoDownloadOptionsViewController.delegate = self;
                
                // Modified to use iOS 5's new modal view controller functions when possible.
                if (rootViewController.modalViewController) {
                    if ([rootViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
                        [rootViewController dismissViewControllerAnimated:NO completion:nil];
                    }
                    else {
                        [rootViewController dismissModalViewControllerAnimated:NO];
                    }
                    
                    // Wait until the modal view controller has been dismissed so that a new one can be presented.
                    while (rootViewController.modalViewController);
                }
                
                // Modified to use iOS 5's new modal view controller functions when possible.
                // This is redundant, but I'm including it for the sake of simplicity and stability.
                if ([rootViewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
                    [rootViewController presentViewController:videoDownloadOptionsViewController animated:YES completion:nil];
                }
                else {
                    [rootViewController presentModalViewController:videoDownloadOptionsViewController animated:YES];
                }
                
                [videoDownloadOptionsViewController release];
            }
            else {
                [self deleteSavedPendingVideoDirectoryFilePath];
                
                [fileManager removeItemAtPath:path error:nil];
                
                if (!isUsingSavedVideoDirectoryFilePath) {
                    UIAlertView *errorAlert = [[UIAlertView alloc]
                                               initWithTitle:@"Error Reading Video Metadata"
                                               message:@"The app encountered an error while trying to read the video metadata. The app you were trying to download videos from may not be supported at this time."
                                               delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
                    [errorAlert show];
                    [errorAlert release];
                }
            }
        }
        else {
            NSDictionary *videoFileURLsDictionary = [videoMetadataDictionary objectForKey:kVideoFileURLsDictionaryKey];
            if (videoFileURLsDictionary) {
                BOOL shouldSavePath = YES;
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                
                NSString *currentPath = [defaults objectForKey:kPendingVideoDirectoryFilePathKey];
                if (currentPath) {
                    if ([currentPath isEqualToString:path]) {
                        shouldSavePath = NO;
                    }
                    else {
                        // Delete the previous pending video so it doesn't waste disk space on the user's device (setting a new pending video directory file path will prevent interaction with the previous pending video).
                        [fileManager removeItemAtPath:currentPath error:nil];
                    }
                }
                
                if (shouldSavePath) {
                    [defaults setObject:path forKey:kPendingVideoDirectoryFilePathKey];
                    [defaults synchronize];
                }
                
                if (![pendingVideoDirectoryFilePath isEqualToString:path]) {
                    [pendingVideoDirectoryFilePath setString:path];
                }
                
                if (![pendingVideoFileURLsDictionary isEqualToDictionary:videoFileURLsDictionary]) {
                    [pendingVideoFileURLsDictionary setDictionary:videoFileURLsDictionary];
                }
                
                pendingVideoIsVideoStream = NO;
                
                VideoDownloadOptionsViewController *videoDownloadOptionsViewController = nil;
                
                if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                    if ([[UIScreen mainScreen]bounds].size.height == 568) {
                        videoDownloadOptionsViewController = [[VideoDownloadOptionsViewController alloc]initWithNibName:@"VideoDownloadOptionsViewController_iPhone568" bundle:nil];
                    }
                    else {
                        videoDownloadOptionsViewController = [[VideoDownloadOptionsViewController alloc]initWithNibName:@"VideoDownloadOptionsViewController_iPhone" bundle:nil];
                    }
                }
                else {
                    videoDownloadOptionsViewController = [[VideoDownloadOptionsViewController alloc]initWithNibName:@"VideoDownloadOptionsViewController_iPad" bundle:nil];
                }
                
                videoDownloadOptionsViewController.delegate = self;
                
                // Modified to use iOS 5's new modal view controller functions when possible.
                if (rootViewController.modalViewController) {
                    if ([rootViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
                        [rootViewController dismissViewControllerAnimated:NO completion:nil];
                    }
                    else {
                        [rootViewController dismissModalViewControllerAnimated:NO];
                    }
                    
                    // Wait until the modal view controller has been dismissed so that a new one can be presented.
                    while (rootViewController.modalViewController);
                }
                
                // Modified to use iOS 5's new modal view controller functions when possible.
                // This is redundant, but I'm including it for the sake of simplicity and stability.
                if ([rootViewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
                    [rootViewController presentViewController:videoDownloadOptionsViewController animated:YES completion:nil];
                }
                else {
                    [rootViewController presentModalViewController:videoDownloadOptionsViewController animated:YES];
                }
                
                [videoDownloadOptionsViewController release];
            }
            else {
                [self deleteSavedPendingVideoDirectoryFilePath];
                
                [fileManager removeItemAtPath:path error:nil];
                
                if (!isUsingSavedVideoDirectoryFilePath) {
                    UIAlertView *errorAlert = [[UIAlertView alloc]
                                               initWithTitle:@"Error Reading Video Metadata"
                                               message:@"The app encountered an error while trying to read the video metadata. The app you were trying to download videos from may not be supported at this time."
                                               delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
                    [errorAlert show];
                    [errorAlert release];
                }
            }
        }
    }
}

- (BOOL)videoDownloadOptionsViewControllerPendingVideoIsVideoStream {
    return pendingVideoIsVideoStream;
}

- (NSDictionary *)videoDownloadOptionsViewControllerVideoFileURLsDictionary {
    return pendingVideoFileURLsDictionary;
}

- (NSArray *)videoDownloadOptionsViewControllerAudioTracks {
    if ([pendingAudioTracksArray count] > 0) {
        return pendingAudioTracksArray;
    }
    return nil;
}

- (NSArray *)videoDownloadOptionsViewControllerVideoFiles {
    return pendingVideosArray;
}

- (void)videoDownloadOptionsViewControllerDidCancel {
    [self deleteSavedPendingVideoDirectoryFilePath];
    
    [[NSFileManager defaultManager]removeItemAtPath:pendingVideoDirectoryFilePath error:nil];
    
    [self dismissRootViewControllerModalViewController];
}

- (void)videoDownloadOptionsViewControllerDidSelectOptionsWithVideoTitle:(NSString *)videoTitle audioTrackIndex:(NSInteger)audioTrackIndex videoFileIndex:(NSInteger)videoFileIndex {
    [self deleteSavedPendingVideoDirectoryFilePath];
    
    MBProgressHUD *progressHUD = [[MBProgressHUD alloc]initWithView:rootViewController.view];
    progressHUD.mode = MBProgressHUDModeIndeterminate;
    progressHUD.labelText = @"Loading";
    progressHUD.detailsLabelText = @"Moving Files...";
    [window addSubview:progressHUD];
    
    NSArray *parameters = [NSArray arrayWithObjects:videoTitle, [NSNumber numberWithInteger:audioTrackIndex], [NSNumber numberWithInteger:videoFileIndex], progressHUD, nil];
    [progressHUD showWhileExecuting:@selector(createDownloadWithParameters:) onTarget:self withObject:parameters animated:YES];
    
    [progressHUD release];
}

- (void)createDownloadWithParameters:(NSArray *)downloadParameters {
    NSString *videoTitle = [downloadParameters objectAtIndex:0];
    NSInteger audioTrackIndex = [[downloadParameters objectAtIndex:1]integerValue];
    NSInteger videoFileIndex = [[downloadParameters objectAtIndex:2]integerValue];
    MBProgressHUD *progressHUD = [downloadParameters objectAtIndex:3];
    
    NSMutableString *videoDestinationDirectoryFileName = [NSMutableString stringWithString:videoTitle];
    for (int i = 0; i < ([kFileNameReplacementStringsArray count] / 2.0); i++) {
		[videoDestinationDirectoryFileName setString:[videoDestinationDirectoryFileName stringByReplacingOccurrencesOfString:[kFileNameReplacementStringsArray objectAtIndex:(i * 2)] withString:[kFileNameReplacementStringsArray objectAtIndex:((i * 2) + 1)]]];
	}
    
    NSString *videoDestinationDirectoryFilePath = [kDownloadDestinationPathStr stringByAppendingPathComponent:videoDestinationDirectoryFileName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager moveItemAtPath:pendingVideoDirectoryFilePath toPath:videoDestinationDirectoryFilePath error:nil]) {
        if (![fileManager createDirectoryAtPath:[kTemporaryFileDownloadPathStr stringByAppendingPathComponent:videoDestinationDirectoryFileName] withIntermediateDirectories:NO attributes:nil error:nil]) {
            UIAlertView *errorAlert = [[UIAlertView alloc]
                                       initWithTitle:@"Error Creating Temporary Download Folder"
                                       message:@"The app encountered an error while trying to create the temporary download folder. Please make sure the app has read and write access to the directory at /var/mobile/Library/Universal_Video_Downloader/Downloads and try again."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [errorAlert show];
            [errorAlert release];
            
            return;
        }
    }
    else {
        if ([fileManager fileExistsAtPath:pendingVideoDirectoryFilePath]) {
            UIAlertView *errorAlert = [[UIAlertView alloc]
                                       initWithTitle:@"Error Creating Download Folder"
                                       message:@"The app encountered an error while trying to create the download folder. Please make sure the app has read and write access to the bundle directory of the app you were trying to download videos from and the directory at /var/mobile/Library/Universal_Video_Downloader/Finished_Downloads and try again."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [errorAlert show];
            [errorAlert release];
        }
        else {
            UIAlertView *errorAlert = [[UIAlertView alloc]
                                       initWithTitle:@"Error Creating Download Folder"
                                       message:@"The app encountered an error while trying to create the download folder. Please make sure the app has read and write access to the bundle directory of the app you were trying to download videos from and try again."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [errorAlert show];
            [errorAlert release];
        }
        
        return;
    }
    
    NSString *videoMetadataDictionaryFilePath = [videoDestinationDirectoryFilePath stringByAppendingPathComponent:kMetadataFileNameStr];
    NSMutableDictionary *videoMetadataDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:videoMetadataDictionaryFilePath];
    
    NSMutableDictionary *fileURLsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:nil];
    
    if (pendingVideoIsVideoStream) {
        // The reference URL replacement system here can be improved, possibly in a future version of the app.
        
        NSString *indexFilePath = [videoDestinationDirectoryFilePath stringByAppendingPathComponent:[videoMetadataDictionary objectForKey:kIndexFileNameKey]];
        NSMutableString *indexFile = [NSMutableString stringWithContentsOfFile:indexFilePath encoding:NSUTF8StringEncoding error:nil];
        
        NSArray *audioTracksArray = [NSArray arrayWithArray:[videoMetadataDictionary objectForKey:kAudioTracksKey]];
        if (audioTracksArray) {
            if ([audioTracksArray count] > 0) {
                NSDictionary *selectedAudioTrack = [audioTracksArray objectAtIndex:audioTrackIndex];
                
                NSDictionary *audioFileURLsDictionary = [NSDictionary dictionaryWithDictionary:[selectedAudioTrack objectForKey:kAudioTrackFileURLsDictionaryKey]];
                [fileURLsDictionary addEntriesFromDictionary:audioFileURLsDictionary];
                [videoMetadataDictionary removeObjectForKey:kAudioTracksKey];
                
                NSString *selectedAudioTrackReferenceFileName = [selectedAudioTrack objectForKey:kAudioTrackReferenceFileNameKey];
                if (selectedAudioTrackReferenceFileName) {
                    for (int i = 0; i < [audioTracksArray count]; i++) {
                        NSString *audioTrackReferenceFileName = [[audioTracksArray objectAtIndex:i]objectForKey:kAudioTrackReferenceFileNameKey];
                        if (audioTrackReferenceFileName) {
                            if (![audioTrackReferenceFileName isEqualToString:selectedAudioTrackReferenceFileName]) {
                                // Perhaps any unnecessary encryption keys can be deleted in the same fashion in a future version of the app. For now, I haven't included this functionality because different reference files may share an encryption key, and therefore deleting that key (thinking that it is unncessary) would render the selected video unplayable.
                                // The only way this should be able to cause problems is if these seemingly-unnecessary reference files are needed by the selected reference file, which is highly unlikely.
                                [fileManager removeItemAtPath:[videoDestinationDirectoryFilePath stringByAppendingPathComponent:audioTrackReferenceFileName] error:nil];
                                
                                // This can be improved upon in future versions of the app to make it safer.
                                [indexFile setString:[indexFile stringByReplacingOccurrencesOfString:audioTrackReferenceFileName withString:selectedAudioTrackReferenceFileName]];
                            }
                        }
                    }
                }
            }
        }
        
        NSArray *videos = [NSArray arrayWithArray:[videoMetadataDictionary objectForKey:kVideosKey]];
        NSDictionary *selectedVideo = [videos objectAtIndex:videoFileIndex];
        
        NSDictionary *videoFileURLsDictionary = [NSDictionary dictionaryWithDictionary:[selectedVideo objectForKey:kVideoFileURLsDictionaryKey]];
        [fileURLsDictionary addEntriesFromDictionary:videoFileURLsDictionary];
        [videoMetadataDictionary removeObjectForKey:kVideosKey];
        
        NSString *selectedVideoReferenceFileName = [selectedVideo objectForKey:kVideoReferenceFileNameKey];
        if (selectedVideoReferenceFileName) {
            for (int i = 0; i < [videos count]; i++) {
                NSString *videoReferenceFileName = [[videos objectAtIndex:i]objectForKey:kVideoReferenceFileNameKey];
                if (videoReferenceFileName) {
                    if (![videoReferenceFileName isEqualToString:selectedVideoReferenceFileName]) {
                        // Perhaps any unnecessary encryption keys can be deleted in the same fashion in a future version of the app. For now, I haven't included this functionality because different reference files may share an encryption key, and therefore deleting that key (thinking that it is unncessary) would render the selected video unplayable.
                        // The only way this should be able to cause problems is if these seemingly-unnecessary reference files are needed by the selected reference file, which is highly unlikely.
                        [fileManager removeItemAtPath:[videoDestinationDirectoryFilePath stringByAppendingPathComponent:videoReferenceFileName] error:nil];
                        
                        // This can be improved upon in future versions of the app to make it safer.
                        [indexFile setString:[indexFile stringByReplacingOccurrencesOfString:videoReferenceFileName withString:selectedVideoReferenceFileName]];
                    }
                }
            }
        }
        
        [indexFile writeToFile:indexFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    else {
        NSDictionary *videoFileURLsDictionary = [NSDictionary dictionaryWithDictionary:[videoMetadataDictionary objectForKey:kVideoFileURLsDictionaryKey]];
        [fileURLsDictionary addEntriesFromDictionary:videoFileURLsDictionary];
        [videoMetadataDictionary removeObjectForKey:kVideoFileURLsDictionaryKey];
    }
    
    NSMutableDictionary *finalFileURLsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:nil];
    
    unsigned long long localBytesCopied = 0;
    
    progressHUD.detailsLabelText = @"Copying Files...";
    
    NSInteger fileURLsCount = [[fileURLsDictionary allKeys]count];
    for (int i = 0; i < fileURLsCount; i++) {
        NSString *urlString = [[fileURLsDictionary allKeys]objectAtIndex:i];
        NSString *fileName = [fileURLsDictionary objectForKey:urlString];
        
        NSURL *url = [NSURL URLWithString:urlString];
        
        if ([url isFileURL]) {
            NSString *destinationPathString = [videoDestinationDirectoryFilePath stringByAppendingPathComponent:fileName];
            
            NSDictionary *attributesDictionary = [fileManager attributesOfItemAtPath:[url path] error:nil];
            if (attributesDictionary) {
                localBytesCopied += [attributesDictionary fileSize];
            }
            
            NSURL *destinationPathURL = [NSURL fileURLWithPath:destinationPathString];
            [fileManager copyItemAtURL:url toURL:destinationPathURL error:nil];
        }
        else {
            [finalFileURLsDictionary setObject:fileName forKey:urlString];
        }
    }
    
    [fileURLsDictionary removeAllObjects];
    fileURLsDictionary = nil;
    
    if ([[finalFileURLsDictionary allKeys]count] > 0) {
        [videoMetadataDictionary setValuesForKeysWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                 [NSNumber numberWithDouble:CFAbsoluteTimeGetCurrent()], kCreationTimeKey,
                                                                 [NSNumber numberWithUnsignedInteger:kDownloadStateDownloading], kDownloadStateKey,
                                                                 videoTitle, kVideoTitleKey,
                                                                 finalFileURLsDictionary, kFileURLsDictionaryKey,
                                                                 [NSNumber numberWithUnsignedLongLong:localBytesCopied], kLocalBytesCopiedKey,
                                                                 nil]];
        [videoMetadataDictionary writeToFile:videoMetadataDictionaryFilePath atomically:YES];
        
        [self updateDownloads];
    }
    else {
        [videoMetadataDictionary setValuesForKeysWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                 videoTitle, kVideoTitleKey,
                                                                 [NSNumber numberWithDouble:0], kCurrentPlaybackTimeKey,
                                                                 [NSNumber numberWithUnsignedLongLong:localBytesCopied], kSizeInBytesKey,
                                                                 nil]];
        [videoMetadataDictionary writeToFile:videoMetadataDictionaryFilePath atomically:YES];
        
        if (![fileManager removeItemAtPath:[kTemporaryFileDownloadPathStr stringByAppendingPathComponent:videoDestinationDirectoryFileName] error:nil]) {
            UIAlertView *errorAlert = [[UIAlertView alloc]
                                       initWithTitle:@"Error Removing Temporary Download Folder"
                                       message:@"The app encountered an error while trying to remove the temporary download folder. Please make sure the app has read and write access to the directory at /var/mobile/Library/Universal_Video_Downloader/Downloads and try again."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [errorAlert show];
            [errorAlert release];
        }
        
        if (![fileManager moveItemAtPath:videoDestinationDirectoryFilePath toPath:[kVideoFolderDestinationPath stringByAppendingPathComponent:videoDestinationDirectoryFileName] error:nil]) {
            UIAlertView *errorAlert = [[UIAlertView alloc]
                                       initWithTitle:@"Error Moving Video Folder"
                                       message:@"The app encountered an error while trying to move the video folder. Please make sure the app has read and write access to the directories at /var/mobile/Library/Universal_Video_Downloader/Finished_Downloads and /var/mobile/Media/Universal_Video_Downloader and try again."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [errorAlert show];
            [errorAlert release];
        }
        
        [[(VideosViewController *)[[[rootViewController.viewControllers objectAtIndex:0]viewControllers]objectAtIndex:0]theTableView]reloadData];
    }
    
    [pendingVideoDirectoryFilePath setString:kNullStr];
    [pendingAudioTracksArray removeAllObjects];
    [pendingVideosArray removeAllObjects];
    [pendingVideoFileURLsDictionary removeAllObjects];
    
    [self performSelectorOnMainThread:@selector(dismissRootViewControllerModalViewController) withObject:nil waitUntilDone:YES];
}

- (void)dismissRootViewControllerModalViewController {
    // Modified to use iOS 5's new modal view controller functions when possible.
    if ([rootViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [rootViewController dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [rootViewController dismissModalViewControllerAnimated:YES];
    }
}

- (void)updateDownloads {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSMutableArray *creationTimesArray = [NSMutableArray arrayWithObjects:nil];
    
    for (NSString *file in [fileManager contentsOfDirectoryAtPath:kDownloadDestinationPathStr error:nil]) {
        NSString *filePath = [kDownloadDestinationPathStr stringByAppendingPathComponent:file];
        NSDictionary *metadataDictionary = [NSDictionary dictionaryWithContentsOfFile:[filePath stringByAppendingPathComponent:kMetadataFileNameStr]];
        
        if (metadataDictionary) {
            NSNumber *creationTime = [metadataDictionary objectForKey:kCreationTimeKey];
            if (creationTime) {
                [creationTimesArray addObject:creationTime];
            }
        }
    }
    
    [creationTimesArray sortUsingComparator:^(NSNumber *firstObject, NSNumber *secondObject) {
        return [[NSString stringWithFormat:kStringFormatSpecifierStr, firstObject] compare:[NSString stringWithFormat:kStringFormatSpecifierStr, secondObject] options:NSNumericSearch];
    }];
    
    NSMutableArray *downloadStatesArray = [NSMutableArray arrayWithObjects:nil];
    NSMutableArray *downloadsSortedByCreationTimesArray = [NSMutableArray arrayWithObjects:nil];
    
    for (int i = 0; i < [creationTimesArray count]; i++) {
        NSNumber *currentCreationTime = [creationTimesArray objectAtIndex:i];
        
        for (NSString *file in [fileManager contentsOfDirectoryAtPath:kDownloadDestinationPathStr error:nil]) {
            NSString *filePath = [kDownloadDestinationPathStr stringByAppendingPathComponent:file];
            NSDictionary *metadataDictionary = [NSDictionary dictionaryWithContentsOfFile:[filePath stringByAppendingPathComponent:kMetadataFileNameStr]];
            
            if (metadataDictionary) {
                NSNumber *creationTime = [metadataDictionary objectForKey:kCreationTimeKey];
                if (creationTime) {
                    if ([creationTime isEqual:currentCreationTime]) {
                        NSNumber *downloadState = [metadataDictionary objectForKey:kDownloadStateKey];
                        NSString *videoTitle = [metadataDictionary objectForKey:kVideoTitleKey];
                        if ((downloadState) && (videoTitle)) {
                            if ([videoTitle length] > 0) {
                                [downloadsSortedByCreationTimesArray addObject:[NSArray arrayWithObjects:downloadState, creationTime, videoTitle, file, nil]];
                                [downloadStatesArray addObject:downloadState];
                            }
                        }
                        
                        break;
                    }
                }
            }
        }
    }
    
    [downloadStatesArray sortUsingComparator:^(NSNumber *firstObject, NSNumber *secondObject) {
        return [[NSString stringWithFormat:kStringFormatSpecifierStr, firstObject] compare:[NSString stringWithFormat:kStringFormatSpecifierStr, secondObject] options:NSNumericSearch];
    }];
    
    NSMutableArray *downloads = [NSMutableArray arrayWithObjects:nil];
    
    for (int i = 0; i < [downloadStatesArray count]; i++) {
        NSNumber *currentDownloadState = [downloadStatesArray objectAtIndex:i];
        
        for (int j = 0; j < [downloadsSortedByCreationTimesArray count]; j++) {
            NSArray *downloadArray = [downloadsSortedByCreationTimesArray objectAtIndex:j];
            if ([[downloadArray objectAtIndex:DOWNLOAD_STATE_INDEX]isEqual:currentDownloadState]) {
                [downloads addObject:downloadArray];
                [downloadsSortedByCreationTimesArray removeObjectAtIndex:j];
                break;
            }
        }
    }
    
    NSInteger temporaryActiveDownloadCount = 0;
    
    BOOL downloadsAreCorrupt = NO;
    for (int i = 0; i < [downloads count]; i++) {
        NSArray *downloadArray = [downloads objectAtIndex:i];
        kDownloadState downloadState = [[downloadArray objectAtIndex:DOWNLOAD_STATE_INDEX]unsignedIntegerValue];
        
        if (i == 0) {
            if (currentDownload) {
                temporaryActiveDownloadCount += 1;
            }
            else {
                if ((downloadState == kDownloadStateDownloading) || (downloadState == kDownloadStateWaiting)) {
                    NSString *downloadDirectoryFileName = [downloadArray objectAtIndex:DOWNLOAD_DIRECTORY_FILE_NAME_INDEX];
                    if (downloadDirectoryFileName) {
                        if ([downloadDirectoryFileName length] > 0) {
                            NSString *metadataDictionaryFilePath = [[kDownloadDestinationPathStr stringByAppendingPathComponent:downloadDirectoryFileName]stringByAppendingPathComponent:kMetadataFileNameStr];
                            NSMutableDictionary *metadataDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:metadataDictionaryFilePath];
                            
                            if (metadataDictionary) {
                                NSDictionary *fileURLsDictionary = [metadataDictionary objectForKey:kFileURLsDictionaryKey];
                                if (fileURLsDictionary) {
                                    NSString *videoTitle = [downloadArray objectAtIndex:VIDEO_TITLE_INDEX];
                                    if (videoTitle) {
                                        if ([videoTitle length] > 0) {
                                            if (downloadState == kDownloadStateWaiting) {
                                                [metadataDictionary setValuesForKeysWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                    [NSNumber numberWithUnsignedInteger:kDownloadStateDownloading], kDownloadStateKey,
                                                                                                    [NSNumber numberWithDouble:CFAbsoluteTimeGetCurrent()], kCreationTimeKey,
                                                                                                    nil]];
                                                [metadataDictionary writeToFile:metadataDictionaryFilePath atomically:YES];
                                                
                                                if (!downloadsAreCorrupt) {
                                                    downloadsAreCorrupt = YES;
                                                }
                                            }
                                            
                                            ASINetworkQueue *downloadQueue = [[ASINetworkQueue alloc]init];
                                            [downloadQueue setDelegate:self];
                                            [downloadQueue setMaxConcurrentOperationCount:MAXIMUM_CONCURRENT_DOWNLOADS];
                                            [downloadQueue setRequestDidStartSelector:@selector(downloadQueueRequestDidStart:)];
                                            [downloadQueue setRequestDidFailSelector:@selector(downloadQueueRequestDidFail:)];
                                            [downloadQueue setQueueDidFinishSelector:@selector(downloadQueueDidFinish:)];
                                            [downloadQueue setShouldCancelAllRequestsOnFailure:YES];
                                            [downloadQueue setShowAccurateProgress:YES];
                                            
                                            unsigned long long bytesPermanentlyDownloadedSoFar = [[metadataDictionary objectForKey:kLocalBytesCopiedKey]unsignedLongLongValue];
                                            
                                            NSString *downloadDirectoryFilePath = [kDownloadDestinationPathStr stringByAppendingPathComponent:downloadDirectoryFileName];
                                            
                                            for (NSString *url in [fileURLsDictionary allKeys]) {
                                                NSString *fileName = [fileURLsDictionary objectForKey:url];
                                                NSString *downloadDestinationPath = [downloadDirectoryFilePath stringByAppendingPathComponent:fileName];
                                                
                                                if ([fileManager fileExistsAtPath:downloadDestinationPath]) {
                                                    NSDictionary *attributesDictionary = [fileManager attributesOfItemAtPath:downloadDestinationPath error:nil];
                                                    if (attributesDictionary) {
                                                        bytesPermanentlyDownloadedSoFar += [attributesDictionary fileSize];
                                                    }
                                                }
                                                else {
                                                    // Potential fix for the occasional, mysterious crashing problem (as much as I hate using -autorelease).
                                                    ASIHTTPRequest *download = [[[ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]]retain]autorelease];
                                                    [download setAllowResumeForFileDownloads:YES];
                                                    [download setDelegate:self];
                                                    [download setDownloadDestinationPath:downloadDestinationPath];
                                                    [download setNumberOfTimesToRetryOnTimeout:DOWNLOAD_ATTEMPTS];
                                                    [download setShouldContinueWhenAppEntersBackground:YES];
                                                    [download setTemporaryFileDownloadPath:[[kTemporaryFileDownloadPathStr stringByAppendingPathComponent:downloadDirectoryFileName]stringByAppendingPathComponent:fileName]];
                                                    [download setTimeOutSeconds:DOWNLOAD_TIMEOUT_IN_SECONDS];
                                                    
                                                    [downloadQueue addOperation:download];
                                                }
                                            }
                                            
                                            [downloadQueue setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:videoTitle, kVideoTitleKey, [NSNumber numberWithBool:YES], kCalculatingTotalSizeKey, [NSNumber numberWithUnsignedLongLong:bytesPermanentlyDownloadedSoFar], kBytesPermanentlyDownloadedSoFarKey, [NSNumber numberWithBool:NO], kDidFailKey, nil]];
                                            
                                            currentDownload = downloadQueue;
                                            
                                            temporaryActiveDownloadCount += 1;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        else if (downloadState == kDownloadStateDownloading) {
            NSString *metadataDictionaryFilePath = [[kDownloadDestinationPathStr stringByAppendingPathComponent:[downloadArray objectAtIndex:DOWNLOAD_DIRECTORY_FILE_NAME_INDEX]]stringByAppendingPathComponent:kMetadataFileNameStr];
            NSMutableDictionary *metadataDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:metadataDictionaryFilePath];
            if (metadataDictionary) {
                [metadataDictionary setObject:[NSNumber numberWithUnsignedInteger:kDownloadStateWaiting] forKey:kDownloadStateKey];
                [metadataDictionary writeToFile:metadataDictionaryFilePath atomically:YES];
            }
            
            if (!downloadsAreCorrupt) {
                downloadsAreCorrupt = YES;
            }
        }
        else if (downloadState == kDownloadStateWaiting) {
            temporaryActiveDownloadCount += 1;
        }
    }
    
    if (downloadsAreCorrupt) {
        [self updateDownloads];
        return;
    }
    
    [downloadsArray setArray:downloads];
    
    // This MUST come after the above statement because -downloadQueueDidFinish: uses the first object of the downloadsArray variable.
    if (currentDownload) {
        if (currentDownload.isSuspended) {
            [currentDownload go];
        }
    }
    
    activeDownloadCount = temporaryActiveDownloadCount;
    
    // Because of problems resulting from executing the following commands in a thread other than the main thread (which MBProgressHUD does), they must be run in the main thread.
    
    // This is done to update the badge instantly rather than having it queued by NSThread. The latter would require me to cancel it specifically by specifying the active download count that was passed to it, which I don't want to have to do. This seems to help prevent the badge from "sticking," which seems to happen more often when I group this code with the code that is queued by NSThread.
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_async(mainQueue, ^{
        NSString *badgeValue = nil;
        if (temporaryActiveDownloadCount > 0) {
            badgeValue = [NSString stringWithFormat:kIntegerFormatSpecifierStr, temporaryActiveDownloadCount];
        }
        [[[rootViewController.viewControllers objectAtIndex:1]tabBarItem]setBadgeValue:badgeValue];
        
        [[UIApplication sharedApplication]setApplicationIconBadgeNumber:temporaryActiveDownloadCount];
    });
    
    // The commands at the following selector don't change, so it's acceptable to have them queued by NSThread like so:
    [self performSelectorOnMainThread:@selector(updateDownloadElements) withObject:nil waitUntilDone:YES];
}

- (void)updateDownloadElements {
    if ((activeDownloadCount > 0) && (viewIsVisible)) {
        if ((!downloadUpdateTimer) || ((downloadUpdateTimer) && (![downloadUpdateTimer isValid]))) {
            downloadUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:DOWNLOAD_TIMER_UPDATE_INTERVAL_IN_SECONDS target:self selector:@selector(updateCurrentDownload) userInfo:nil repeats:YES];
        }
    }
    else if (downloadUpdateTimer) {
        if ([downloadUpdateTimer isValid]) {
            [downloadUpdateTimer invalidate];
        }
        downloadUpdateTimer = nil;
    }
    
    if (![downloadsArray containsObject:pendingDownloadArray]) {
        if (optionsActionSheet) {
            [optionsActionSheet dismissWithClickedButtonIndex:optionsActionSheet.cancelButtonIndex animated:YES];
            [optionsActionSheet release];
            optionsActionSheet = nil;
        }
    }
    
    [theTableView reloadData];
}

- (void)updateCurrentDownload {
    [theTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)downloadQueueRequestDidStart:(ASIHTTPRequest *)request {
    if ([[currentDownload.userInfo objectForKey:kCalculatingTotalSizeKey]boolValue]) {
        NSMutableDictionary *userInfoDictionary = [NSMutableDictionary dictionaryWithDictionary:currentDownload.userInfo];
        [userInfoDictionary setObject:[NSNumber numberWithBool:NO] forKey:kCalculatingTotalSizeKey];
        currentDownload.userInfo = userInfoDictionary;
    }
}

- (void)downloadQueueRequestDidFail:(ASIHTTPRequest *)request {
    if (![[currentDownload.userInfo objectForKey:kDidFailKey]boolValue]) {
        NSMutableDictionary *userInfoDictionary = [NSMutableDictionary dictionaryWithDictionary:currentDownload.userInfo];
        [userInfoDictionary setObject:[NSNumber numberWithBool:YES] forKey:kDidFailKey];
        currentDownload.userInfo = userInfoDictionary;
    }
}

- (void)downloadQueueDidFinish:(ASINetworkQueue *)downloadQueue {
    NSArray *downloadArray = [downloadsArray objectAtIndex:0];
    NSString *downloadDirectoryFileName = [downloadArray objectAtIndex:DOWNLOAD_DIRECTORY_FILE_NAME_INDEX];
    NSString *downloadDirectoryFilePath = [kDownloadDestinationPathStr stringByAppendingPathComponent:downloadDirectoryFileName];
    NSString *metadataDictionaryFilePath = [downloadDirectoryFilePath stringByAppendingPathComponent:kMetadataFileNameStr];
    NSMutableDictionary *metadataDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:metadataDictionaryFilePath];
    
    BOOL downloadDidFail = NO;
    
    if ([[downloadQueue.userInfo objectForKey:kDidFailKey]boolValue]) {
        if (metadataDictionary) {
            [metadataDictionary setObject:[NSNumber numberWithUnsignedInteger:kDownloadStateFailed] forKey:kDownloadStateKey];
            [metadataDictionary writeToFile:metadataDictionaryFilePath atomically:YES];
        }
        
        downloadDidFail = YES;
    }
    else {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (metadataDictionary) {
            unsigned long long fileSize = [[metadataDictionary objectForKey:kLocalBytesCopiedKey]unsignedLongLongValue];
            
            NSDictionary *fileURLsDictionary = [metadataDictionary objectForKey:kFileURLsDictionaryKey];
            
            for (NSString *url in [fileURLsDictionary allKeys]) {
                NSString *fileName = [fileURLsDictionary objectForKey:url];
                NSString *downloadDestinationPath = [downloadDirectoryFilePath stringByAppendingPathComponent:fileName];
                
                NSDictionary *attributesDictionary = [fileManager attributesOfItemAtPath:downloadDestinationPath error:nil];
                if (attributesDictionary) {
                    fileSize += [attributesDictionary fileSize];
                }
            }
            
            [metadataDictionary removeObjectForKey:kCreationTimeKey];
            [metadataDictionary removeObjectForKey:kDownloadStateKey];
            [metadataDictionary removeObjectForKey:kFileURLsDictionaryKey];
            [metadataDictionary removeObjectForKey:kLocalBytesCopiedKey];
            
            [metadataDictionary setValuesForKeysWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                [NSNumber numberWithDouble:0], kCurrentPlaybackTimeKey,
                                                                [NSNumber numberWithUnsignedLongLong:fileSize], kSizeInBytesKey,
                                                                nil]];
            
            [metadataDictionary writeToFile:metadataDictionaryFilePath atomically:YES];
        }
        
        if (![fileManager removeItemAtPath:[kTemporaryFileDownloadPathStr stringByAppendingPathComponent:downloadDirectoryFileName] error:nil]) {
            UIAlertView *errorAlert = [[UIAlertView alloc]
                                       initWithTitle:@"Error Removing Temporary Download Folder"
                                       message:@"The app encountered an error while trying to remove the temporary download folder. Please make sure the app has read and write access to the directory at /var/mobile/Library/Universal_Video_Downloader/Downloads and try again."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [errorAlert show];
            [errorAlert release];
        }
        
        if (![fileManager moveItemAtPath:downloadDirectoryFilePath toPath:[kVideoFolderDestinationPath stringByAppendingPathComponent:downloadDirectoryFileName] error:nil]) {
            UIAlertView *errorAlert = [[UIAlertView alloc]
                                       initWithTitle:@"Error Moving Video Folder"
                                       message:@"The app encountered an error while trying to move the video folder. Please make sure the app has read and write access to the directories at /var/mobile/Library/Universal_Video_Downloader/Finished_Downloads and /var/mobile/Media/Universal_Video_Downloader and try again."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [errorAlert show];
            [errorAlert release];
        }
        
        [[(VideosViewController *)[[[rootViewController.viewControllers objectAtIndex:0]viewControllers]objectAtIndex:0]theTableView]reloadData];
    }
    
    currentDownload = nil;
    [self updateDownloads];
    
    if ((isRunningInBackground) && ([[NSUserDefaults standardUserDefaults]boolForKey:kDownloadAlertsKey])) {
        UILocalNotification *notification = [[UILocalNotification alloc]init];
        
        if (downloadDidFail) {
            notification.alertBody = [NSString stringWithFormat:@"\"%@\" failed to download. It has been paused so that you can resume it later.", [downloadQueue.userInfo objectForKey:kVideoTitleKey]];
        }
        else {
            notification.alertBody = [NSString stringWithFormat:@"\"%@\" has finished downloading.", [downloadQueue.userInfo objectForKey:kVideoTitleKey]];
        }
        
        notification.alertAction = @"View";
        notification.soundName = UILocalNotificationDefaultSoundName;
        
        [[UIApplication sharedApplication]presentLocalNotificationNow:notification];
        
        [notification release];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    
    isRunningInBackground = YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    
    isRunningInBackground = YES;
    
    if (backgroundTask) {
		[[UIApplication sharedApplication]endBackgroundTask:backgroundTask];
	}
	[[UIApplication sharedApplication]beginBackgroundTaskWithExpirationHandler:^{
		backgroundTask = 0;
	}];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    isRunningInBackground = NO;
    
    if (backgroundTask) {
		[[UIApplication sharedApplication]endBackgroundTask:backgroundTask];
	}
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    return [downloadsArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ROW_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = [NSString stringWithFormat:@"Cell %i", (indexPath.row + 1)];
    
    DownloadCell *cell = (DownloadCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[DownloadCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier]autorelease];
    }
    
    // Configure the cell...
    
    NSArray *downloadArray = [downloadsArray objectAtIndex:indexPath.row];
    
    cell.titleLabel.text = [downloadArray objectAtIndex:VIDEO_TITLE_INDEX];
    
    NSUInteger downloadState = [[downloadArray objectAtIndex:DOWNLOAD_STATE_INDEX]unsignedIntegerValue];
    if ((downloadState == kDownloadStateDownloading) && (![[currentDownload.userInfo objectForKey:kCalculatingTotalSizeKey]boolValue])) {
        unsigned long long bytesPermanentlyDownloadedSoFar = [[currentDownload.userInfo objectForKey:kBytesPermanentlyDownloadedSoFarKey]unsignedLongLongValue];
        unsigned long long bytesDownloadedSoFar = (bytesPermanentlyDownloadedSoFar + currentDownload.bytesDownloadedSoFar);
        unsigned long long totalBytesToDownload = (bytesPermanentlyDownloadedSoFar + currentDownload.totalBytesToDownload);
        
        if ((totalBytesToDownload <= 0) || (bytesDownloadedSoFar > totalBytesToDownload)) {
            cell.progressLabel.text = [NSString stringWithFormat:@"%@ MB of Unknown Size", [self megaBytesStringFromBytes:bytesDownloadedSoFar]];
        }
        else {
            cell.progressLabel.text = [NSString stringWithFormat:@"%@ MB of %@ MB", [self megaBytesStringFromBytes:bytesDownloadedSoFar], [self megaBytesStringFromBytes:totalBytesToDownload]];
        }
        
        if (totalBytesToDownload > 0) {
            // Casting these to doubles is acceptable here since the number of bytes usually isn't so astronomically high that it reaches the limit of the double data type.
            cell.progressView.progress = (((double)bytesDownloadedSoFar) / ((double)totalBytesToDownload));
        }
        else {
            cell.progressView.progress = 0;
        }
        
        cell.progressLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1];
        cell.progressView.hidden = NO;
    }
    else {
        if (downloadState == kDownloadStateFailed) {
            cell.progressLabel.text = @"Failed";
            cell.progressLabel.textColor = [UIColor colorWithRed:FAILED_COLOR_RED green:FAILED_COLOR_GREEN blue:FAILED_COLOR_BLUE alpha:1];
        }
        else {
            if (downloadState == kDownloadStateDownloading) {
                if (currentDownload.totalBytesToDownload > 0) {
                    // I don't add this to currentDownload.bytesDownloadedSoFar because it isn't relevant here.
                    unsigned long long bytesDownloadedSoFar = [[currentDownload.userInfo objectForKey:kBytesPermanentlyDownloadedSoFarKey]unsignedLongLongValue];
                    unsigned long long totalBytesToDownload = (bytesDownloadedSoFar + currentDownload.totalBytesToDownload);
                    cell.progressLabel.text = [NSString stringWithFormat:@"Calculating Total Size... %@ MB", [self megaBytesStringFromBytes:totalBytesToDownload]];
                }
                else {
                    cell.progressLabel.text = @"Starting Download...";
                }
            }
            else if (downloadState == kDownloadStateWaiting) {
                cell.progressLabel.text = @"Waiting...";
            }
            else {
                cell.progressLabel.text = @"Paused";
            }
            
            cell.progressLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1];
        }
        
        cell.progressView.hidden = YES;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (NSString *)megaBytesStringFromBytes:(unsigned long long)bytes {
    float megaBytes = (bytes / MB_FLOAT_SIZE);
    NSString *megaBytesString = [NSString stringWithFormat:kFloatFormatSpecifierStr, megaBytes];
    NSDecimalNumber *megaBytesDecimalNumber = [[NSDecimalNumber decimalNumberWithString:megaBytesString]decimalNumberByRoundingAccordingToBehavior:decimalNumberHandler];
    return [self stringFromDecimalNumber:megaBytesDecimalNumber];
}

- (NSString *)stringFromDecimalNumber:(NSDecimalNumber *)decimalNumber {
	NSMutableString *formattedDecimalNumber = [NSMutableString stringWithFormat:kStringFormatSpecifierStr, decimalNumber];
	if ([formattedDecimalNumber rangeOfString:kDecimalStr].length > 0) {
		if ([[[formattedDecimalNumber componentsSeparatedByString:kDecimalStr]lastObject]length] < 2) {
			[formattedDecimalNumber appendString:kTenthAppendStr];
		}
	}
	else {
		[formattedDecimalNumber appendString:kWholeNumberAppendStr];
	}
    /*
    if ([formattedDecimalNumber rangeOfString:kDecimalStr].length <= 0) {
        [formattedDecimalNumber appendString:kWholeNumberAppendStr];
    }
    */
	return [NSString stringWithString:formattedDecimalNumber];
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!optionsActionSheet) {
        NSArray *downloadArray = [downloadsArray objectAtIndex:indexPath.row];
        [pendingDownloadArray setArray:downloadArray];
        
        NSString *videoTitle = [downloadArray objectAtIndex:VIDEO_TITLE_INDEX];
        
        NSUInteger downloadState = [[downloadArray objectAtIndex:DOWNLOAD_STATE_INDEX]unsignedIntegerValue];
        if ((downloadState == kDownloadStateDownloading) || (downloadState == kDownloadStateWaiting)) {
            NSString *actionSheetTitle = nil;
            if (downloadState == kDownloadStateDownloading) {
                actionSheetTitle = [NSString stringWithFormat:@"\"%@\" (Downloading)", videoTitle];
            }
            else {
                actionSheetTitle = [NSString stringWithFormat:@"\"%@\" (Waiting)", videoTitle];
            }
            
            optionsActionSheet = [[UIActionSheet alloc]
                                  initWithTitle:actionSheetTitle
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:@"Delete"
                                  otherButtonTitles:@"Pause", nil];
            optionsActionSheet.tag = 0;
        }
        else if (downloadState == kDownloadStatePaused) {
            optionsActionSheet = [[UIActionSheet alloc]
                                  initWithTitle:[NSString stringWithFormat:@"\"%@\" (Paused)", videoTitle]
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:@"Delete"
                                  otherButtonTitles:@"Resume Downloading", nil];
            optionsActionSheet.tag = 1;
        }
        else {
            optionsActionSheet = [[UIActionSheet alloc]
                                  initWithTitle:[NSString stringWithFormat:@"\"%@\" (Failed)", videoTitle]
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:@"Delete"
                                  otherButtonTitles:@"Resume Downloading", nil];
            optionsActionSheet.tag = 1;
        }
        
        optionsActionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [optionsActionSheet showInView:rootViewController.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        UIView *view = rootViewController.view;
        
        MBProgressHUD *progressHUD = [[MBProgressHUD alloc]initWithView:view];
        progressHUD.mode = MBProgressHUDModeIndeterminate;
        [view addSubview:progressHUD];
        
        if (buttonIndex == 0) {
            progressHUD.labelText = @"Deleting Download...";
            [progressHUD showWhileExecuting:@selector(deleteDownload) onTarget:self withObject:nil animated:YES];
        }
        else {
            BOOL shouldPauseDownload = (actionSheet.tag == 0);
            if (shouldPauseDownload) {
                progressHUD.labelText = @"Pausing Download...";
            }
            else {
                progressHUD.labelText = @"Resuming Download...";
            }
            [progressHUD showWhileExecuting:@selector(setDownloadPaused:) onTarget:self withObject:[NSNumber numberWithBool:shouldPauseDownload] animated:YES];
        }
        
        [progressHUD release];
    }
    
    if (optionsActionSheet) {
        [optionsActionSheet release];
        optionsActionSheet = nil;
    }
}

- (void)deleteDownload {
    if ([pendingDownloadArray isEqualToArray:[downloadsArray objectAtIndex:0]]) {
        currentDownload.delegate = nil;
        [currentDownload cancelAllOperations];
        currentDownload = nil;
    }
    
    NSString *downloadDirectoryFileName = [pendingDownloadArray objectAtIndex:DOWNLOAD_DIRECTORY_FILE_NAME_INDEX];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[kTemporaryFileDownloadPathStr stringByAppendingPathComponent:downloadDirectoryFileName] error:nil];
    [fileManager removeItemAtPath:[kDownloadDestinationPathStr stringByAppendingPathComponent:downloadDirectoryFileName] error:nil];
    
    [self updateDownloads];
    
    if (optionsActionSheet) {
        [optionsActionSheet release];
        optionsActionSheet = nil;
    }
}

- (void)setDownloadPaused:(NSNumber *)paused {
    NSString *metadataDictionaryFilePath = [[kDownloadDestinationPathStr stringByAppendingPathComponent:[pendingDownloadArray objectAtIndex:DOWNLOAD_DIRECTORY_FILE_NAME_INDEX]]stringByAppendingPathComponent:kMetadataFileNameStr];
    NSMutableDictionary *metadataDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:metadataDictionaryFilePath];
    if (metadataDictionary) {
        if ([paused boolValue]) {
            if ([pendingDownloadArray isEqualToArray:[downloadsArray objectAtIndex:0]]) {
                currentDownload.delegate = nil;
                [currentDownload cancelAllOperations];
                currentDownload = nil;
            }
            
            [metadataDictionary setObject:[NSNumber numberWithUnsignedInteger:kDownloadStatePaused] forKey:kDownloadStateKey];
        }
        else {
            [metadataDictionary setValuesForKeysWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                [NSNumber numberWithUnsignedInteger:kDownloadStateDownloading], kDownloadStateKey,
                                                                [NSNumber numberWithDouble:CFAbsoluteTimeGetCurrent()], kCreationTimeKey,
                                                                nil]];
        }
        
        [metadataDictionary writeToFile:metadataDictionaryFilePath atomically:YES];
        
        [self updateDownloads];
    }
    
    if (optionsActionSheet) {
        [optionsActionSheet release];
        optionsActionSheet = nil;
    }
}

#pragma mark Memory management

- (void)dealloc {
    [window release];
    [rootViewController release];
    
    [theTableView release];
    
    [downloadsArray release];
    [pendingDownloadArray release];
    
    [pendingVideoDirectoryFilePath release];
    [pendingAudioTracksArray release];
    [pendingVideosArray release];
    [pendingVideoFileURLsDictionary release];
    
    [decimalNumberHandler release];
    
    [httpServer release];
    [super dealloc];
}

@end
