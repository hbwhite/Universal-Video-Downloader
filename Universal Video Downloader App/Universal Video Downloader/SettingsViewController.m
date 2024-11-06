//
//  SettingsViewController.m
//  Universal Video Downloader
//
//  Created by Harrison White on 3/18/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import "SettingsViewController.h"
#import "RootViewController.h"
#import "AboutViewController.h"
#import "SwitchCell.h"

static NSString *kFullQualityVideoOnlyKey           = @"Full Quality Video Only";
static NSString *kDefaultAudioTrackOnlyKey          = @"Default Audio Track Only";
static NSString *kResumeVideosKey                   = @"Resume Videos";
static NSString *kDownloadAlertsKey                 = @"Download Alerts Enabled";

static NSString *kFrequentlyAskedQuestionsURLStr    = @"http://www.harrisonapps.com/faq/universal-video-downloader";

static NSString *kRepoURLStr                        = @"http://www.harrisonapps.com/repo";
static NSString *kWebsiteURLStr                     = @"http://www.harrisonapps.com";
static NSString *kFacebookURLStr                    = @"http://www.facebook.com/harrisonapps";
static NSString *kTwitterURLStr                     = @"http://www.twitter.com/harrisonapps";

@implementation SettingsViewController

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
    if (section == 4) {
        return @"Frequently Asked Questions";
    }
    else if (section == 5) {
        return @"Support Us";
    }
    else {
        return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"When enabled, the app will always download videos in the highest available quality and ignore lower quality options. This greatly increases the speed of the application, saves RAM, and is highly recommended.";
    }
    else if (section == 1) {
        return @"When enabled, if applicable, the app will always download the default audio track for videos and ignore alternative languages. This increases the speed of the application and saves RAM.";
    }
    else if (section == 2) {
        return @"Allows you to continue watching videos where you left off.";
    }
    else if (section == 3) {
        return @"Notifies you when videos finish downloading if your device is locked or if the app is running in the background.";
    }
    else if (section == 4) {
        return @"Visit our Frequently Asked Questions page to get answers to common questions about this app.";
    }
    else if (section == 6) {
        // Final newline added to improve the appearance of the UI on firmwares earlier than iOS 6. A space is required if the newline is the last character for the newline itself to work.
        return @"\nCopyright © 2012 Harrison Apps, LLC\nAll rights reserved.\n ";
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 5) {
        return 4;
    }
    else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 4) {
        NSString *CellIdentifier = [NSString stringWithFormat:@"Cell %i", (indexPath.section + 1)];
        
        SwitchCell *cell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[SwitchCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier]autorelease];
        }
        
        // Configure the cell...
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if (indexPath.section == 0) {
            cell.textLabel.text = @"Full Quality Only";
            cell.imageView.image = [UIImage imageNamed:@"Full_Quality"];
            if ([cell.cellSwitch respondsToSelector:@selector(setOnTintColor:)]) {
                [cell.cellSwitch setOnTintColor:[UIColor orangeColor]];
            }
            cell.cellSwitch.on = [defaults boolForKey:kFullQualityVideoOnlyKey];
        }
        else if (indexPath.section == 1) {
            cell.textLabel.text = @"Default Audio";
            cell.imageView.image = [UIImage imageNamed:@"Default_Audio"];
            if ([cell.cellSwitch respondsToSelector:@selector(setOnTintColor:)]) {
                [cell.cellSwitch setOnTintColor:[UIColor orangeColor]];
            }
            cell.cellSwitch.on = [defaults boolForKey:kDefaultAudioTrackOnlyKey];
        }
        else if (indexPath.section == 2) {
            cell.textLabel.text = @"Resume Videos";
            cell.imageView.image = [UIImage imageNamed:@"Resume_Videos"];
            cell.cellSwitch.on = [defaults boolForKey:kResumeVideosKey];
        }
        else if (indexPath.section == 3) {
            cell.textLabel.text = @"Download Alerts";
            cell.imageView.image = [UIImage imageNamed:@"Alerts"];
            cell.cellSwitch.on = [defaults boolForKey:kDownloadAlertsKey];
        }
        cell.cellSwitch.tag = indexPath.section;
        [cell.cellSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        
        return cell;
    }
    else if (indexPath.section < 6) {
        NSString *CellIdentifier = [NSString stringWithFormat:@"Cell %i", (indexPath.section + 1)];
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier]autorelease];
        }
        
        // Configure the cell...
        
        if (indexPath.section == 4) {
            cell.textLabel.text = @"FAQ Page";
            cell.detailTextLabel.text = @"harrisonapps.com/faq";
            cell.imageView.image = [UIImage imageNamed:@"Help"];
            cell.imageView.highlightedImage = [UIImage imageNamed:@"Help-Selected"];
        }
        else {
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Add Our Repo";
                cell.detailTextLabel.text = @"harrisonapps.com/repo";
                cell.imageView.image = [UIImage imageNamed:@"Repo"];
                cell.imageView.highlightedImage = [UIImage imageNamed:@"Repo-Selected"];
            }
            else if (indexPath.row == 1) {
                cell.textLabel.text = @"Visit Our Website";
                cell.detailTextLabel.text = @"harrisonapps.com";
                cell.imageView.image = [UIImage imageNamed:@"Website"];
                cell.imageView.highlightedImage = [UIImage imageNamed:@"Website-Selected"];
            }
            else if (indexPath.row == 2) {
                cell.textLabel.text = @"Like Our Facebook Page";
                cell.detailTextLabel.text = @"facebook.com/harrisonapps";
                cell.imageView.image = [UIImage imageNamed:@"Facebook"];
                cell.imageView.highlightedImage = [UIImage imageNamed:@"Facebook-Selected"];
            }
            else {
                cell.textLabel.text = @"Follow Us on Twitter";
                cell.detailTextLabel.text = @"twitter.com/harrisonapps";
                cell.imageView.image = [UIImage imageNamed:@"Twitter"];
                cell.imageView.highlightedImage = [UIImage imageNamed:@"Twitter-Selected"];
            }
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        return cell;
    }
    else {
        NSString *CellIdentifier = @"Cell 7";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier]autorelease];
        }
        
        // Configure the cell...
        
        cell.textLabel.text = @"About";
        cell.imageView.image = [UIImage imageNamed:@"About"];
        cell.imageView.highlightedImage = [UIImage imageNamed:@"About-Selected"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        return cell;
    }
}

