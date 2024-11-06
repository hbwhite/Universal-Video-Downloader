//
//  UVDVideoProcessor.m
//  Universal Video Downloader
//
//  Created by Harrison White on 7/25/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import "UVDVideoProcessor.h"
#import "UVDHTTPRequest.h"

#define DOWNLOAD_TIMEOUT_IN_SECONDS                             30

#define kFileNameReplacementStringsArray                        [NSArray arrayWithObjects:@"/", @"-", nil]

static NSString *kMetadataFileNameStr                           = @"Metadata.plist";

static NSString *kIsVideoStreamKey                              = @"Video Stream";
static NSString *kVideoFileNameKey                              = @"Video File Name";
static NSString *kIndexFileNameKey                              = @"Index File Name";
static NSString *kAudioTracksKey                                = @"Audio Tracks";
static NSString *kVideosKey                                     = @"Videos";
static NSString *kAudioTrackReferenceFileURLDictionaryKey       = @"Audio Track Reference File URL Dictionary";
static NSString *kVideoReferenceFileURLDictionaryKey            = @"Video Reference File URL Dictionary";
static NSString *kAudioTrackReferenceFileNameKey                = @"Audio Track Reference File Name";
static NSString *kVideoReferenceFileNameKey                     = @"Video Reference File Name";
static NSString *kAudioTrackFileURLsDictionaryKey               = @"Audio Track File URLs Dictionary";
static NSString *kVideoFileURLsDictionaryKey                    = @"Video File URLs Dictionary";
static NSString *kAudioTrackLanguageTitleKey                    = @"Audio Track Language Title";
static NSString *kIsDefaultAudioTrackKey                        = @"Default Audio Track";
static NSString *kBandwidthKey                                  = @"Bandwidth";

// To improve performance, invalid characters in this title will not be replaced using the kFileNameReplacementStringsArray variable, so it should not contain any invalid characters specified in that variable.
static NSString *kDefaultFileNameStr                            = @"Untitled";

static NSString *kLowercaseHTTPURLSchemeStr                     = @"http";
static NSString *kLowercaseHTTPSURLSchemeStr                    = @"https";

static NSString *kLowercaseFileURLSchemeStr                     = @"file";

static NSString *kVideoStreamPrefixStr                          = @"#EXTM3U";

static NSString *kDefaultVideoFilePathExtensionStr              = @"mp4";
static NSString *kLowercaseVideoStreamIndexFilePathExtensionStr = @"m3u8";

static NSString *kCopyFormatStr                                 = @"_%i";
static NSString *kNullStr                                       = @"";

static NSString *kPreferencesFilePathStr                        = @"/private/var/mobile/Library/Preferences/com.harrisonapps.Universal-Video-Downloader.plist";

static NSString *kDefaultAudioTrackOnlyKey                      = @"Default Audio Track Only";
static NSString *kFullQualityVideoOnlyKey                       = @"Full Quality Video Only";

static NSString *kURLPrefixStr                                  = @"universalvideodownloader:";

@interface UVDVideoProcessor ()

@property (readwrite) BOOL defaultAudioTrackOnly;
@property (readwrite) BOOL fullQualityVideoOnly;
@property (nonatomic, assign) NSString *rootDownloadFilePath;

@property (nonatomic, assign) NSMutableString *indexFile;
@property (nonatomic, assign) NSMutableArray *audioTracksArray;
@property (nonatomic, assign) NSMutableArray *videosArray;
@property (nonatomic, assign) NSMutableArray *savedFileNamesArray;
@property (nonatomic, assign) NSMutableDictionary *savedFileURLsDictionary;

// Internal Functions
- (void)showConnectionFailedAlert;
- (void)didIdentifyVideoFileWithFinalURL:(NSURL *)finalURL;
- (void)didIdentifyVideoStreamWithFinalURL:(NSURL *)finalURL indexFileContents:(NSString *)indexFileContents;
- (void)setUpRootDownloadFilePath;
- (void)cleanUp;
- (void)didFinish;
- (NSURL *)rootURLFromURL:(NSURL *)url;
- (NSURL *)directoryURLFromURL:(NSURL *)url;
- (NSString *)downloadFileNameForFileWithName:(NSString *)fileName;
- (void)saveVideoFileWithURL:(NSURL *)videoFileURL;
- (void)saveVideoStreamWithIndexFileURL:(NSURL *)indexFileURL contents:(NSString *)indexFileContents;
- (void)processIndexFileAtURL:(NSURL *)url;
- (NSDictionary *)fileURLsDictionaryFromReferenceFile:(NSMutableString *)referenceFile atURL:(NSURL *)url;

@end

@implementation UVDVideoProcessor

@synthesize delegate = _delegate;

@synthesize defaultAudioTrackOnly;
@synthesize fullQualityVideoOnly;
@synthesize rootDownloadFilePath;

@synthesize indexFile;
@synthesize audioTracksArray;
@synthesize videosArray;
@synthesize savedFileNamesArray;
@synthesize savedFileURLsDictionary;

#pragma mark External Functions

- (id)initWithDelegate:(id <UVDVideoProcessorDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        
        defaultAudioTrackOnly = NO;
        if ([[NSFileManager defaultManager]fileExistsAtPath:kPreferencesFilePathStr]) {
            NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPreferencesFilePathStr];
            if (preferences) {
                if ([preferences objectForKey:kDefaultAudioTrackOnlyKey]) {
                    if ([[preferences objectForKey:kDefaultAudioTrackOnlyKey]boolValue]) {
                        defaultAudioTrackOnly = YES;
                    }
                }
            }
        }
        
        fullQualityVideoOnly = NO;
        if ([[NSFileManager defaultManager]fileExistsAtPath:kPreferencesFilePathStr]) {
            NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPreferencesFilePathStr];
            if (preferences) {
                if ([preferences objectForKey:kFullQualityVideoOnlyKey]) {
                    if ([[preferences objectForKey:kFullQualityVideoOnlyKey]boolValue]) {
                        fullQualityVideoOnly = YES;
                    }
                }
            }
        }
    }
    return self;
}

