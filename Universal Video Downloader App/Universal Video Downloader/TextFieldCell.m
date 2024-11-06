//
//  TextFieldCell.m
//  Universal Video Downloader
//
//  Created by Harrison White on 10/1/11.
//  Copyright (c) 2012 Harrison Apps, LLC 2011 Harrison Apps, LLC. All rights reserved.
//

#import "TextFieldCell.h"

#define TEXT_COLOR_RED		(46.0 / 255.0)
#define TEXT_COLOR_GREEN    (65.0 / 255.0)
#define TEXT_COLOR_BLUE		(118.0 / 255.0)

@implementation TextFieldCell

@synthesize textField;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
		
		textField = [[UITextField alloc]init];
        if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            textField.frame = CGRectMake(0, 0, 280, 23);
        }
        else {
            textField.frame = CGRectMake(0, 0, 658, 23);
        }
		textField.borderStyle = UITextBorderStyleNone;
		textField.font = [UIFont systemFontOfSize:18];
		textField.textColor = [UIColor colorWithRed:TEXT_COLOR_RED green:TEXT_COLOR_GREEN blue:TEXT_COLOR_BLUE alpha:1];
		textField.clearButtonMode = UITextFieldViewModeAlways;
		textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.accessoryView = textField;
		
		self.textLabel.backgroundColor = [UIColor clearColor];
		self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
	[textField release];
	[super dealloc];
}

@end
