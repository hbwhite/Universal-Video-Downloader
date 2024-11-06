//
//  AppsViewController.m
//  Universal Video Downloader
//
//  Created by Harrison White on 3/18/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import "AppsViewController.h"
#import "AppDelegate.h"
#import "RootViewController.h"
#import "AppList.h"
#import "MBProgressHUD.h"
#import "SwitchCell.h"

#define APP_DISPLAY_NAME_INDEX                  0
#define APP_IDENTIFIER_INDEX                    1

static NSString *kEnableAllApplicationsKey      = @"Enable All Applications";
static NSString *kEnabledApplicationsArrayKey   = @"Enabled Applications";

@implementation AppsViewController

@synthesize theTableView;
@synthesize refreshButton;
@synthesize appsArray;
@synthesize refreshingApps;
@synthesize isAdObserver;

@synthesize applicationList;
@synthesize appListState;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    refreshButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonPressed)];
    if (![[NSUserDefaults standardUserDefaults]boolForKey:kEnableAllApplicationsKey]) {
        self.navigationItem.rightBarButtonItem = refreshButton;
    }
    appsArray = [[NSMutableArray alloc]init];
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

- (void)refreshButtonPressed {
    CGPoint contentOffset = theTableView.contentOffset;
    if (theTableView.contentOffset.y < 0) {
        contentOffset = CGPointMake(0, 0);
    }
    else {
        NSInteger maximumContentOffsetYValue = (theTableView.contentSize.height - 1);
        if (theTableView.contentOffset.y > maximumContentOffsetYValue) {
            contentOffset = CGPointMake(0, maximumContentOffsetYValue);
        }
    }
    [theTableView setContentOffset:contentOffset animated:NO];
    
    [self refreshApps:NO];
}

- (void)refreshApps:(BOOL)enabled {
    refreshingApps = YES;
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    UIView *view = [[(AppDelegate *)[[UIApplication sharedApplication]delegate]rootViewController]view];
    
    MBProgressHUD *progressHUD = [[MBProgressHUD alloc]initWithView:view];
    progressHUD.mode = MBProgressHUDModeIndeterminate;
    progressHUD.labelText = @"Loading...";
    [view addSubview:progressHUD];
    [progressHUD showWhileExecuting:@selector(_refreshApps:) onTarget:self withObject:[NSNumber numberWithBool:enabled] animated:YES];
    [progressHUD release];
}

