//
//  RootViewController.h
//  Universal Video Downloader
//
//  Created by Harrison White on 3/18/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GADBannerView.h"

#define kAdDidShowNotification		@"kAdDidShowNotification"
#define kAdDidHideNotification	@"kAdDidHideNotification"

@interface RootViewController : UITabBarController <GADBannerViewDelegate> {
    UIView *bannerViewContainer;
	GADBannerView *bannerView;
}

@property (nonatomic, retain) UIView *bannerViewContainer;
@property (nonatomic, retain) GADBannerView *bannerView;

@end
