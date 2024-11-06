//
//  DownloadsViewController.m
//  Universal Video Downloader
//
//  Created by Harrison White on 3/18/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import "DownloadsViewController.h"
#import "AppDelegate.h"
#import "RootViewController.h"

@implementation DownloadsViewController

@synthesize isAdObserver;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
	self.view.frame = delegate.window.frame;
    [self.view addSubview:delegate.theTableView];
}

- (void)adDidShow {
    UITableView *theTableView = [(AppDelegate *)[[UIApplication sharedApplication]delegate]theTableView];
    if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if ([[UIScreen mainScreen]bounds].size.height == 568) {
            theTableView.frame = CGRectMake(0, 0, 320, 425);
        }
        else {
            theTableView.frame = CGRectMake(0, 0, 320, 337);
        }
    }
    else {
        theTableView.frame = CGRectMake(0, 0, 768, 841);
    }
}

- (void)adDidHide {
    UITableView *theTableView = [(AppDelegate *)[[UIApplication sharedApplication]delegate]theTableView];
    if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if ([[UIScreen mainScreen]bounds].size.height == 568) {
            theTableView.frame = CGRectMake(0, 0, 320, 475);
        }
        else {
            theTableView.frame = CGRectMake(0, 0, 320, 387);
        }
    }
    else {
        theTableView.frame = CGRectMake(0, 0, 768, 931);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    if (!delegate.viewIsVisible) {
        delegate.viewIsVisible = YES;
    }
    
    [delegate updateDownloadElements];
    
    if (!isAdObserver) {
        isAdObserver = YES;
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(adDidShow) name:kAdDidShowNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(adDidHide) name:kAdDidHideNotification object:nil];
    }
    if (((RootViewController *)self.tabBarController).bannerViewContainer.hidden) {
        [self adDidHide];
    }
    else {
        [self adDidShow];
    }
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    if (delegate.viewIsVisible) {
        delegate.viewIsVisible = NO;
        
        if (delegate.downloadUpdateTimer) {
            if ([delegate.downloadUpdateTimer isValid]) {
                [delegate.downloadUpdateTimer invalidate];
            }
            delegate.downloadUpdateTimer = nil;
        }
    }
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// iOS 6 Rotation Methods

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
    [super dealloc];
}

@end
