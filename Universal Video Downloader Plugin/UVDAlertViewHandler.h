//
//  UVDAlertViewHandler.h
//  Universal Video Downloader
//
//  Created by Harrison White on 7/25/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UVDVideoProcessor.h"

@class UVDVideoProcessor;

@interface UVDAlertViewHandler : NSObject <UIAlertViewDelegate, UVDVideoProcessorDelegate> {
@private
    NSMutableArray *_cachedVideoFileURLsArray;
    
    UVDVideoProcessor *videoProcessor;
    UIAlertView *downloadAlert;
}

@property (nonatomic, assign) NSMutableArray *cachedVideoFileURLsArray;

- (id)initWithCachedVideoFileURLsArray:(NSMutableArray *)cachedVideoFileURLsArray;
- (void)showAlert;

@end
