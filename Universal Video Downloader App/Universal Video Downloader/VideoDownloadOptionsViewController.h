//
//  VideoDownloadOptionsViewController.h
//  Universal Video Downloader
//
//  Created by Harrison White on 2/17/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VideoDownloadOptionsViewControllerDelegate;

@interface VideoDownloadOptionsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
@public
    id <VideoDownloadOptionsViewControllerDelegate> delegate;
@private
    IBOutlet UINavigationBar *theNavigationBar;
    IBOutlet UIBarButtonItem *cancelButton;
    IBOutlet UIBarButtonItem *downloadButton;
    IBOutlet UITableView *theTableView;
    
    NSInteger selectedAudioTrackIndex;
    NSInteger selectedVideoIndex;
    
    BOOL didInitiallyAssignFirstResponder;
}

@property (nonatomic, assign) id <VideoDownloadOptionsViewControllerDelegate> delegate;

@end

@protocol VideoDownloadOptionsViewControllerDelegate <NSObject>

@required

- (BOOL)videoDownloadOptionsViewControllerPendingVideoIsVideoStream;
- (NSDictionary *)videoDownloadOptionsViewControllerVideoFileURLsDictionary;
- (NSArray *)videoDownloadOptionsViewControllerVideoFiles;

@optional

- (NSArray *)videoDownloadOptionsViewControllerAudioTracks;
- (void)videoDownloadOptionsViewControllerDidCancel;
- (void)videoDownloadOptionsViewControllerDidSelectOptionsWithVideoTitle:(NSString *)videoTitle audioTrackIndex:(NSInteger)audioTrackIndex videoFileIndex:(NSInteger)videoFileIndex;

@end