- (void)saveVideoAtURL:(NSURL *)url {
    NSString *urlScheme = [[url scheme]lowercaseString];
    if (([urlScheme isEqualToString:kLowercaseHTTPURLSchemeStr]) || ([urlScheme isEqualToString:kLowercaseHTTPSURLSchemeStr])) {
        // I have to use the __block specifier in order to write to variables like these in blocks.
        __block BOOL didIdentifyVideoStream = NO;
        
        NSMutableData *receivedData = [[NSMutableData alloc]init];
        
        UVDHTTPRequest *request = [UVDHTTPRequest requestWithURL:url];
        
        // If this is set to YES, the received data from some services can be corrupt.
        request.allowCompressedResponse = NO;
        
        request.timeOutSeconds = DOWNLOAD_TIMEOUT_IN_SECONDS;
        
        [request setStartedBlock:^{
            [receivedData setLength:0];
        }];
        [request setDataReceivedBlock:^(NSData *data) {
            [receivedData appendData:data];
            
            if (!didIdentifyVideoStream) {
                NSString *receivedDataString = [[NSString alloc]initWithData:receivedData encoding:NSASCIIStringEncoding];
                
                NSInteger searchStringLength = [kVideoStreamPrefixStr length];
                if ([receivedDataString length] >= searchStringLength) {
                    didIdentifyVideoStream = [[[receivedDataString substringToIndex:searchStringLength]uppercaseString]isEqualToString:kVideoStreamPrefixStr];
                    
                    if (!didIdentifyVideoStream) {
                        [request clearDelegatesAndCancel];
                        
                        [receivedData release];
                        
                        [self didIdentifyVideoFileWithFinalURL:request.url];
                    }
                }
                
                [receivedDataString release];
            }
        }];
        [request setFailedBlock:^{
            [receivedData release];
            
            [self showConnectionFailedAlert];
            
            [self didFinish];
        }];
        [request setCompletionBlock:^{
            if (didIdentifyVideoStream) {
                NSString *receivedDataString = [[NSString alloc]initWithData:receivedData encoding:NSASCIIStringEncoding];
                
                [self didIdentifyVideoStreamWithFinalURL:request.url indexFileContents:[NSString stringWithString:receivedDataString]];
                
                [receivedDataString release];
            }
            else if ([receivedData length] <= 0) {
                // This will execute if it was pointed to a blank file.
                
                UIAlertView *connectionFailedAlert = [[UIAlertView alloc]
                                                      initWithTitle:@"Error Reading Video Data"
                                                      message:@"The app encountered an error while trying to read the video data. Please check your Internet connection status and try again. You can also try playing the video again. If these solutions do not fix the problem, the app you are trying to download videos from may not be supported at this time."
                                                      delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [connectionFailedAlert show];
                [connectionFailedAlert release];
                
                [self didFinish];
            }
            
            [receivedData release];
        }];
        
        [request startSynchronous];
    }
    else if ([urlScheme isEqualToString:kLowercaseFileURLSchemeStr]) {
        [self didIdentifyVideoFileWithFinalURL:url];
    }
    else {
        // It should be safe to load the entire file into RAM since I don't know of any apps that use custom URL schemes to host video files (excluding video index files and video reference files) locally. If they do, it will most likely crash the app, but this is acceptable because in order to have a custom URL scheme, an app would have to run its own local server, which would most likely go down when the active app changes to the Universal Video Downloader app. Even if the server didn't go down, the instance of UVDHTTPRequest that the Universal Video Downloader app uses may not even be able to download the video file because of its URL scheme (which is, in fact, the whole reason this block of code exists). In short, even if the app didn't crash from loading a video file into RAM, it probably wouldn't be able to download the video anyway.
        // I am using an instance of NSURLConnection so that it will handle any possible redirects and return the data at the final URL.
        
        NSURLResponse *response = nil;
        NSError *error = nil;
        
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if ((error) || (!receivedData)) {
            [self showConnectionFailedAlert];
            
            [self didFinish];
        }
        else {
            NSURL *finalURL = [response URL];
            
            NSString *receivedDataString = [[NSString alloc]initWithData:receivedData encoding:NSASCIIStringEncoding];
            
            NSInteger searchStringLength = [kVideoStreamPrefixStr length];
            if ([receivedDataString length] >= searchStringLength) {
                if ([[[receivedDataString substringToIndex:searchStringLength]uppercaseString]isEqualToString:kVideoStreamPrefixStr]) {
                    [self didIdentifyVideoStreamWithFinalURL:finalURL indexFileContents:[NSString stringWithString:receivedDataString]];
                }
                else {
                    // In the rare event that the app doesn't crash from loading a video file (excluding video index files and video reference files) into RAM, the server on which the file is hosted won't go down when the active app changes to the Universal Video Downloader app, and the instance of UVDHTTPRequest that the Universal Video Downloader app uses is able to download the video file despite its URL scheme (highly unlikely).
                    [self didIdentifyVideoFileWithFinalURL:finalURL];
                }
            }
            else {
                [self didIdentifyVideoFileWithFinalURL:finalURL];
            }
            
            [receivedDataString release];
        }
    }
}

#pragma mark -
#pragma mark Internal Functions

- (void)showConnectionFailedAlert {
    UIAlertView *connectionFailedAlert = [[UIAlertView alloc]
                                          initWithTitle:@"Connection Failed"
                                          message:@"The connection to the server failed. Please check your Internet connection status and try again. You can also try playing the video again. If these solutions do not fix the problem, the app you are trying to download videos from may not be supported at this time."
                                          delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [connectionFailedAlert show];
    [connectionFailedAlert release];
}

- (void)didIdentifyVideoFileWithFinalURL:(NSURL *)finalURL {
    [self setUpRootDownloadFilePath];
    
    [self saveVideoFileWithURL:finalURL];
}

- (void)didIdentifyVideoStreamWithFinalURL:(NSURL *)finalURL indexFileContents:(NSString *)indexFileContents {
    [self setUpRootDownloadFilePath];
    
    [self saveVideoStreamWithIndexFileURL:finalURL contents:indexFileContents];
}

- (void)setUpRootDownloadFilePath {
    // I don't think the library directory will ever have a trailing slash (or start with the /private directory, for that matter), but I'm including it just to be safe.
    NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    if (([libraryDirectory isEqualToString:@"/var/mobile/Library"]) ||
        ([libraryDirectory isEqualToString:@"/var/mobile/Library/"]) ||
        ([libraryDirectory isEqualToString:@"/private/var/mobile/Library"]) ||
        ([libraryDirectory isEqualToString:@"/private/var/mobile/Library/"])) {
        
        rootDownloadFilePath = @"/private/var/tmp/Universal_Video_Downloader";
    }
    else {
        rootDownloadFilePath = [libraryDirectory stringByAppendingPathComponent:@"Universal_Video_Downloader"];
    }
    
    // This will be automatically released if I don't retain it here.
    [rootDownloadFilePath retain];
}

- (void)cleanUp {
    if (rootDownloadFilePath) {
        [rootDownloadFilePath release];
        rootDownloadFilePath = nil;
    }
    
    indexFile = nil;
    
    if (audioTracksArray) {
        [audioTracksArray removeAllObjects];
        audioTracksArray = nil;
    }
    
    if (videosArray) {
        [videosArray removeAllObjects];
        videosArray = nil;
    }
    
    if (savedFileNamesArray) {
        [savedFileNamesArray removeAllObjects];
        savedFileNamesArray = nil;
    }
    
    if (savedFileURLsDictionary) {
        [savedFileURLsDictionary removeAllObjects];
        savedFileURLsDictionary = nil;
    }
}

- (void)didFinish {
    [self cleanUp];
    
    if (_delegate) {
        if ([_delegate respondsToSelector:@selector(videoProcessorDidFinishProcessing)]) {
            [_delegate videoProcessorDidFinishProcessing];
        }
    }
}

- (NSURL *)rootURLFromURL:(NSURL *)url {
    NSString *urlScheme = [url scheme];
    NSString *urlHost = [url host];
    
    NSNumber *urlPort = [url port];
    if (urlPort) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@", urlScheme, urlHost, [urlPort stringValue]]];
    }
    else {
        return [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", urlScheme, urlHost]];
    }
}

- (NSURL *)directoryURLFromURL:(NSURL *)url {
    NSString *finalURLPath = nil;
    
    // NSURL's -URLByAppendingPathComponent: function automatically adds a trailing slash to the URL that is passed to it, so I have to strip the initial slash that may be present in the path that I want to append to that URL.
    // NSString's -stringByDeletingLastPathComponent function automatically strips any trailing slashes that may be present in the path that is passed to it, so I don't have to worry about stripping them myself here (which I would have to do because NSURL's -URLByAppendingPathComponent: function is used in other places in this code; see the comment on the previous line for more information about this).
    NSString *urlPath = [[url path]stringByDeletingLastPathComponent];
    if ([[urlPath substringToIndex:1]isEqualToString:@"/"]) {
        finalURLPath = [urlPath substringFromIndex:1];
    }
    else {
        finalURLPath = urlPath;
    }
    
    return [[self rootURLFromURL:url]URLByAppendingPathComponent:finalURLPath];
}

- (NSString *)downloadFileNameForFileWithName:(NSString *)fileName {
    NSString *finalFileName = nil;
    if ([fileName length] > 0) {
        // I could automatically truncate file names to 255 characters, but I believe such an overflow (from files stored on a server) happens far too rarely to be worth implementing (I've never seen it happen while testing this program).
        
        // This prevents invalid characters from appearing in the file names.
        NSMutableString *revisedFileName = [NSMutableString stringWithString:fileName];
        for (int i = 0; i < ([kFileNameReplacementStringsArray count] / 2.0); i++) {
            [revisedFileName setString:[revisedFileName stringByReplacingOccurrencesOfString:[kFileNameReplacementStringsArray objectAtIndex:(i * 2)] withString:[kFileNameReplacementStringsArray objectAtIndex:((i * 2) + 1)]]];
        }
        
        finalFileName = revisedFileName;
    }
    else {
        finalFileName = kDefaultFileNameStr;
    }
    
    if ([savedFileNamesArray containsObject:finalFileName]) {
        NSInteger copyNumber = 2;
        
        NSString *pathExtension = [finalFileName pathExtension];
        if ([pathExtension length] > 0) {
            NSString *baseFileName = [finalFileName stringByDeletingPathExtension];
            
            while ([savedFileNamesArray containsObject:[[baseFileName stringByAppendingFormat:kCopyFormatStr, copyNumber]stringByAppendingPathExtension:pathExtension]]) {
                copyNumber += 1;
            }
            return [[baseFileName stringByAppendingFormat:kCopyFormatStr, copyNumber]stringByAppendingPathExtension:pathExtension];
        }
        else {
            while ([savedFileNamesArray containsObject:[finalFileName stringByAppendingFormat:kCopyFormatStr, copyNumber]]) {
                copyNumber += 1;
            }
            return [finalFileName stringByAppendingFormat:kCopyFormatStr, copyNumber];
        }
    }
    else {
        return finalFileName;
    }
}

- (void)saveVideoFileWithURL:(NSURL *)videoFileURL {
    if (![[NSFileManager defaultManager]createDirectoryAtPath:rootDownloadFilePath withIntermediateDirectories:YES attributes:nil error:nil]) {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Error Creating Download Folder"
                                   message:@"The app encountered an error while trying to create the download folder. Please make sure the app has read and write access to this app's bundle directory and try again."
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
        
        [self didFinish];
        
        return;
    }
    
    NSString *videoFileURLString = [videoFileURL absoluteString];
    
    NSString *videoFileNameWithExtension = nil;
    
    NSString *videoFileName = [[videoFileURL lastPathComponent]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if ([[videoFileName pathExtension]length] > 0) {
        videoFileNameWithExtension = videoFileName;
    }
    else {
        videoFileNameWithExtension = [videoFileName stringByAppendingPathExtension:kDefaultVideoFilePathExtensionStr];
    }
    
    NSString *finalVideoFileName = [self downloadFileNameForFileWithName:videoFileNameWithExtension];
    
    NSDictionary *metadataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO], kIsVideoStreamKey,
                                        finalVideoFileName, kVideoFileNameKey,
                                        [NSDictionary dictionaryWithObjectsAndKeys:finalVideoFileName, videoFileURLString, nil], kVideoFileURLsDictionaryKey,
                                        nil];
    
    if (![metadataDictionary writeToFile:[rootDownloadFilePath stringByAppendingPathComponent:kMetadataFileNameStr] atomically:YES]) {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Error Saving Video Metadata File"
                                   message:@"The app encountered an error while trying to save the video metadata file. Please make sure the app has read and write access to this app's bundle directory and try again."
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
        
        [self didFinish];
        
        return;
    }
    
    NSString *url = [kURLPrefixStr stringByAppendingString:rootDownloadFilePath];
    NSURL *formattedURL = [NSURL URLWithString:url];
    
    [[UIApplication sharedApplication]openURL:formattedURL];
    
    [self didFinish];
}

- (void)saveVideoStreamWithIndexFileURL:(NSURL *)indexFileURL contents:(NSString *)indexFileContents {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:rootDownloadFilePath]) {
        [fileManager removeItemAtPath:rootDownloadFilePath error:nil];
    }
    
    if (![fileManager createDirectoryAtPath:rootDownloadFilePath withIntermediateDirectories:YES attributes:nil error:nil]) {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Error Creating Download Folder"
                                   message:@"The app encountered an error while trying to create the download folder. Please make sure the app has read and write access to this app's bundle directory and try again."
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
        
        [self didFinish];
        
        return;
    }
    
    if (indexFileContents) {
        indexFile = [NSMutableString stringWithString:indexFileContents];
        
        if ([indexFile length] <= 0) {
            UIAlertView *errorAlert = [[UIAlertView alloc]
                                       initWithTitle:@"Error Reading Video Index File"
                                       message:@"The app encountered an error while trying to read the video index file. The app you are trying to download videos from may not be supported at this time."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [errorAlert show];
            [errorAlert release];
            
            [self didFinish];
            
            return;
        }
    }
    else {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Error Reading Video Index File"
                                   message:@"The app encountered an error while trying to read the video index file. The app you are trying to download videos from may not be supported at this time."
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
        
        [self didFinish];
        
        return;
    }
    
    NSMutableDictionary *metadataDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kIsVideoStreamKey, nil];
    
    audioTracksArray = [NSMutableArray arrayWithObjects:nil];
    videosArray = [NSMutableArray arrayWithObjects:nil];
    
    savedFileNamesArray = [NSMutableArray arrayWithObject:kMetadataFileNameStr];
    savedFileURLsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:nil];
    
    [self processIndexFileAtURL:indexFileURL];
    
    if ([videosArray count] <= 0) {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Error Extracting Video Reference Files"
                                   message:@"The app encountered an error while trying to extract the video reference files. The app you are trying to download videos from may not be supported at this time."
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
        
        [self didFinish];
        
        return;
    }
    
    if ([audioTracksArray count] > 0) {
        NSMutableArray *sortedAudioTracksArray = nil;
        if ([audioTracksArray count] == 1) {
            sortedAudioTracksArray = [NSMutableArray arrayWithObject:[audioTracksArray objectAtIndex:0]];
        }
        else {
            sortedAudioTracksArray = [NSMutableArray arrayWithObjects:nil];
            
            NSMutableDictionary *defaultAudioTrackMetadata = [NSMutableDictionary dictionaryWithObjectsAndKeys:nil];
            
            NSMutableDictionary *audioFilesDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:nil];
            
            BOOL didSetDefaultAudioTrack = NO;
            
            for (int i = 0; i < [audioTracksArray count]; i++) {
                NSDictionary *audioTrackMetadata = [audioTracksArray objectAtIndex:i];
                if ((!didSetDefaultAudioTrack) && ([[audioTrackMetadata objectForKey:kIsDefaultAudioTrackKey]integerValue] == [[NSNumber numberWithBool:YES]integerValue])) {
                    [defaultAudioTrackMetadata setDictionary:audioTrackMetadata];
                    didSetDefaultAudioTrack = YES;
                }
                else {
                    [audioFilesDictionary setObject:audioTrackMetadata forKey:[audioTrackMetadata objectForKey:kAudioTrackLanguageTitleKey]];
                }
            }
            
            if (didSetDefaultAudioTrack) {
                // If I don't copy the defaultAudioTrackMetadata variable using NSDictionary's -dictionaryWithDictionary: method, a reference to it will be set instead of a new dictionary, so when I clear it later on to save RAM, that reference will point to an empty dictionary, rendering the audio track metadata useless.
                [sortedAudioTracksArray addObject:[NSDictionary dictionaryWithDictionary:defaultAudioTrackMetadata]];
            }
            else if (defaultAudioTrackOnly) {
                NSDictionary *audioTrackMetadata = [audioTracksArray objectAtIndex:0];
                [defaultAudioTrackMetadata setDictionary:audioTrackMetadata];
                [sortedAudioTracksArray addObject:audioTrackMetadata];
            }
            
            [audioTracksArray removeAllObjects];
            audioTracksArray = nil;
            
            NSMutableArray *audioFilesDictionaryKeysArray = [NSMutableArray arrayWithArray:[audioFilesDictionary allKeys]];
            if (defaultAudioTrackOnly) {
                NSDictionary *audioTrackReferenceFileURLDictionary = [defaultAudioTrackMetadata objectForKey:kAudioTrackReferenceFileURLDictionaryKey];
                NSString *audioTrackReferenceFileName = [audioTrackReferenceFileURLDictionary objectForKey:[[audioTrackReferenceFileURLDictionary allKeys]objectAtIndex:0]];
                NSString *fullQualityAudioTrackReferenceFileName = audioTrackReferenceFileName;
                
                for (int i = 0; i < [audioFilesDictionaryKeysArray count]; i++) {
                    NSString *audioLanguageTitle = [audioFilesDictionaryKeysArray objectAtIndex:i];
                    NSDictionary *audioTrackMetadata = [audioFilesDictionary objectForKey:audioLanguageTitle];
                    NSDictionary *audioTrackReferenceFileURLDictionary = [audioTrackMetadata objectForKey:kAudioTrackReferenceFileURLDictionaryKey];
                    NSString *audioTrackReferenceFileName = [audioTrackReferenceFileURLDictionary objectForKey:[[audioTrackReferenceFileURLDictionary allKeys]objectAtIndex:0]];
                    
                    // This can be improved upon in future versions of the app to make it safer.
                    [indexFile setString:[indexFile stringByReplacingOccurrencesOfString:audioTrackReferenceFileName withString:fullQualityAudioTrackReferenceFileName]];
                }
                
                [defaultAudioTrackMetadata removeAllObjects];
                defaultAudioTrackMetadata = nil;
            }
            else {
                [defaultAudioTrackMetadata removeAllObjects];
                defaultAudioTrackMetadata = nil;
                
                [audioFilesDictionaryKeysArray sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
                
                for (int i = 0; i < [audioFilesDictionaryKeysArray count]; i++) {
                    NSString *audioLanguageTitle = [audioFilesDictionaryKeysArray objectAtIndex:i];
                    NSDictionary *audioTrackMetadata = [audioFilesDictionary objectForKey:audioLanguageTitle];
                    [sortedAudioTracksArray addObject:audioTrackMetadata];
                }
            }
        }
        
        for (int i = 0; i < [sortedAudioTracksArray count]; i++) {
            NSMutableDictionary *audioTrackMetadata = [NSMutableDictionary dictionaryWithDictionary:[sortedAudioTracksArray objectAtIndex:i]];
            
            NSDictionary *audioTrackReferenceFileDictionary = [audioTrackMetadata objectForKey:kAudioTrackReferenceFileURLDictionaryKey];
            NSString *audioTrackReferenceFileURL = [[audioTrackReferenceFileDictionary allKeys]objectAtIndex:0];
            NSString *audioTrackReferenceFileName = [audioTrackReferenceFileDictionary objectForKey:audioTrackReferenceFileURL];
            
            NSURL *formattedAudioTrackReferenceFileURL = [NSURL URLWithString:audioTrackReferenceFileURL];
            
            NSString *urlScheme = [[formattedAudioTrackReferenceFileURL scheme]lowercaseString];
            if (([urlScheme isEqualToString:kLowercaseHTTPURLSchemeStr]) || ([urlScheme isEqualToString:kLowercaseHTTPSURLSchemeStr])) {
                NSMutableData *receivedData = [[NSMutableData alloc]init];
                
                UVDHTTPRequest *request = [UVDHTTPRequest requestWithURL:formattedAudioTrackReferenceFileURL];
                
                // If this is set to YES, the received data from some services can be corrupt.
                request.allowCompressedResponse = NO;
                
                request.timeOutSeconds = DOWNLOAD_TIMEOUT_IN_SECONDS;
                
                [request setStartedBlock:^{
                    [receivedData setLength:0];
                }];
                [request setDataReceivedBlock:^(NSData *data) {
                    [receivedData appendData:data];
                }];
                [request setFailedBlock:^{
                    [receivedData release];
                }];
                [request setCompletionBlock:^{
                    NSString *receivedDataString = [[NSString alloc]initWithData:receivedData encoding:NSASCIIStringEncoding];
                    
                    [receivedData release];
                    
                    NSURL *finalURL = request.url;
                    if ((finalURL) && (receivedDataString) && ([receivedDataString length] > 0)) {
                        NSMutableString *audioReferenceFile = [NSMutableString stringWithString:receivedDataString];
                        
                        NSMutableDictionary *audioFileURLsDictionary = [NSMutableDictionary dictionaryWithDictionary:[self fileURLsDictionaryFromReferenceFile:audioReferenceFile atURL:finalURL]];
                        
                        [audioTrackMetadata removeObjectForKey:kAudioTrackReferenceFileURLDictionaryKey];
                        [audioTrackMetadata setObject:audioTrackReferenceFileName forKey:kAudioTrackReferenceFileNameKey];
                        [audioTrackMetadata setObject:audioFileURLsDictionary forKey:kAudioTrackFileURLsDictionaryKey];
                        [sortedAudioTracksArray replaceObjectAtIndex:i withObject:audioTrackMetadata];
                        
                        [audioReferenceFile writeToFile:[rootDownloadFilePath stringByAppendingPathComponent:audioTrackReferenceFileName] atomically:YES encoding:NSUTF8StringEncoding error:nil];
                    }
                    
                    [receivedDataString release];
                }];
                
                [request startSynchronous];
            }
            else {
                // In case the video reference file is hosted by a local server and, because of its URL scheme, cannot be downloaded by an instance of the UVDHTTPRequest class.
                // I am using an instance of NSURLConnection so that it will handle any possible redirects and return the data at the final URL.
                
                NSError *error = nil;
                
                NSURLRequest *request = [NSURLRequest requestWithURL:formattedAudioTrackReferenceFileURL];
                NSURLResponse *response = nil;
                NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                if (response) {
                    NSURL *finalURL = [response URL];
                    if ((!error) && (finalURL) && (receivedData)) {
                        // I believe I have to use the same block of code as above because using the __block specifier with a mutual variable seems to cause the app to crash.
                        
                        NSString *receivedDataString = [[NSString alloc]initWithData:receivedData encoding:NSASCIIStringEncoding];
                        
                        if ((receivedDataString) && ([receivedDataString length] > 0)) {
                            NSMutableString *audioReferenceFile = [NSMutableString stringWithString:receivedDataString];
                            
                            NSMutableDictionary *audioFileURLsDictionary = [NSMutableDictionary dictionaryWithDictionary:[self fileURLsDictionaryFromReferenceFile:audioReferenceFile atURL:finalURL]];
                            
                            [audioTrackMetadata removeObjectForKey:kAudioTrackReferenceFileURLDictionaryKey];
                            [audioTrackMetadata setObject:audioTrackReferenceFileName forKey:kAudioTrackReferenceFileNameKey];
                            [audioTrackMetadata setObject:audioFileURLsDictionary forKey:kAudioTrackFileURLsDictionaryKey];
                            [sortedAudioTracksArray replaceObjectAtIndex:i withObject:audioTrackMetadata];
                            
                            [audioReferenceFile writeToFile:[rootDownloadFilePath stringByAppendingPathComponent:audioTrackReferenceFileName] atomically:YES encoding:NSUTF8StringEncoding error:nil];
                        }
                        
                        [receivedDataString release];
                    }
                }
            }
        }
        
        [metadataDictionary setObject:sortedAudioTracksArray forKey:kAudioTracksKey];
    }
    
    NSMutableArray *sortedVideosArray = nil;
    
    if ([videosArray count] == 1) {
        sortedVideosArray = [NSMutableArray arrayWithObject:[videosArray objectAtIndex:0]];
    }
    else {
        sortedVideosArray = [NSMutableArray arrayWithObjects:nil];
        
        NSMutableDictionary *videoFilesDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:nil];
        for (int i = 0; i < [videosArray count]; i++) {
            NSDictionary *videoFileMetadata = [videosArray objectAtIndex:i];
            [videoFilesDictionary setObject:videoFileMetadata forKey:[videoFileMetadata objectForKey:kBandwidthKey]];
        }
        
        NSArray *sortedVideoFileBandwidthStringsArray = [[videoFilesDictionary allKeys]sortedArrayUsingComparator:^(id firstObject, id secondObject) {
            // Take note of the negative sign before the return value. This reverses the sorting algorithm such that videos are sorted from highest to lowest bandwidth instead of the other way around.
            return - [((NSString *)firstObject) compare:((NSString *)secondObject) options:NSNumericSearch];
        }];
        
        for (int i = 0; i < [sortedVideoFileBandwidthStringsArray count]; i++) {
            NSString *bandwidthString = [sortedVideoFileBandwidthStringsArray objectAtIndex:i];
            [sortedVideosArray addObject:[videoFilesDictionary objectForKey:bandwidthString]];
        }
        
        if (fullQualityVideoOnly) {
            NSString *fullQualityVideoReferenceFileName = nil;
            for (int i = 0; i < [sortedVideosArray count]; i++) {
                NSDictionary *videoReferenceFileURLDictionary = [[sortedVideosArray objectAtIndex:i]objectForKey:kVideoReferenceFileURLDictionaryKey];
                NSString *videoReferenceFileName = [videoReferenceFileURLDictionary objectForKey:[[videoReferenceFileURLDictionary allKeys]objectAtIndex:0]];
                if (i == 0) {
                    fullQualityVideoReferenceFileName = videoReferenceFileName;
                }
                else if (![videoReferenceFileName isEqualToString:fullQualityVideoReferenceFileName]) {
                    // This can be improved upon in future versions of the app to make it safer.
                    [indexFile setString:[indexFile stringByReplacingOccurrencesOfString:videoReferenceFileName withString:fullQualityVideoReferenceFileName]];
                }
            }
            
            [sortedVideosArray setArray:[NSArray arrayWithObject:[sortedVideosArray objectAtIndex:0]]];
        }
    }
    
    [videosArray removeAllObjects];
    videosArray = nil;
    
    NSMutableArray *finalVideosArray = [NSMutableArray arrayWithObjects:nil];
    
    for (int i = 0; i < [sortedVideosArray count]; i++) {
        NSMutableDictionary *videoFileMetadata = [NSMutableDictionary dictionaryWithDictionary:[sortedVideosArray objectAtIndex:i]];
        
        NSDictionary *videoReferenceFileDictionary = [videoFileMetadata objectForKey:kVideoReferenceFileURLDictionaryKey];
        NSString *videoReferenceFileURL = [[videoReferenceFileDictionary allKeys]objectAtIndex:0];
        NSString *videoReferenceFileName = [videoReferenceFileDictionary objectForKey:videoReferenceFileURL];
        
        NSURL *formattedVideoReferenceFileURL = [NSURL URLWithString:videoReferenceFileURL];
        
        NSString *urlScheme = [[formattedVideoReferenceFileURL scheme]lowercaseString];
        if (([urlScheme isEqualToString:kLowercaseHTTPURLSchemeStr]) || ([urlScheme isEqualToString:kLowercaseHTTPSURLSchemeStr])) {
            NSMutableData *receivedData = [[NSMutableData alloc]init];
            
            UVDHTTPRequest *request = [UVDHTTPRequest requestWithURL:formattedVideoReferenceFileURL];
            
            // If this is set to YES, the received data from some services can be corrupt.
            request.allowCompressedResponse = NO;
            
            request.timeOutSeconds = DOWNLOAD_TIMEOUT_IN_SECONDS;
            
            [request setStartedBlock:^{
                [receivedData setLength:0];
            }];
            [request setDataReceivedBlock:^(NSData *data) {
                [receivedData appendData:data];
            }];
            [request setFailedBlock:^{
                [receivedData release];
            }];
            [request setCompletionBlock:^{
                NSString *receivedDataString = [[NSString alloc]initWithData:receivedData encoding:NSASCIIStringEncoding];
                
                [receivedData release];
                
                NSURL *finalURL = request.url;
                if ((finalURL) && (receivedDataString) && ([receivedDataString length] > 0)) {
                    NSMutableString *videoReferenceFile = [NSMutableString stringWithString:receivedDataString];
                    
                    NSDictionary *videoFileURLsDictionary = [self fileURLsDictionaryFromReferenceFile:videoReferenceFile atURL:finalURL];
                    
                    if ([[videoFileURLsDictionary allKeys]count] > 0) {
                        [videoFileMetadata removeObjectForKey:kVideoReferenceFileURLDictionaryKey];
                        [videoFileMetadata setObject:videoReferenceFileName forKey:kVideoReferenceFileNameKey];
                        [videoFileMetadata setObject:videoFileURLsDictionary forKey:kVideoFileURLsDictionaryKey];
                        
                        [finalVideosArray addObject:videoFileMetadata];
                        
                        [videoReferenceFile writeToFile:[rootDownloadFilePath stringByAppendingPathComponent:videoReferenceFileName] atomically:YES encoding:NSUTF8StringEncoding error:nil];
                    }
                }
                
                [receivedDataString release];
            }];
            
            [request startSynchronous];
        }
        else {
            // In case the video reference file is hosted by a local server and, because of its URL scheme, cannot be downloaded by an instance of the UVDHTTPRequest class.
            // I am using an instance of NSURLConnection so that it will handle any possible redirects and return the data at the final URL.
            
            NSError *error = nil;
            
            NSURLRequest *request = [NSURLRequest requestWithURL:formattedVideoReferenceFileURL];
            NSURLResponse *response = nil;
            NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            if (response) {
                NSURL *finalURL = [response URL];
                if ((!error) && (receivedData) && (finalURL)) {
                    // I believe I have to use the same block of code as above because using the __block specifier with a mutual variable seems to cause the app to crash.
                    
                    NSString *receivedDataString = [[NSString alloc]initWithData:receivedData encoding:NSASCIIStringEncoding];
                    
                    NSURL *finalURL = [response URL];
                    if ((finalURL) && (receivedDataString) && ([receivedDataString length] > 0)) {
                        NSMutableString *videoReferenceFile = [NSMutableString stringWithString:receivedDataString];
                        
                        NSDictionary *videoFileURLsDictionary = [self fileURLsDictionaryFromReferenceFile:videoReferenceFile atURL:finalURL];
                        
                        if ([[videoFileURLsDictionary allKeys]count] > 0) {
                            [videoFileMetadata removeObjectForKey:kVideoReferenceFileURLDictionaryKey];
                            [videoFileMetadata setObject:videoReferenceFileName forKey:kVideoReferenceFileNameKey];
                            [videoFileMetadata setObject:videoFileURLsDictionary forKey:kVideoFileURLsDictionaryKey];
                            
                            [finalVideosArray addObject:videoFileMetadata];
                            
                            [videoReferenceFile writeToFile:[rootDownloadFilePath stringByAppendingPathComponent:videoReferenceFileName] atomically:YES encoding:NSUTF8StringEncoding error:nil];
                        }
                    }
                    
                    [receivedDataString release];
                }
            }
        }
    }
    
    [sortedVideosArray removeAllObjects];
    sortedVideosArray = nil;
    
    if ([finalVideosArray count] > 0) {
        // If I don't copy the finalVideosArray variable using NSArray's -arrayWithArray: method, a reference to it will be set instead of a new array, so when I clear it later on to save RAM, that reference will point to an empty array, rendering the video metadata useless.
        [metadataDictionary setObject:[NSArray arrayWithArray:finalVideosArray] forKey:kVideosKey];
    }
    else {
        // This is perhaps the most common error message, so I added a newline character between the two sentences to improve its appearance.
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Error Extracting Video Files"
                                   message:@"The app encountered an error while trying to extract the video files.\nThe app you are trying to download videos from may not be supported at this time."
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
        
        [self didFinish];
        
        return;
    }
    
    [finalVideosArray removeAllObjects];
    finalVideosArray = nil;
    
    NSString *originalIndexFileName = [indexFileURL lastPathComponent];
    NSString *indexFileDownloadFileName = [self downloadFileNameForFileWithName:originalIndexFileName];
    
    [savedFileNamesArray removeAllObjects];
    savedFileNamesArray = nil;
    
    [savedFileURLsDictionary removeAllObjects];
    savedFileURLsDictionary = nil;
    
    NSString *finalIndexFileDownloadFileName = nil;
    if ([[[indexFileDownloadFileName pathExtension]lowercaseString]isEqualToString:kLowercaseVideoStreamIndexFilePathExtensionStr]) {
        finalIndexFileDownloadFileName = indexFileDownloadFileName;
    }
    else {
        finalIndexFileDownloadFileName = [indexFileDownloadFileName stringByAppendingPathExtension:kLowercaseVideoStreamIndexFilePathExtensionStr];
    }
    
    if (![indexFile writeToFile:[rootDownloadFilePath stringByAppendingPathComponent:finalIndexFileDownloadFileName] atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Error Saving Video Index File"
                                   message:@"The app encountered an error while trying to save the video index file. Please make sure the app has read and write access to this app's bundle directory and try again."
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
        
        [self didFinish];
        
        return;
    }
    
    [metadataDictionary setObject:finalIndexFileDownloadFileName forKey:kIndexFileNameKey];
    
    if (![metadataDictionary writeToFile:[rootDownloadFilePath stringByAppendingPathComponent:kMetadataFileNameStr] atomically:YES]) {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Error Saving Video Metadata File"
                                   message:@"The app encountered an error while trying to save the video metadata file. Please make sure the app has read and write access to this app's bundle directory and try again."
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
        
        [self didFinish];
        
        return;
    }
    
    NSString *url = [kURLPrefixStr stringByAppendingString:rootDownloadFilePath];
    NSURL *formattedURL = [NSURL URLWithString:url];
    
    [[UIApplication sharedApplication]openURL:formattedURL];
    
    [self didFinish];
}

