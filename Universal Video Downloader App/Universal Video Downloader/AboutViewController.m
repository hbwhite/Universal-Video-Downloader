//
//  AboutViewController.m
//  Universal Video Downloader
//
//  Created by Harrison White on 3/18/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import "AboutViewController.h"
#import "RootViewController.h"

@implementation AboutViewController

@synthesize theTableView;
@synthesize isAdObserver;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)adDidShow {
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
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

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Universal Video Downloader";
        case 1:
            return @"Copyright © 2012 Harrison Apps, LLC\nAll rights reserved.";
        case 2:
            return @"-----";
        case 3:
            return @"THE FOLLOWING SETS FORTH ATTRIBUTION NOTICES FOR THIRD PARTY SOFTWARE THAT MAY BE CONTAINED IN PORTIONS OF THE UNIVERSAL VIDEO DOWNLOADER PRODUCT.";
        case 4:
            return @"-----";
        case 5:
            return @"The following software may be included in this product: ASIHTTPRequest. This software contains the following license and notice below:";
        case 6:
            return @"Copyright (c) 2007-2011, All-Seeing Interactive\nAll rights reserved.";
        case 7:
            return @"Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:\n* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.\n* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.\n* Neither the name of the All-Seeing Interactive nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.";
        case 8:
            return @"THIS SOFTWARE IS PROVIDED BY All-Seeing Interactive ''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL All-Seeing Interactive BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.";
        case 9:
            return @"-----";
        case 10:
            return @"The following software may be included in this product: Reachability. This software contains the following license and notice below:";
        case 11:
            return @"Version: 2.0.4ddg";
        case 12:
            return @"-----";
        case 13:
            return @"Significant additions made by Andrew W. Donoho, August 11, 2009.\nThis is a derived work of Apple's Reachability v2.0 class.";
        case 14:
            return @"The below license is the new BSD license with the OSI recommended personalizations.\n<http://www.opensource.org/licenses/bsd-license.php>";
        case 15:
            return @"Extensions Copyright (C) 2009 Donoho Design Group, LLC. All Rights Reserved.";
        case 16:
            return @"Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:";
        case 17:
            return @"* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.";
        case 18:
            return @"* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.";
        case 19:
            return @"* Neither the name of Andrew W. Donoho nor Donoho Design Group, L.L.C. may be used to endorse or promote products derived from this software without specific prior written permission.";
        case 20:
            return @"THIS SOFTWARE IS PROVIDED BY DONOHO DESIGN GROUP, L.L.C. \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.";
        case 21:
            return @"-----";
        case 22:
            return @"Apple's Original License on Reachability v2.0";
        case 23:
            return @"Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. (\"Apple\") in consideration of your agreement to the following terms, and your use, installation, modification or redistribution of this Apple software constitutes acceptance of these terms.  If you do not agree with these terms, please do not use, install, modify or redistribute this Apple software.";
        case 24:
            return @"In consideration of your agreement to abide by the following terms, and subject to these terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in this original Apple software (the \"Apple Software\"), to use, reproduce, modify and redistribute the Apple Software, with or without modifications, in source and/or binary forms; provided that if you redistribute the Apple Software in its entirety and without modifications, you must retain this notice and the following text and disclaimers in all such redistributions of the Apple Software.";
        case 25:
            return @"Neither the name, trademarks, service marks or logos of Apple Inc. may be used to endorse or promote products derived from the Apple Software without specific prior written permission from Apple.  Except as expressly stated in this notice, no other rights or licenses, express or implied, are granted by Apple herein, including but not limited to any patent rights that may be infringed by your derivative works or by other works in which the Apple Software may be incorporated.";
        case 26:
            return @"The Apple Software is provided by Apple on an \"AS IS\" basis.  APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.";
        case 27:
            return @"IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.";
        case 28:
            return @"Copyright (C) 2009 Apple Inc. All Rights Reserved.";
        case 29:
            return @"-----";
        case 30:
            return @"The following software may be included in this product: CocoaHTTPServer. This software contains the following license and notice below:";
        case 31:
            return @"Software License Agreement (BSD License)";
        case 32:
            return @"Copyright (c) 2011, Deusty, LLC\nAll rights reserved.";
        case 33:
            return @"Redistribution and use of this software in source and binary forms, with or without modification, are permitted provided that the following conditions are met:";
        case 34:
            return @"* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.";
        case 35:
            return @"* Neither the name of Deusty nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission of Deusty, LLC.";
        case 36:
            return @"THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.";
        case 37:
            return @"-----";
        case 38:
            return @"The following software may be included in this product: MultipartMessageHeader. This software contains the following license and notice below:";
        case 39:
            return @"Created by Валерий Гаврилов on 29.03.12.\nCopyright (c) 2012 LLC \"Online Publishing Partners\" (onlinepp.ru). All rights reserved.";
        case 40:
            return @"-----";
        case 41:
            return @"The following software may be included in this product: MultipartMessagePart. This software contains the following license and notice below:";
        case 42:
            return @"Created by Валерий Гаврилов on 29.03.12.\nCopyright (c) 2012 LLC \"Online Publishing Partners\" (onlinepp.ru). All rights reserved.";
        case 43:
            return @"-----";
        case 44:
            return @"The following software may be included in this product: MBProgressHUD. This software contains the following license and notice below:";
        case 45:
            return @"Version 0.5\nCreated by Matej Bukovinski on 2.4.09.";
        case 46:
            return @"This code is distributed under the terms and conditions of the MIT license. ";
        case 47:
            return @"Copyright (c) 2011 Matej Bukovinski";
        case 48:
            return @"Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:";
        case 49:
            return @"The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.";
        case 50:
            return @"THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.";
        case 51:
            return @"-----";
        default:
            return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 52;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier]autorelease];
    }
    
    // Configure the cell...
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
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
    
    self.theTableView = nil;
}

- (void)dealloc {
    [theTableView release];
    [super dealloc];
}

@end