- (void)_refreshApps:(NSNumber *)enabled {
    BOOL appListIsFunctional = YES;
    for (NSString *identifier in [[self applications]allKeys]) {
        if ([identifier isKindOfClass:[NSString class]]) {
            NSString *appName = [[self applications]objectForKey:identifier];
            if (![appName isKindOfClass:[NSString class]]) {
                appListIsFunctional = NO;
                break;
            }
        }
        else {
            appListIsFunctional = NO;
            break;
        }
    }
    
    if (appListIsFunctional) {
        appListState = kAppListStateFunctional;
    }
    else {
        appListState = kAppListStateNotFunctional;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:kEnableAllApplicationsKey];
        [defaults synchronize];
    }
    
    if (![[NSUserDefaults standardUserDefaults]boolForKey:kEnableAllApplicationsKey]) {
        if (appListIsFunctional) {
            NSMutableArray *appDisplayNamesArray = [[NSMutableArray alloc]initWithObjects:nil];
            NSMutableArray *appsSortedByIdentifiersArray = [[NSMutableArray alloc]initWithObjects:nil];
            
            NSString *bundleIdentifier = [[NSBundle mainBundle]bundleIdentifier];
            
            NSDictionary *originalAppsDictionary = [self applications];
            NSArray *sortedIdentifiersArray = [[originalAppsDictionary allKeys]sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            for (int i = 0; i < [sortedIdentifiersArray count]; i++) {
                NSString *key = [sortedIdentifiersArray objectAtIndex:i];
                if (![key isEqualToString:bundleIdentifier]) {
                    [appDisplayNamesArray addObject:[originalAppsDictionary objectForKey:key]];
                    [appsSortedByIdentifiersArray addObject:[NSArray arrayWithObjects:[originalAppsDictionary objectForKey:key], key, nil]];
                }
            }
            
            [appDisplayNamesArray sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            
            NSMutableArray *temporaryAppsArray = [[NSMutableArray alloc]initWithObjects:nil];
            
            for (int i = 0; i < [appDisplayNamesArray count]; i++) {
                NSString *appDisplayName = [appDisplayNamesArray objectAtIndex:i];
                for (int j = 0; j < [appsSortedByIdentifiersArray count]; j++) {
                    NSArray *appArray = [appsSortedByIdentifiersArray objectAtIndex:j];
                    if ([[appArray objectAtIndex:APP_DISPLAY_NAME_INDEX]isEqualToString:appDisplayName]) {
                        [temporaryAppsArray addObject:[NSArray arrayWithObjects:appDisplayName, [appArray objectAtIndex:APP_IDENTIFIER_INDEX], nil]];
                        [appsSortedByIdentifiersArray removeObjectAtIndex:j];
                        break;
                    }
                }
            }
            
            [appDisplayNamesArray release];
            [appsSortedByIdentifiersArray release];
            
            [appsArray setArray:temporaryAppsArray];
            
            [temporaryAppsArray release];
        }
        else {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:YES forKey:kEnableAllApplicationsKey];
            [defaults synchronize];
            
            [appsArray removeAllObjects];
        }
        
        [theTableView reloadData];
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    
    refreshingApps = NO;
}

- (ALApplicationList *)applicationList {
    if (!applicationList) {
        applicationList = [ALApplicationList sharedApplicationList];
    }
    return applicationList;
}

- (NSDictionary *)applications {
    return [[self applicationList]applications];
}

- (void)viewWillAppear:(BOOL)animated {
    [self refreshApps:NO];
    
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
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 2) {
        if (appListState == kAppListStateFunctional) {
            return @"Select Enabled Apps:";
        }
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"Turn on the \"Enable All Apps\" switch to enable the Universal Video Downloader in all applications, or turn it off to select specific apps.";
    }
    else if (section == 2) {
        if (appListState == kAppListStateNotFunctional) {
            return @"AppList is not working properly on your device. Please make sure that you are not in Safe Mode and that the AppList Mobile Substrate extension is enabled. When AppList is working properly, you will be able to select specific apps in which to enable the Universal Video Downloader.";
        }
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (appListState == kAppListStateNotFunctional) {
        return 3;
    }
    else {
        if ([[NSUserDefaults standardUserDefaults]boolForKey:kEnableAllApplicationsKey]) {
            return 2;
        }
        else {
            return 3;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0) {
        return 0;
    }
    else if (section == 1) {
        return 1;
    }
    else {
        if (appListState == kAppListStateNotFunctional) {
            return 0;
        }
        else {
            return [appsArray count];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = nil;
    if (indexPath.section == 1) {
        CellIdentifier = @"Cell 1";
    }
    else {
        CellIdentifier = [NSString stringWithFormat:@"Cell %i", (indexPath.row + 2)];
    }
    
    SwitchCell *cell = (SwitchCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[SwitchCell alloc]initWithStyle:(indexPath.section == 1) ? UITableViewCellStyleDefault : UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier]autorelease];
    }
    
    // Configure the cell...
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (indexPath.section == 1) {
        cell.textLabel.text = @"Enable All Apps";
        cell.imageView.image = [UIImage imageNamed:@"Enable_All_Apps"];
        
        cell.cellSwitch.tag = 0;
        cell.cellSwitch.on = [defaults boolForKey:kEnableAllApplicationsKey];
        
        if (appListState == kAppListStateNotFunctional) {
            cell.cellSwitch.enabled = NO;
        }
        else {
            cell.cellSwitch.enabled = YES;
        }
    }
    else {
        NSString *appDisplayName = [[appsArray objectAtIndex:indexPath.row]objectAtIndex:APP_DISPLAY_NAME_INDEX];
        NSString *appIdentifier = [[appsArray objectAtIndex:indexPath.row]objectAtIndex:APP_IDENTIFIER_INDEX];
        
        cell.textLabel.text = appDisplayName;
        cell.detailTextLabel.text = appIdentifier;
        cell.imageView.image = [[self applicationList]iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:appIdentifier];
        
        cell.cellSwitch.tag = (indexPath.row + 1);
        cell.cellSwitch.on = [[defaults arrayForKey:kEnabledApplicationsArrayKey]containsObject:appIdentifier];
    }
    [cell.cellSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    return cell;
}

- (void)switchValueChanged:(id)sender {
    [[UIApplication sharedApplication]beginIgnoringInteractionEvents];
    
    UISwitch *theSwitch = sender;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (theSwitch.tag == 0) {
        if (theSwitch.on != [defaults boolForKey:kEnableAllApplicationsKey]) {
            if (refreshingApps) {
                [theSwitch setOn:NO animated:YES];
            }
            else {
                [defaults setBool:theSwitch.on forKey:kEnableAllApplicationsKey];
                [defaults synchronize];
                
                if (theSwitch.on) {
                    self.navigationItem.rightBarButtonItem = nil;
                    
                    // This saves RAM.
                    [appsArray removeAllObjects];
                    
                    [theTableView reloadData];
                }
                else {
                    self.navigationItem.rightBarButtonItem = refreshButton;
                    
                    [self refreshApps:YES];
                }
            }
        }
    }
    else {
        NSString *appIdentifier = [[appsArray objectAtIndex:(theSwitch.tag - 1)]objectAtIndex:APP_IDENTIFIER_INDEX];
        
        NSMutableArray *enabledApplicationsArray = [NSMutableArray arrayWithArray:[defaults objectForKey:kEnabledApplicationsArrayKey]];
        if (theSwitch.on) {
            [enabledApplicationsArray addObject:appIdentifier];
        }
        else {
            [enabledApplicationsArray removeObject:appIdentifier];
        }
        [defaults setObject:enabledApplicationsArray forKey:kEnabledApplicationsArrayKey];
        [defaults synchronize];
    }
    
    [[UIApplication sharedApplication]endIgnoringInteractionEvents];
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
    self.refreshButton = nil;
    self.appsArray = nil;
}

- (void)dealloc {
    [theTableView release];
    [refreshButton release];
    [appsArray release];
    [super dealloc];
}

@end