- (void)switchValueChanged:(id)sender {
    UISwitch *theSwitch = sender;
    
    NSString *key = nil;
    if (theSwitch.tag == 0) {
        key = kFullQualityVideoOnlyKey;
    }
    else if (theSwitch.tag == 1) {
        key = kDefaultAudioTrackOnlyKey;
    }
    else if (theSwitch.tag == 2) {
        key = kResumeVideosKey;
    }
    else {
        key = kDownloadAlertsKey;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:theSwitch.on forKey:key];
    [defaults synchronize];
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
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 4) {
        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:kFrequentlyAskedQuestionsURLStr]];
    }
    if (indexPath.section == 5) {
        if (indexPath.row == 0) {
            NSString *title = nil;
            if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                title = @"Add our official repo to your sources to get access to our other apps and stay up-to-date on future versions of the Universal Video Downloader:\n\nharrisonapps.com/repo\n\nTake note of the repo URL above,\nthen press the button below to launch Cydia and add it as a source.";
            }
            else {
                title = @"Add our official repo to your sources to get access to our other apps and stay up-to-date on future versions of the Universal Video Downloader:\n\nharrisonapps.com/repo\n\nTake note of the repo URL above, then press the button below to launch Cydia and add it as a source.";
            }
            UIActionSheet *addRepoActionSheet = [[UIActionSheet alloc]
                                                 initWithTitle:title
                                                 delegate:self
                                                 cancelButtonTitle:@"Cancel"
                                                 destructiveButtonTitle:nil
                                                 otherButtonTitles:@"Launch Cydia", @"More Info", nil];
            addRepoActionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
            [addRepoActionSheet showInView:self.tabBarController.view];
            [addRepoActionSheet release];
        }
        else {
            NSString *url = nil;
            if (indexPath.row == 1) {
                url = kWebsiteURLStr;
            }
            else if (indexPath.row == 2) {
                url = kFacebookURLStr;
            }
            else {
                url = kTwitterURLStr;
            }
            [[UIApplication sharedApplication]openURL:[NSURL URLWithString:url]];
        }
    }
    else if (indexPath.section == 6) {
        AboutViewController *aboutViewController = nil;
        if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            if ([[UIScreen mainScreen]bounds].size.height == 568) {
                aboutViewController = [[AboutViewController alloc]initWithNibName:@"AboutViewController_iPhone568" bundle:nil];
            }
            else {
                aboutViewController = [[AboutViewController alloc]initWithNibName:@"AboutViewController_iPhone" bundle:nil];
            }
        }
        else {
            aboutViewController = [[AboutViewController alloc]initWithNibName:@"AboutViewController_iPad" bundle:nil];
        }
        aboutViewController.title = NSLocalizedString(@"About", @"About");
        [self.navigationController pushViewController:aboutViewController animated:YES];
        [aboutViewController release];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        NSString *url = nil;
        if (buttonIndex == 0) {
            url = @"cydia://sources";
        }
        else {
            url = kRepoURLStr;
        }
        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:url]];
    }
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
