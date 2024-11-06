//
//  DownloadCell.m
//  Universal Video Downloader
//
//  Created by Harrison White on 2/18/11.
//  Copyright 2011 Harrison Apps, LLC. All rights reserved.
//

#import "DownloadCell.h"

@implementation DownloadCell

@synthesize titleLabel;
@synthesize progressLabel;
@synthesize progressView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code.
		
		titleLabel = [[UILabel alloc]init];
        titleLabel.numberOfLines = 2;
		titleLabel.font = [UIFont boldSystemFontOfSize:17];
		titleLabel.textColor = [UIColor blackColor];
		titleLabel.backgroundColor = [UIColor clearColor];
		titleLabel.highlightedTextColor = [UIColor whiteColor];
		[self addSubview:titleLabel];
        
        progressLabel = [[UILabel alloc]init];
        progressLabel.font = [UIFont boldSystemFontOfSize:12];
		progressLabel.backgroundColor = [UIColor clearColor];
        progressLabel.highlightedTextColor = [UIColor whiteColor];
        [self addSubview:progressLabel];
        
		progressView = [[UIProgressView alloc]init];
		[self addSubview:progressView];
        
        if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            titleLabel.frame = CGRectMake(10, 6, 300, 44);
            progressLabel.frame = CGRectMake(10, 50, 300, 20);
            progressView.frame = CGRectMake(10, 70, 300, 9);
        }
        else {
            titleLabel.frame = CGRectMake(10, 6, 748, 44);
            progressLabel.frame = CGRectMake(10, 50, 748, 20);
            progressView.frame = CGRectMake(10, 70, 748, 9);
        }
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	
	[super setSelected:selected animated:animated];
	
    // Configure the view for the selected state
}

- (void)dealloc {
	[titleLabel release];
    [progressLabel release];
	[progressView release];
    [super dealloc];
}

@end
