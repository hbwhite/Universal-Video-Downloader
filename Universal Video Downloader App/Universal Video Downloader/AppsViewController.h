//
//  AppsViewController.h
//  Universal Video Downloader
//
//  Created by Harrison White on 3/18/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ALApplicationList;

enum {
    kAppListStateUnknown = 0,
    kAppListStateFunctional,
    kAppListStateNotFunctional
};
typedef NSUInteger kAppListState;

@interface AppsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UITableView *theTableView;
    UIBarButtonItem *refreshButton;
    NSMutableArray *appsArray;
    BOOL refreshingApps;
    BOOL isAdObserver;
    
    ALApplicationList *applicationList;
    kAppListState appListState;
}

@property (nonatomic, retain) IBOutlet UITableView *theTableView;
@property (nonatomic, retain) UIBarButtonItem *refreshButton;
@property (nonatomic, retain) NSMutableArray *appsArray;
@property (readwrite) BOOL refreshingApps;
@property (readwrite) BOOL isAdObserver;

@property (nonatomic, retain) ALApplicationList *applicationList;
@property (nonatomic) kAppListState appListState;

- (void)adDidShow;
- (void)adDidHide;
- (void)refreshButtonPressed;
- (void)refreshApps:(BOOL)enabled;
- (void)_refreshApps:(NSNumber *)enabled;
- (ALApplicationList *)applicationList;
- (NSDictionary *)applications;

@end
