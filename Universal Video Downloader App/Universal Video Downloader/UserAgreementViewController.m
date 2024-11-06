//
//  UserAgreementViewController.m
//  Universal Video Downloader
//
//  Created by Harrison White on 3/18/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import "UserAgreementViewController.h"
#import "AppDelegate.h"
#import "RootViewController.h"

static NSString *kDidAcceptUserAgreementKey = @"Did Accept User Agreement";

@implementation UserAgreementViewController

@synthesize declineButton;
@synthesize acceptButton;
@synthesize theTableView;

- (IBAction)declineButtonPressed {
    exit(0);
}

- (IBAction)acceptButtonPressed {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kDidAcceptUserAgreementKey];
    [defaults synchronize];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    // Modified to use iOS 5's new modal view controller functions when possible.
    RootViewController *rootViewController = appDelegate.rootViewController;
    if ([rootViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [rootViewController dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [rootViewController dismissModalViewControllerAnimated:YES];
    }
    
    [appDelegate runBasicSetup];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
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
            return @"\nEND USER LICENSE AGREEMENT";
        case 1:
            return @"\nThis copy of Universal Video Downloader (\"the Software Product\") and accompanying documentation is licensed and not sold. This Software Product is protected by copyright laws and treaties, as well as laws and treaties related to other forms of intellectual property. Harrison Apps, LLC or its subsidiaries, affiliates, and suppliers (collectively \"Harrison Apps, LLC\") own intellectual property rights in the Software Product. The Licensee's (\"you\" or \"your\") license to download, use, copy, or change the Software Product is subject to these rights and to all the terms and conditions of this End User License Agreement (\"Agreement\").";
        case 2:
            return @"Acceptance\nYOU ACCEPT AND AGREE TO BE BOUND BY THE TERMS OF THIS AGREEMENT BY SELECTING THE \"ACCEPT\" OPTION AND DOWNLOADING THE SOFTWARE PRODUCT OR BY INSTALLING, USING, OR COPYING THE SOFTWARE PRODUCT. YOU MUST AGREE TO ALL OF THE TERMS OF THIS AGREEMENT BEFORE YOU WILL BE ALLOWED TO DOWNLOAD THE SOFTWARE PRODUCT. IF YOU DO NOT AGREE TO ALL OF THE TERMS OF THIS AGREEMENT, YOU MUST SELECT \"DECLINE\" AND YOU MUST NOT INSTALL, USE, OR COPY THE SOFTWARE PRODUCT.";
        case 3:
            return @"License Grant\nThis Agreement entitles you to install and use one copy of the Software Product. In addition, you may make one archival copy of the Software Product. The archival copy must be on a storage medium other than a hard drive, and may only be used for the reinstallation of the Software Product. This Agreement does not permit the installation or use of multiple copies of the Software Product, or the installation of the Software Product on more than one computer at any given time, on a system that allows shared used of applications, on a multi-user network, or on any configuration or system of computers that allows multiple users. Multiple copy use or installation is only allowed if you obtain an appropriate licensing agreement for each user and each copy of the Software Product.";
        case 4:
            return @"Restrictions on Transfer\nWithout first obtaining the express written consent of Harrison Apps, LLC, you may not assign your rights and obligations under this Agreement, or redistribute, encumber, sell, rent, lease, sublicense, or otherwise transfer your rights to the Software Product.";
        case 5:
            return @"Restrictions on Use\nYou may not use, copy, or install the Software Product on any system with more than one computer, or permit the use, copying, or installation of the Software Product by more than one user or on more than one computer. If you hold multiple, validly licensed copies, you may not use, copy, or install the Software Product on any system with more than the number of computers permitted by license, or permit the use, copying, or installation by more users, or on more computers than the number permitted by license.";
        case 6:
            return @"You may not decompile, \"reverse-engineer\", disassemble, or otherwise attempt to derive the source code for the Software Product.";
        case 7:
            return @"You may not use the Software Product to download copyrighted material.";
        case 8:
            return @"Restrictions on Alteration\nYou may not modify the Software Product or create any derivative work of the Software Product or its accompanying documentation. Derivative works include but are not limited to translations. You may not alter any files or libraries in any portion of the Software Product.";
        case 9:
            return @"Restrictions on Copying\nYou may not copy any part of the Software Product except to the extent that licensed use inherently demands the creation of a temporary copy stored in computer memory and not permanently affixed on storage medium. You may make one archival copy which must be stored on a medium other than a computer hard drive.";
        case 10:
            return @"Disclaimer of Warranties and Limitation of Liability\nUNLESS OTHERWISE EXPLICITLY AGREED TO IN WRITING BY HARRISON APPS, LLC, HARRISON APPS, LLC MAKES NO OTHER WARRANTIES, EXPRESS OR IMPLIED, IN FACT OR IN LAW, INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE OTHER THAN AS SET FORTH IN THIS AGREEMENT OR IN THE LIMITED WARRANTY DOCUMENTS PROVIDED WITH THE SOFTWARE PRODUCT.";
        case 11:
            return @"Harrison Apps, LLC makes no warranty that the Software Product will meet your requirements or operate under your specific conditions of use. Harrison Apps, LLC makes no warranty that operation of the Software Product will be secure, error free, or free from interruption. YOU MUST DETERMINE WHETHER THE SOFTWARE PRODUCT SUFFICIENTLY MEETS YOUR REQUIREMENTS FOR SECURITY AND UNINTERRUPTABILITY. YOU BEAR SOLE RESPONSIBILITY AND ALL LIABILITY FOR ANY LOSS INCURRED DUE TO FAILURE OF THE SOFTWARE PRODUCT TO MEET YOUR REQUIREMENTS. HARRISON APPS, LLC WILL NOT, UNDER ANY CIRCUMSTANCES, BE RESPONSIBLE OR LIABLE FOR THE LOSS OF DATA ON ANY COMPUTER OR INFORMATION STORAGE DEVICE.";
        case 12:
            return @"UNDER NO CIRCUMSTANCES SHALL HARRISON APPS, LLC, ITS DIRECTORS, OFFICERS, EMPLOYEES OR AGENTS BE LIABLE TO YOU OR ANY OTHER PARTY FOR INDIRECT, CONSEQUENTIAL, SPECIAL, INCIDENTAL, PUNITIVE, OR EXEMPLARY DAMAGES OF ANY KIND (INCLUDING LOST REVENUES OR PROFITS OR LOSS OF BUSINESS) RESULTING FROM THIS AGREEMENT, OR FROM THE FURNISHING, PERFORMANCE, INSTALLATION, OR USE OF THE SOFTWARE PRODUCT, WHETHER DUE TO A BREACH OF CONTRACT, BREACH OF WARRANTY, OR THE NEGLIGENCE OF HARRISON APPS, LLC OR ANY OTHER PARTY, EVEN IF HARRISON APPS, LLC IS ADVISED BEFOREHAND OF THE POSSIBILITY OF SUCH DAMAGES. TO THE EXTENT THAT THE APPLICABLE JURISDICTION LIMITS HARRISON APPS, LLC'S ABILITY TO DISCLAIM ANY IMPLIED WARRANTIES, THIS DISCLAIMER SHALL BE EFFECTIVE TO THE MAXIMUM EXTENT PERMITTED.";
        case 13:
            return @"Limitation of Remedies and Damages\nYour remedy for a breach of this Agreement or of any warranty included in this Agreement is the correction or replacement of the Software Product. Selection of whether to correct or replace shall be solely at the discretion of Harrison Apps, LLC. Harrison Apps, LLC reserves the right to substitute a functionally equivalent copy of the Software Product as a replacement. If Harrison Apps, LLC is unable to provide a replacement or substitute Software Product or corrections to the Software Product, your sole alternate remedy shall be a refund of the purchase price for the Software Product exclusive of any costs for shipping and handling.";
        case 14:
            return @"Any claim must be made within the applicable warranty period. All warranties cover only defects arising under normal use and do not include malfunctions or failure resulting from misuse, abuse, neglect, alteration, problems with electrical power, acts of nature, unusual temperatures or humidity, improper installation, or damage determined by Harrison Apps, LLC to have been caused by you. All limited warranties on the Software Product are granted only to you and are non-transferable. You agree to indemnify and hold Harrison Apps, LLC harmless from all claims, judgments, liabilities, expenses, or costs arising from your breach of this Agreement and/or acts or omissions.";
        case 15:
            return @"Governing Law, Jurisdiction and Costs\nThis Agreement is governed by the laws of Iowa, without regard to Iowa's conflict or choice of law provisions.";
        case 16:
            return @"Severability\nIf any provision of this Agreement shall be held to be invalid or unenforceable, the remainder of this Agreement shall remain in full force and effect. To the extent any express or implied restrictions are not permitted by applicable laws, these express or implied restrictions shall remain in force and effect to the maximum extent permitted by such applicable laws.";
        case 17:
            return @"";
        default:
            return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 18;
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
    
    self.declineButton = nil;
    self.acceptButton = nil;
    self.theTableView = nil;
}

- (void)dealloc {
    [declineButton release];
    [acceptButton release];
    [theTableView release];
    [super dealloc];
}

@end
