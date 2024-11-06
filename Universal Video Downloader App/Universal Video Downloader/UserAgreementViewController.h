//
//  UserAgreementViewController.h
//  Universal Video Downloader
//
//  Created by Harrison White on 3/18/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserAgreementViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UIBarButtonItem *declineButton;
    IBOutlet UIBarButtonItem *acceptButton;
    IBOutlet UITableView *theTableView;
}

@property (nonatomic, retain) IBOutlet UIBarButtonItem *declineButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *acceptButton;
@property (nonatomic, retain) IBOutlet UITableView *theTableView;

- (IBAction)declineButtonPressed;
- (IBAction)acceptButtonPressed;

@end
