//
//  HelpViewController.h
//  Universal Video Downloader
//
//  Created by Harrison White on 3/18/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelpViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UITableView *theTableView;
    BOOL isAdObserver;
}

@property (nonatomic, retain) IBOutlet UITableView *theTableView;
@property (readwrite) BOOL isAdObserver;

- (void)adDidShow;
- (void)adDidHide;

@end
