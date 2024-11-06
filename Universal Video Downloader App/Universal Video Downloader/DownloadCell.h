//
//  DownloadCell.h
//  Universal Video Downloader
//
//  Created by Harrison White on 2/18/11.
//  Copyright 2011 Harrison Apps, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DownloadCell : UITableViewCell {
	UILabel *titleLabel;
    UILabel *progressLabel;
	UIProgressView *progressView;
}

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *progressLabel;
@property (nonatomic, retain) UIProgressView *progressView;

@end
