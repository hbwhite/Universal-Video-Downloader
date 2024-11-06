//
//  RootViewController.m
//  Universal Video Downloader
//
//  Created by Harrison White on 3/18/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import "RootViewController.h"
#import "AppDelegate.h"
#import "VideosViewController.h"
#import "DownloadsViewController.h"
#import "AppsViewController.h"
#import "SettingsViewController.h"
#import "HelpViewController.h"
#import "MoviePlayerViewController.h"

#define IPHONE_AD_WIDTH_IN_PIXELS   320
#define IPHONE_AD_HEIGHT_IN_PIXELS  50

#define IPAD_AD_WIDTH_IN_PIXELS     768
#define IPAD_AD_HEIGHT_IN_PIXELS    90

@implementation RootViewController

@synthesize bannerViewContainer;
@synthesize bannerView;

#pragma mark - View lifecycle

- (id)init {
    self = [super init];
    if (self) {
        // Using a loop here helps to define different instances of UINavigationController while reusing the generic variable name "navigationController".
        for (int i = 0; i < 5; i++) {
            if (i == 0) {
                VideosViewController *videosViewController = nil;
                
                if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                    if ([[UIScreen mainScreen]bounds].size.height == 568) {
                        videosViewController = [[VideosViewController alloc]initWithNibName:@"VideosViewController_iPhone568" bundle:nil];
                    }
                    else {
                        videosViewController = [[VideosViewController alloc]initWithNibName:@"VideosViewController_iPhone" bundle:nil];
                    }
                }
                else {
                    videosViewController = [[VideosViewController alloc]initWithNibName:@"VideosViewController_iPad" bundle:nil];
                }
                
                videosViewController.title = NSLocalizedString(@"Videos", @"Videos");
                
                UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:videosViewController];
                navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
                navigationController.tabBarItem.title = NSLocalizedString(@"Videos", @"Videos");
                navigationController.tabBarItem.image = [UIImage imageNamed:@"Videos"];
                
                [videosViewController release];
                
                self.viewControllers = [NSArray arrayWithObject:navigationController];
                
                [navigationController release];
            }
            else if (i == 1) {
                DownloadsViewController *downloadsViewController = nil;
                
                if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                    if ([[UIScreen mainScreen]bounds].size.height == 568) {
                        downloadsViewController = [[DownloadsViewController alloc]initWithNibName:@"DownloadsViewController_iPhone568" bundle:nil];
                    }
                    else {
                        downloadsViewController = [[DownloadsViewController alloc]initWithNibName:@"DownloadsViewController_iPhone" bundle:nil];
                    }
                }
                else {
                    downloadsViewController = [[DownloadsViewController alloc]initWithNibName:@"DownloadsViewController_iPad" bundle:nil];
                }
                
                downloadsViewController.title = NSLocalizedString(@"Downloads", @"Downloads");
                
                UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:downloadsViewController];
                navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
                
                [downloadsViewController release];
                
                UITabBarItem *tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemDownloads tag:0];
                tabBarItem.title = NSLocalizedString(@"Downloads", @"Downloads");
                navigationController.tabBarItem = tabBarItem;
                [tabBarItem release];
                
                self.viewControllers = [self.viewControllers arrayByAddingObject:navigationController];
                
                [navigationController release];
            }
            else if (i == 2) {
                AppsViewController *appsViewController = nil;
                
                if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                    if ([[UIScreen mainScreen]bounds].size.height == 568) {
                        appsViewController = [[AppsViewController alloc]initWithNibName:@"AppsViewController_iPhone568" bundle:nil];
                    }
                    else {
                        appsViewController = [[AppsViewController alloc]initWithNibName:@"AppsViewController_iPhone" bundle:nil];
                    }
                }
                else {
                    appsViewController = [[AppsViewController alloc]initWithNibName:@"AppsViewController_iPad" bundle:nil];
                }
                
                appsViewController.title = NSLocalizedString(@"Apps", @"Apps");
                
                UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:appsViewController];
                navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
                navigationController.tabBarItem.title = NSLocalizedString(@"Apps", @"Apps");
                navigationController.tabBarItem.image = [UIImage imageNamed:@"Apps"];
                
                [appsViewController release];
                
                self.viewControllers = [self.viewControllers arrayByAddingObject:navigationController];
                
                [navigationController release];
            }
            else if (i == 3) {
                SettingsViewController *settingsViewController = nil;
                
                if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                    if ([[UIScreen mainScreen]bounds].size.height == 568) {
                        settingsViewController = [[SettingsViewController alloc]initWithNibName:@"SettingsViewController_iPhone568" bundle:nil];
                    }
                    else {
                        settingsViewController = [[SettingsViewController alloc]initWithNibName:@"SettingsViewController_iPhone" bundle:nil];
                    }
                }
                else {
                    settingsViewController = [[SettingsViewController alloc]initWithNibName:@"SettingsViewController_iPad" bundle:nil];
                }
                
                settingsViewController.title = NSLocalizedString(@"Settings", @"Settings");
                
                UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:settingsViewController];
                navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
                navigationController.tabBarItem.title = NSLocalizedString(@"Settings", @"Settings");
                navigationController.tabBarItem.image = [UIImage imageNamed:@"Settings"];
                
                [settingsViewController release];
                
                self.viewControllers = [self.viewControllers arrayByAddingObject:navigationController];
                
                [navigationController release];
            }
            else {
                HelpViewController *helpViewController = nil;
                
                if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                    if ([[UIScreen mainScreen]bounds].size.height == 568) {
                        helpViewController = [[HelpViewController alloc]initWithNibName:@"HelpViewController_iPhone568" bundle:nil];
                    }
                    else {
                        helpViewController = [[HelpViewController alloc]initWithNibName:@"HelpViewController_iPhone" bundle:nil];
                    }
                }
                else {
                    helpViewController = [[HelpViewController alloc]initWithNibName:@"HelpViewController_iPad" bundle:nil];
                }
                
                helpViewController.title = NSLocalizedString(@"Help", @"Help");
                
                UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:helpViewController];
                navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
                navigationController.tabBarItem.title = NSLocalizedString(@"Help", @"Help");
                navigationController.tabBarItem.image = [UIImage imageNamed:@"Help"];
                
                [helpViewController release];
                
                self.viewControllers = [self.viewControllers arrayByAddingObject:navigationController];
                
                [navigationController release];
            }
        }
        
        bannerViewContainer = [[UIView alloc]init];
        bannerViewContainer.hidden = YES;
        bannerViewContainer.backgroundColor = [UIColor whiteColor];
        
        bannerView = [[GADBannerView alloc]init];
        bannerView.adUnitID = kAdUnitID;
        bannerView.delegate = self;
        bannerView.rootViewController = self;
        
        if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            if ([[UIScreen mainScreen]bounds].size.height == 568) {
                bannerView.frame = CGRectMake(0, 0, IPHONE_AD_WIDTH_IN_PIXELS, IPHONE_AD_HEIGHT_IN_PIXELS);
                bannerViewContainer.frame = CGRectMake(0, (self.view.frame.size.height - (self.tabBar.frame.size.height + IPHONE_AD_HEIGHT_IN_PIXELS)), bannerView.frame.size.width, bannerView.frame.size.height);
            }
            else {
                bannerView.frame = CGRectMake(0, 0, IPHONE_AD_WIDTH_IN_PIXELS, IPHONE_AD_HEIGHT_IN_PIXELS);
                bannerViewContainer.frame = CGRectMake(0, (self.view.frame.size.height - (self.tabBar.frame.size.height + IPHONE_AD_HEIGHT_IN_PIXELS)), bannerView.frame.size.width, bannerView.frame.size.height);
            }
        }
        else {
            bannerView.frame = CGRectMake(0, 0, IPAD_AD_WIDTH_IN_PIXELS, IPAD_AD_HEIGHT_IN_PIXELS);
            bannerViewContainer.frame = CGRectMake(0, (self.view.frame.size.height - (self.tabBar.frame.size.height + IPAD_AD_HEIGHT_IN_PIXELS)), 768, bannerView.frame.size.height);
        }
        
        [bannerViewContainer addSubview:bannerView];
        
        [self.view addSubview:bannerViewContainer];
        
        GADRequest *request = [GADRequest request];
        [bannerView loadRequest:request];
    }
    return self;
}

- (void)adViewDidReceiveAd:(GADBannerView *)view {
    bannerViewContainer.hidden = NO;
	[[NSNotificationCenter defaultCenter]postNotificationName:kAdDidShowNotification object:nil];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
	[[NSNotificationCenter defaultCenter]postNotificationName:kAdDidHideNotification object:nil];
	bannerViewContainer.hidden = YES;
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
    
    self.bannerViewContainer = nil;
    self.bannerView = nil;
}

- (void)dealloc {
    [bannerViewContainer release];
    [bannerView release];
    [super dealloc];
}

@end
