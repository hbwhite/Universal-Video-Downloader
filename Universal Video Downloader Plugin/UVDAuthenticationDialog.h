//
//  UVDAuthenticationDialog.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 21/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class UVDHTTPRequest;

typedef enum _UVDAuthenticationType {
	UVDStandardAuthenticationType = 0,
    UVDProxyAuthenticationType = 1
} UVDAuthenticationType;

@interface UVDAutorotatingViewController : UIViewController
@end

@interface UVDAuthenticationDialog : UVDAutorotatingViewController <UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource> {
	UVDHTTPRequest *request;
	UVDAuthenticationType type;
	UITableView *tableView;
	UIViewController *presentingController;
	BOOL didEnableRotationNotifications;
}
+ (void)presentAuthenticationDialogForRequest:(UVDHTTPRequest *)request;
+ (void)dismiss;

@property (retain) UVDHTTPRequest *request;
@property (assign) UVDAuthenticationType type;
@property (assign) BOOL didEnableRotationNotifications;
@property (retain, nonatomic) UIViewController *presentingController;
@end
