//
//  DownloadsViewController.h
//  Universal Video Downloader
//
//  Created by Harrison White on 3/18/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DownloadsViewController : UIViewController {
    BOOL isAdObserver;
}

@property (readwrite) BOOL isAdObserver;

- (void)adDidShow;
- (void)adDidHide;

@end
