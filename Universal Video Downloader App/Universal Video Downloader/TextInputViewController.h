//
//  TextInputViewController.h
//  Universal Video Downloader
//
//  Created by Harrison White on 2/17/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TextInputViewControllerDelegate;

@interface TextInputViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
    id <TextInputViewControllerDelegate> delegate;
    
    IBOutlet UINavigationBar *theNavigationBar;
    IBOutlet UIBarButtonItem *cancelButton;
    IBOutlet UIBarButtonItem *doneButton;
    IBOutlet UITableView *theTableView;
}

@property (nonatomic, assign) id <TextInputViewControllerDelegate> delegate;

@property (nonatomic, retain) IBOutlet UINavigationBar *theNavigationBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, retain) IBOutlet UITableView *theTableView;

@end

@protocol TextInputViewControllerDelegate <NSObject>

@required

- (NSString *)textInputViewControllerNavigationBarTitle;
- (NSString *)textInputViewControllerHeader;
- (NSString *)textInputViewControllerPlaceholder;
- (NSString *)textInputViewControllerDefaultText;
- (UIViewController *)textInputViewControllerParentViewController;

@optional

- (void)textInputViewControllerDidReceiveTextInput:(NSString *)text;

@end
