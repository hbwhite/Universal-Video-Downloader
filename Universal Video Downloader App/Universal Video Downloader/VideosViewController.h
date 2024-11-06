//
//  VideosViewController.h
//  Universal Video Downloader
//
//  Created by Harrison White on 3/18/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "TextInputViewController.h"
#import "MoviePlayerViewController.h"

@class MBProgressHUD;

@interface VideosViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, TextInputViewControllerDelegate, MoviePlayerViewControllerDelegate> {
    IBOutlet UITableView *theTableView;
    UIBarButtonItem *editButton;
    UIBarButtonItem *doneButton;
    NSDecimalNumberHandler *decimalNumberHandler;
    NSMutableString *pendingVideoFolderName;
    BOOL isAdObserver;
}

@property (nonatomic, retain) IBOutlet UITableView *theTableView;
@property (nonatomic, retain) UIBarButtonItem *editButton;
@property (nonatomic, retain) UIBarButtonItem *doneButton;
@property (nonatomic, retain) NSDecimalNumberHandler *decimalNumberHandler;
@property (nonatomic, retain) NSMutableString *pendingVideoFolderName;
@property (readwrite) BOOL isAdObserver;

- (void)editButtonPressed;
- (void)doneButtonPressed;

- (void)editButtonAction;
- (void)doneButtonAction;
- (NSArray *)videos;
- (NSString *)pathForFileWithName:(NSString *)fileName;
- (void)adDidShow;
- (void)adDidHide;
- (NSString *)stringFromDecimalNumber:(NSDecimalNumber *)decimalNumber;
- (BOOL)isAirPlaySupported;
- (void)deleteVideoWithParameters:(NSArray *)parameters;

@end