- (void)processIndexFileAtURL:(NSURL *)url {
    NSURL *indexFileRootURL = [self rootURLFromURL:url];
    NSURL *indexFileDirectoryURL = [self directoryURLFromURL:url];
    
    NSMutableDictionary *pendingAudioTrackMetadata = [NSMutableDictionary dictionaryWithObjectsAndKeys:nil];
    NSMutableDictionary *pendingVideoMetadata = [NSMutableDictionary dictionaryWithObjectsAndKeys:nil];
    
    BOOL videoReferenceFileIsDuplicate = NO;
    NSMutableString *duplicateVideoReferenceFileReplacementURLString = [NSMutableString stringWithString:kNullStr];
    
    NSMutableArray *indexFileComponents = [NSMutableArray arrayWithArray:[indexFile componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
    for (int i = 0; i < [indexFileComponents count]; i++) {
        NSString *component = [indexFileComponents objectAtIndex:i];
        if (component) {
            if ([component length] > 0) {
                if ([[component substringToIndex:1]isEqualToString:@"#"]) {
                    NSString *componentTitle = nil;
                    NSRange colonRange = [component rangeOfString:@":"];
                    if (colonRange.location == NSNotFound) {
                        componentTitle = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    }
                    else {
                        componentTitle = [[component substringToIndex:colonRange.location]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    }
                    if ([[[componentTitle substringFromIndex:1]uppercaseString]isEqualToString:@"EXT-X-MEDIA"]) {
                        BOOL shouldSaveAudioTrack = NO;
                        
                        NSString *componentVariableSeparatorString = @",";
                        
                        NSInteger componentVariableStringIndex = (colonRange.location + 1);
                        NSString *componentVariableString = [component substringFromIndex:componentVariableStringIndex];
                        NSMutableArray *componentVariablesArray = [NSMutableArray arrayWithArray:[componentVariableString componentsSeparatedByString:componentVariableSeparatorString]];
                        for (int j = 0; j < [componentVariablesArray count]; j++) {
                            NSString *componentVariable = [componentVariablesArray objectAtIndex:j];
                            NSRange equalsSignRange = [componentVariable rangeOfString:@"="];
                            if (equalsSignRange.location != NSNotFound) {
                                NSString *componentVariableTitle = [[componentVariable substringToIndex:equalsSignRange.location]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                if ([[componentVariableTitle uppercaseString]isEqualToString:@"NAME"]) {
                                    NSString *audioLanguageTitleWithQuotes = [[componentVariable substringFromIndex:(equalsSignRange.location + 1)]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                    NSString *audioLanguageTitleWithoutQuotes = [audioLanguageTitleWithQuotes stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
                                    if ([audioLanguageTitleWithoutQuotes length] > 0) {
                                        [pendingAudioTrackMetadata setObject:audioLanguageTitleWithoutQuotes forKey:kAudioTrackLanguageTitleKey];
                                    }
                                }
                                else if ([[componentVariableTitle uppercaseString]isEqualToString:@"DEFAULT"]) {
                                    BOOL isDefaultAudioTrack = NO;
                                    
                                    NSString *componentVariableValue = [[componentVariable substringFromIndex:(equalsSignRange.location + 1)]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                    if ([[componentVariableValue uppercaseString]isEqualToString:@"YES"]) {
                                        isDefaultAudioTrack = YES;
                                    }
                                    
                                    [pendingAudioTrackMetadata setObject:[NSNumber numberWithBool:isDefaultAudioTrack] forKey:kIsDefaultAudioTrackKey];
                                }
                                else if ([[componentVariableTitle uppercaseString]isEqualToString:@"URI"]) {
                                    NSInteger audioReferenceFileURLIndex = (equalsSignRange.location + 1);
                                    NSString *audioReferenceFileURLWithQuotes = [[componentVariable substringFromIndex:audioReferenceFileURLIndex]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                    NSString *audioReferenceFileURLWithoutQuotes = [audioReferenceFileURLWithQuotes stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
                                    if ([audioReferenceFileURLWithoutQuotes length] > 0) {
                                        NSString *audioReferenceFileName = nil;
                                        if ([[savedFileURLsDictionary allKeys]containsObject:audioReferenceFileURLWithoutQuotes]) {
                                            audioReferenceFileName = [savedFileURLsDictionary objectForKey:audioReferenceFileURLWithoutQuotes];
                                            
                                            shouldSaveAudioTrack = NO;
                                        }
                                        else {
                                            NSURL *formattedAudioReferenceFileURL = [NSURL URLWithString:audioReferenceFileURLWithoutQuotes];
                                            audioReferenceFileName = [self downloadFileNameForFileWithName:[formattedAudioReferenceFileURL lastPathComponent]];
                                            
                                            [pendingAudioTrackMetadata setObject:[NSDictionary dictionaryWithObjectsAndKeys:audioReferenceFileName, audioReferenceFileURLWithoutQuotes, nil] forKey:kAudioTrackReferenceFileURLDictionaryKey];
                                            
                                            [savedFileURLsDictionary setObject:audioReferenceFileName forKey:audioReferenceFileURLWithoutQuotes];
                                            [savedFileNamesArray addObject:audioReferenceFileName];
                                            
                                            shouldSaveAudioTrack = YES;
                                        }
                                        
                                        if (![audioReferenceFileURLWithoutQuotes isEqualToString:audioReferenceFileName]) {
                                            NSString *componentVariablePrefix = [componentVariable substringToIndex:audioReferenceFileURLIndex];
                                            [componentVariablesArray replaceObjectAtIndex:j withObject:[componentVariablePrefix stringByAppendingFormat:@"\"%@\"", audioReferenceFileName]];
                                        }
                                    }
                                }
                                
                                if (([pendingAudioTrackMetadata objectForKey:kAudioTrackLanguageTitleKey]) &&
                                    ([pendingAudioTrackMetadata objectForKey:kIsDefaultAudioTrackKey]) &&
                                    ([pendingAudioTrackMetadata objectForKey:kAudioTrackReferenceFileURLDictionaryKey])) {
                                    
                                    break;
                                }
                            }
                        }
                        
                        NSString *componentVariableStringPrefix = [component substringToIndex:componentVariableStringIndex];
                        [indexFileComponents replaceObjectAtIndex:i withObject:[componentVariableStringPrefix stringByAppendingString:[componentVariablesArray componentsJoinedByString:componentVariableSeparatorString]]];
                        
                        if (([pendingAudioTrackMetadata objectForKey:kAudioTrackLanguageTitleKey]) &&
                            ([pendingAudioTrackMetadata objectForKey:kIsDefaultAudioTrackKey]) &&
                            ([pendingAudioTrackMetadata objectForKey:kAudioTrackReferenceFileURLDictionaryKey])) {
                            
                            // I could put this farther up where the shouldSaveAudioTrack is set to YES, but if it ran before the program knew whether or not it was the default audio track (in other words, if the "DEFAULT" variable came after the "URI" variable) it could run improperly.
                            if (shouldSaveAudioTrack) {
                                [audioTracksArray addObject:[NSDictionary dictionaryWithDictionary:pendingAudioTrackMetadata]];
                            }
                            
                            [pendingAudioTrackMetadata removeAllObjects];
                        }
                    }
                    else if ([[[componentTitle substringFromIndex:1]uppercaseString]isEqualToString:@"EXT-X-STREAM-INF"]) {
                        NSString *componentVariableString = [component substringFromIndex:(colonRange.location + 1)];
                        NSArray *componentVariablesArray = [componentVariableString componentsSeparatedByString:@","];
                        for (int j = 0; j < [componentVariablesArray count]; j++) {
                            NSString *componentVariable = [componentVariablesArray objectAtIndex:j];
                            NSRange equalsSignRange = [componentVariable rangeOfString:@"="];
                            if (equalsSignRange.location != NSNotFound) {
                                NSString *componentVariableTitle = [[componentVariable substringToIndex:equalsSignRange.location]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                if ([[componentVariableTitle uppercaseString]isEqualToString:@"BANDWIDTH"]) {
                                    NSString *componentVariableValue = [[componentVariable substringFromIndex:(equalsSignRange.location + 1)]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                    
                                    videoReferenceFileIsDuplicate = NO;
                                    [duplicateVideoReferenceFileReplacementURLString setString:kNullStr];
                                    
                                    for (int k = 0; k < [videosArray count]; k++) {
                                        NSDictionary *videoMetadata = [videosArray objectAtIndex:k];
                                        if ([[videoMetadata objectForKey:kBandwidthKey]isEqualToString:componentVariableValue]) {
                                            NSDictionary *videoReferenceFileURLDictionary = [videoMetadata objectForKey:kVideoReferenceFileURLDictionaryKey];
                                            NSString *videoReferenceFileName = [videoReferenceFileURLDictionary objectForKey:[[videoReferenceFileURLDictionary allKeys]objectAtIndex:0]];
                                            
                                            [duplicateVideoReferenceFileReplacementURLString setString:videoReferenceFileName];
                                            
                                            videoReferenceFileIsDuplicate = YES;
                                            
                                            break;
                                        }
                                    }
                                    if (videoReferenceFileIsDuplicate) {
                                        [pendingVideoMetadata removeAllObjects];
                                    }
                                    else {
                                        [pendingVideoMetadata setObject:componentVariableValue forKey:kBandwidthKey];
                                    }
                                    
                                    break;
                                }
                            }
                        }
                    }
                }
                else {
                    NSString *replacementOriginalVideoReferenceFileURLString = nil;
                    
                    if (videoReferenceFileIsDuplicate) {
                        // If I don't copy the duplicateVideoReferenceFileReplacementURLString variable using the -stringWithString: function as I have done here, this will simply assign a reference to it (rather than assigning its value) and cause problems when it is changed. For this reason, I am using the -stringWithString: function. I could also use an NSMutableString, but since I've used so many NSStrings to make quick variable assignments in this program I decided to use another NSString instead.
                        replacementOriginalVideoReferenceFileURLString = [NSString stringWithString:duplicateVideoReferenceFileReplacementURLString];
                        
                        videoReferenceFileIsDuplicate = NO;
                        [duplicateVideoReferenceFileReplacementURLString setString:kNullStr];
                    }
                    else {
                        NSString *finalComponent = nil;
                        
                        NSRange urlPrefixRange = [component rangeOfString:@"://"];
                        if (urlPrefixRange.location == NSNotFound) {
                            if ([[component substringToIndex:1]isEqualToString:@"/"]) {
                                finalComponent = [[[indexFileRootURL URLByAppendingPathComponent:[component substringFromIndex:1]]absoluteString]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                            }
                            else {
                                finalComponent = [[[indexFileDirectoryURL URLByAppendingPathComponent:component]absoluteString]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                            }
                        }
                        else {
                            finalComponent = component;
                        }
                        
                        if ([[savedFileURLsDictionary allKeys]containsObject:finalComponent]) {
                            replacementOriginalVideoReferenceFileURLString = [savedFileURLsDictionary objectForKey:finalComponent];
                        }
                        else {
                            NSURL *formattedFinalVideoReferenceFileURL = [NSURL URLWithString:finalComponent];
                            replacementOriginalVideoReferenceFileURLString = [self downloadFileNameForFileWithName:[formattedFinalVideoReferenceFileURL lastPathComponent]];
                            
                            [pendingVideoMetadata setObject:[NSDictionary dictionaryWithObjectsAndKeys:replacementOriginalVideoReferenceFileURLString, finalComponent, nil] forKey:kVideoReferenceFileURLDictionaryKey];
                            [videosArray addObject:[NSDictionary dictionaryWithDictionary:pendingVideoMetadata]];
                            
                            [savedFileURLsDictionary setObject:replacementOriginalVideoReferenceFileURLString forKey:finalComponent];
                            [savedFileNamesArray addObject:replacementOriginalVideoReferenceFileURLString];
                        }
                        
                        [pendingVideoMetadata removeAllObjects];
                    }
                    
                    if (![component isEqualToString:replacementOriginalVideoReferenceFileURLString]) {
                        [indexFileComponents replaceObjectAtIndex:i withObject:replacementOriginalVideoReferenceFileURLString];
                    }
                }
            }
        }
    }
    
    indexFileRootURL = nil;
    indexFileDirectoryURL = nil;
    
    [indexFile setString:[indexFileComponents componentsJoinedByString:@"\n"]];
}

- (NSDictionary *)fileURLsDictionaryFromReferenceFile:(NSMutableString *)referenceFile atURL:(NSURL *)url {
    if (referenceFile) {
        if ([referenceFile length] > 0) {
            NSURL *referenceFileRootURL = [self rootURLFromURL:url];
            NSURL *referenceFileDirectoryURL = [self directoryURLFromURL:url];
            
            NSMutableDictionary *fileURLsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:nil];
            
            BOOL expectingFileURL = NO;
            
            NSMutableArray *referenceFileComponents = [NSMutableArray arrayWithArray:[referenceFile componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
            for (int i = 0; i < [referenceFileComponents count]; i++) {
                NSString *component = [referenceFileComponents objectAtIndex:i];
                if (component) {
                    if ([component length] > 0) {
                        if ([[component substringToIndex:1]isEqualToString:@"#"]) {
                            NSString *componentTitle = nil;
                            NSRange colonRange = [component rangeOfString:@":"];
                            if (colonRange.location == NSNotFound) {
                                componentTitle = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                            }
                            else {
                                componentTitle = [[component substringToIndex:colonRange.location]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                            }
                            if ([[[componentTitle substringFromIndex:1]uppercaseString]isEqualToString:@"EXT-X-KEY"]) {
                                NSString *componentVariableSeparatorString = @",";
                                
                                NSInteger componentVariableStringIndex = (colonRange.location + 1);
                                NSString *componentVariableString = [component substringFromIndex:componentVariableStringIndex];
                                NSMutableArray *componentVariablesArray = [NSMutableArray arrayWithArray:[componentVariableString componentsSeparatedByString:componentVariableSeparatorString]];
                                for (int j = 0; j < [componentVariablesArray count]; j++) {
                                    NSString *componentVariable = [componentVariablesArray objectAtIndex:j];
                                    NSRange equalsSignRange = [componentVariable rangeOfString:@"="];
                                    if (equalsSignRange.location != NSNotFound) {
                                        NSString *componentVariableTitle = [[componentVariable substringToIndex:equalsSignRange.location]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                        if ([[componentVariableTitle uppercaseString]isEqualToString:@"URI"]) {
                                            NSInteger encryptionKeyFileURLIndex = (equalsSignRange.location + 1);
                                            NSString *encryptionKeyFileURLWithQuotes = [[componentVariable substringFromIndex:encryptionKeyFileURLIndex]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                            NSString *encryptionKeyFileURLWithoutQuotes = [encryptionKeyFileURLWithQuotes stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
                                            
                                            NSString *encryptionKeyFileName = nil;
                                            if ([[savedFileURLsDictionary allKeys]containsObject:encryptionKeyFileURLWithoutQuotes]) {
                                                encryptionKeyFileName = [savedFileURLsDictionary objectForKey:encryptionKeyFileURLWithoutQuotes];
                                            }
                                            else {
                                                NSURL *formattedEncryptionKeyFileURL = [NSURL URLWithString:encryptionKeyFileURLWithoutQuotes];
                                                encryptionKeyFileName = [self downloadFileNameForFileWithName:[formattedEncryptionKeyFileURL lastPathComponent]];
                                                
                                                NSString *downloadPath = [rootDownloadFilePath stringByAppendingPathComponent:encryptionKeyFileName];
                                                
                                                NSString *urlScheme = [[formattedEncryptionKeyFileURL scheme]lowercaseString];
                                                if (([urlScheme isEqualToString:kLowercaseHTTPURLSchemeStr]) || ([urlScheme isEqualToString:kLowercaseHTTPSURLSchemeStr])) {
                                                    NSMutableData *receivedData = [[NSMutableData alloc]init];
                                                    
                                                    UVDHTTPRequest *request = [UVDHTTPRequest requestWithURL:formattedEncryptionKeyFileURL];
                                                    
                                                    // If this is set to YES, the received data from some services can be corrupt.
                                                    request.allowCompressedResponse = NO;
                                                    
                                                    request.timeOutSeconds = DOWNLOAD_TIMEOUT_IN_SECONDS;
                                                    
                                                    [request setStartedBlock:^{
                                                        [receivedData setLength:0];
                                                    }];
                                                    [request setDataReceivedBlock:^(NSData *data) {
                                                        [receivedData appendData:data];
                                                    }];
                                                    [request setFailedBlock:^{
                                                        [receivedData release];
                                                    }];
                                                    [request setCompletionBlock:^{
                                                        [receivedData writeToFile:downloadPath atomically:YES];
                                                        [receivedData release];
                                                    }];
                                                    
                                                    [request startSynchronous];
                                                }
                                                else {
                                                    // In case the encryption key file is hosted by a local server and, because of its URL scheme, cannot be downloaded by an instance of the UVDHTTPRequest class.
                                                    // I am using an instance of NSURLConnection so that it will handle any possible redirects and return the data at the final URL.
                                                    
                                                    NSError *error = nil;
                                                    
                                                    NSURLRequest *request = [NSURLRequest requestWithURL:formattedEncryptionKeyFileURL];
                                                    NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
                                                    if ((!error) && (receivedData)) {
                                                        [receivedData writeToFile:downloadPath atomically:YES];
                                                    }
                                                }
                                                
                                                [savedFileURLsDictionary setObject:encryptionKeyFileName forKey:encryptionKeyFileURLWithoutQuotes];
                                                [savedFileNamesArray addObject:encryptionKeyFileName];
                                            }
                                            
                                            if (![encryptionKeyFileURLWithoutQuotes isEqualToString:encryptionKeyFileName]) {
                                                NSString *componentVariablePrefix = [componentVariable substringToIndex:encryptionKeyFileURLIndex];
                                                [componentVariablesArray replaceObjectAtIndex:j withObject:[componentVariablePrefix stringByAppendingFormat:@"\"%@\"", encryptionKeyFileName]];
                                            }
                                        }
                                    }
                                }
                                
                                NSString *componentVariableStringPrefix = [component substringToIndex:componentVariableStringIndex];
                                [referenceFileComponents replaceObjectAtIndex:i withObject:[componentVariableStringPrefix stringByAppendingString:[componentVariablesArray componentsJoinedByString:componentVariableSeparatorString]]];
                            }
                            
                            expectingFileURL = YES;
                        }
                        else if (expectingFileURL) {
                            NSString *finalComponent = nil;
                            
                            NSRange urlPrefixRange = [component rangeOfString:@"://"];
                            if (urlPrefixRange.location == NSNotFound) {
                                if ([[component substringToIndex:1]isEqualToString:@"/"]) {
                                    finalComponent = [[[referenceFileRootURL URLByAppendingPathComponent:[component substringFromIndex:1]]absoluteString]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                                }
                                else {
                                    finalComponent = [[[referenceFileDirectoryURL URLByAppendingPathComponent:component]absoluteString]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                                }
                            }
                            else {
                                finalComponent = component;
                            }
                            
                            NSString *fileName = nil;
                            if ([[savedFileURLsDictionary allKeys]containsObject:finalComponent]) {
                                fileName = [savedFileURLsDictionary objectForKey:finalComponent];
                            }
                            else {
                                NSURL *formattedFileURL = [NSURL URLWithString:finalComponent];
                                fileName = [self downloadFileNameForFileWithName:[formattedFileURL lastPathComponent]];
                                
                                [savedFileURLsDictionary setObject:fileName forKey:finalComponent];
                                [savedFileNamesArray addObject:fileName];
                            }
                            
                            if (![component isEqualToString:fileName]) {
                                [referenceFileComponents replaceObjectAtIndex:i withObject:fileName];
                            }
                            
                            if (![[fileURLsDictionary allKeys]containsObject:finalComponent]) {
                                [fileURLsDictionary setObject:fileName forKey:finalComponent];
                            }
                            
                            expectingFileURL = NO;
                        }
                    }
                }
            }
            
            referenceFileRootURL = nil;
            referenceFileDirectoryURL = nil;
            
            [referenceFile setString:[referenceFileComponents componentsJoinedByString:@"\n"]];
            
            return fileURLsDictionary;
        }
    }
    
    return nil;
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [super dealloc];
}

@end
