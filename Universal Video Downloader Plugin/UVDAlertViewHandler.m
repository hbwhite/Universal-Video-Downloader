//
//  UVDAlertViewHandler.m
//  Universal Video Downloader
//
//  Created by Harrison White on 7/25/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import "UVDAlertViewHandler.h"

@interface UVDAlertViewHandler ()

@property (nonatomic, assign) UVDVideoProcessor *videoProcessor;
@property (nonatomic, assign) UIAlertView *downloadAlert;

- (void)updateDownloadAlert;

@end

@implementation UVDAlertViewHandler

@synthesize cachedVideoFileURLsArray = _cachedVideoFileURLsArray;

@synthesize videoProcessor;
@synthesize downloadAlert;

#pragma mark External Functions

- (id)initWithCachedVideoFileURLsArray:(NSMutableArray *)cachedVideoFileURLsArray {
    self = [super init];
    if (self) {
        self.cachedVideoFileURLsArray = cachedVideoFileURLsArray;
    }
    return self;
}

- (void)showAlert {
    downloadAlert = [[UIAlertView alloc]
                     initWithTitle:@"Universal Video Downloader"
                     message:@"Would you like to download this video?"
                     delegate:self
                     cancelButtonTitle:@"Dismiss"
                     otherButtonTitles:@"Download", nil];
    [downloadAlert show];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([_cachedVideoFileURLsArray count] > 0) {
        if (buttonIndex == 0) {
            [_cachedVideoFileURLsArray removeLastObject];
            
            [downloadAlert release];
        }
        else {
            BOOL initialErrorDidOccur = YES;
            
            if (_cachedVideoFileURLsArray) {
                if ([_cachedVideoFileURLsArray count] > 0) {
                    NSString *cachedVideoFileURLString = [NSString stringWithString:[_cachedVideoFileURLsArray lastObject]];
                    [_cachedVideoFileURLsArray removeLastObject];
                    if (cachedVideoFileURLString) {
                        if ([cachedVideoFileURLString length] > 0) {
                            NSURL *formattedCachedVideoFileURLString = [NSURL URLWithString:cachedVideoFileURLString];
                            if (formattedCachedVideoFileURLString) {
                                [self performSelectorInBackground:@selector(updateDownloadAlert) withObject:nil];
                                
                                videoProcessor = [[UVDVideoProcessor alloc]initWithDelegate:self];
                                [videoProcessor saveVideoAtURL:formattedCachedVideoFileURLString];
                                
                                initialErrorDidOccur = NO;
                            }
                        }
                    }
                }
            }
            
            if (initialErrorDidOccur) {
                [downloadAlert release];
                
                UIAlertView *errorAlert = [[UIAlertView alloc]
                                           initWithTitle:@"Error Reading Cached Video URL"
                                           message:@"The app encountered an error while trying to read the cached video URL. The app you are trying to download videos from may not be supported at this time."
                                           delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
                [errorAlert show];
                [errorAlert release];
            }
        }
    }
    else {
        [downloadAlert release];
        
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Error Reading Cached Video URLs"
                                   message:@"The app encountered an error while trying to read the cached video URLs. The app you are trying to download videos from may not be supported at this time."
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
    }
}

#pragma mark -
#pragma mark VideoProcessorDelegate

- (void)videoProcessorDidFinishProcessing {
    if (videoProcessor) {
        [videoProcessor release];
        videoProcessor = nil;
    }
    
    [downloadAlert release];
}

#pragma mark -
#pragma mark Internal Functions

- (void)updateDownloadAlert {
    // An autorelease pool is necessary here to prevent the app from leaking memory when it is running this code in the background thread.
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    
    downloadAlert.message = @"     Loading...";
    
    UIActivityIndicatorView *loadingActivityIndicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    loadingActivityIndicatorView.frame = CGRectMake(92, 56, 20, 20);
    [downloadAlert addSubview:loadingActivityIndicatorView];
    [loadingActivityIndicatorView startAnimating];
    [loadingActivityIndicatorView release];
    
    [pool release];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [super dealloc];
}

@end
