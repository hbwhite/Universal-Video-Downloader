//
//  VideosViewController.m
//  Universal Video Downloader
//
//  Created by Harrison White on 3/18/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import "VideosViewController.h"
#import "AppDelegate.h"
#import "RootViewController.h"
#import "TextInputViewController.h"
#import "HTTPServer.h"
#import "MBProgressHUD.h"

#define ROW_HEIGHT                                  90

#define MB_FLOAT_SIZE                               1048576.0

#define kFileNameReplacementStringsArray            [NSArray arrayWithObjects:@"/", @"-", nil]

/*
// Simulator Debugging
#warning Don't forget to remove the simulator debugging code.
static NSString *kFilePathStr                       = @"/Users/Harrison/Desktop/Universal_Video_Downloader";
*/

/*
// Device Debugging
#warning Don't forget to remove the device debugging code.
#define kFilePathStr                                [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
*/


// Deployment
static NSString *kFilePathStr                       = @"/private/var/mobile/Media/Universal_Video_Downloader";


static NSString *kMetadataFileNameStr               = @"Metadata.plist";

static NSString *kVideoTitleKey                     = @"Video Title";
static NSString *kIsVideoStreamKey                  = @"Video Stream";
static NSString *kVideoFileNameKey                  = @"Video File Name";
static NSString *kIndexFileNameKey                  = @"Index File Name";
static NSString *kSizeInBytesKey                    = @"Size In Bytes";
static NSString *kCurrentPlaybackTimeKey            = @"Current Playback Time";

static NSString *kResumeVideosKey                   = @"Resume Videos";

static NSString *kStringFormatSpecifierStr          = @"%@";
static NSString *kFloatFormatSpecifierStr           = @"%f";

static NSString *kNullStr                           = @"";

static NSString *kDecimalStr                        = @".";
static NSString *kTenthAppendStr                    = @"0";
static NSString *kWholeNumberAppendStr              = @".00";

static NSString *kFileDeletionFormatStr             = @"Deleting File %i of %i...";

@implementation VideosViewController

@synthesize theTableView;
@synthesize editButton;
@synthesize doneButton;
@synthesize decimalNumberHandler;
@synthesize pendingVideoFolderName;
@synthesize isAdObserver;

- (void)editButtonPressed {
    [self editButtonAction];
}

- (void)doneButtonPressed {
    [self doneButtonAction];
}

- (void)editButtonAction {
    [theTableView setEditing:YES animated:YES];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)doneButtonAction {
    [theTableView setEditing:NO animated:YES];
    self.navigationItem.rightBarButtonItem = editButton;
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [self editButtonAction];
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    [self doneButtonAction];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    decimalNumberHandler = [[NSDecimalNumberHandler alloc]
                            initWithRoundingMode:NSRoundPlain
                            scale:2
                            raiseOnExactness:NO
                            raiseOnOverflow:NO
                            raiseOnUnderflow:NO
                            raiseOnDivideByZero:NO];
    
    pendingVideoFolderName = [[NSMutableString alloc]init];
    
    editButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed)];
    doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    
    if ([[self videos]count] > 0) {
        self.navigationItem.rightBarButtonItem = editButton;
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
        if (theTableView.editing) {
            [theTableView setEditing:NO animated:NO];
        }
    }
    
    theTableView.rowHeight = ROW_HEIGHT;
}

- (NSArray *)videos {
    NSMutableArray *foldersArray = [NSMutableArray arrayWithObjects:nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *item in [fileManager contentsOfDirectoryAtPath:kFilePathStr error:nil]) {
        NSString *videoDirectoryPath = [kFilePathStr stringByAppendingPathComponent:item];
        
        BOOL isDirectory = NO;
        [fileManager fileExistsAtPath:videoDirectoryPath isDirectory:&isDirectory];
        if (isDirectory) {
            NSString *metadataDictionaryFilePath = [videoDirectoryPath stringByAppendingPathComponent:kMetadataFileNameStr];
            if ([fileManager fileExistsAtPath:metadataDictionaryFilePath]) {
                [foldersArray addObject:item];
            }
        }
    }
    return foldersArray;
}

- (NSString *)pathForFileWithName:(NSString *)fileName {
    NSMutableString *finalFileName = [NSMutableString stringWithString:fileName];
    for (int i = 0; i < ([kFileNameReplacementStringsArray count] / 2.0); i++) {
		[finalFileName setString:[finalFileName stringByReplacingOccurrencesOfString:[kFileNameReplacementStringsArray objectAtIndex:(i * 2)] withString:[kFileNameReplacementStringsArray objectAtIndex:((i * 2) + 1)]]];
	}
    return [kFilePathStr stringByAppendingPathComponent:finalFileName];
}

- (BOOL)isAirPlaySupported {
	return [MPMoviePlayerViewController instancesRespondToSelector:@selector(setAllowsAirPlay:)];
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
    if ([[self videos]count] > 0) {
        if (!self.navigationItem.rightBarButtonItem) {
            self.navigationItem.rightBarButtonItem = editButton;
        }
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
        if (theTableView.editing) {
            [theTableView setEditing:NO animated:NO];
        }
    }
    [theTableView reloadData];
    
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[self videos]count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ROW_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier]autorelease];
    }
    
    // Configure the cell...
    
    NSString *videoFolderName = [[self videos]objectAtIndex:indexPath.row];
    NSString *videoFolderPath = [self pathForFileWithName:videoFolderName];
    
    NSString *metadataDictionaryFilePath = [videoFolderPath stringByAppendingPathComponent:kMetadataFileNameStr];
    NSDictionary *metadataDictionary = [NSDictionary dictionaryWithContentsOfFile:metadataDictionaryFilePath];
    
    cell.textLabel.text = [metadataDictionary objectForKey:kVideoTitleKey];
    cell.textLabel.numberOfLines = 3;
    
    unsigned long long folderSizeInBytes = [[metadataDictionary objectForKey:kSizeInBytesKey]unsignedLongLongValue];
    CGFloat folderSizeInMegaBytes = (folderSizeInBytes / MB_FLOAT_SIZE);
    NSString *folderSizeInMegaBytesString = [NSString stringWithFormat:kFloatFormatSpecifierStr, folderSizeInMegaBytes];
    NSDecimalNumber *folderSizeInMegaBytesDecimalNumber = [[NSDecimalNumber decimalNumberWithString:folderSizeInMegaBytesString]decimalNumberByRoundingAccordingToBehavior:decimalNumberHandler];
    NSString *formattedFolderSizeInMegaBytesString = [self stringFromDecimalNumber:folderSizeInMegaBytesDecimalNumber];
    cell.detailTextLabel.text = [formattedFolderSizeInMegaBytesString stringByAppendingString:@" MB"];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    
    return cell;
}

- (NSString *)stringFromDecimalNumber:(NSDecimalNumber *)decimalNumber {
	NSMutableString *formattedDecimalNumber = [NSMutableString stringWithFormat:kStringFormatSpecifierStr, decimalNumber];
	if ([formattedDecimalNumber rangeOfString:kDecimalStr].length > 0) {
		if ([[[formattedDecimalNumber componentsSeparatedByString:kDecimalStr]lastObject]length] < 2) {
			[formattedDecimalNumber appendString:kTenthAppendStr];
		}
	}
	else {
		[formattedDecimalNumber appendString:kWholeNumberAppendStr];
	}
    /*
    if ([formattedDecimalNumber rangeOfString:kDecimalStr].length <= 0) {
        [formattedDecimalNumber appendString:kWholeNumberAppendStr];
    }
    */
	return [NSString stringWithString:formattedDecimalNumber];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSString *videoFolderName = [[self videos]objectAtIndex:indexPath.row];
    NSString *videoFolderPath = [self pathForFileWithName:videoFolderName];
    NSString *metadataDictionaryFilePath = [videoFolderPath stringByAppendingPathComponent:kMetadataFileNameStr];
    NSDictionary *metadataDictionary = [NSDictionary dictionaryWithContentsOfFile:metadataDictionaryFilePath];
    NSString *videoTitle = [metadataDictionary objectForKey:kVideoTitleKey];
    if (videoTitle) {
        [pendingVideoFolderName setString:[metadataDictionary objectForKey:kVideoTitleKey]];
    }
    else {
        [pendingVideoFolderName setString:kNullStr];
    }
    
    TextInputViewController *textInputViewController = nil;
    if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if ([[UIScreen mainScreen]bounds].size.height == 568) {
            textInputViewController = [[TextInputViewController alloc]initWithNibName:@"TextInputViewController_iPhone568" bundle:nil];
        }
        else {
            textInputViewController = [[TextInputViewController alloc]initWithNibName:@"TextInputViewController_iPhone" bundle:nil];
        }
    }
    else {
        textInputViewController = [[TextInputViewController alloc]initWithNibName:@"TextInputViewController_iPad" bundle:nil];
    }
    textInputViewController.delegate = self;
    
    // Modified to use iOS 5's new modal view controller functions when possible.
    UIViewController *rootViewController = self.tabBarController;
    if ([rootViewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        [rootViewController presentViewController:textInputViewController animated:YES completion:nil];
    }
    else {
        [rootViewController presentModalViewController:textInputViewController animated:YES];
    }
    
    [textInputViewController release];
}

- (NSString *)textInputViewControllerNavigationBarTitle {
    return @"Rename Video";
}

- (NSString *)textInputViewControllerHeader {
    return @"Please enter a new name for this video:";
}

- (NSString *)textInputViewControllerPlaceholder {
    return @"New Video Name";
}

- (NSString *)textInputViewControllerDefaultText {
    return pendingVideoFolderName;
}

- (UIViewController *)textInputViewControllerParentViewController {
    return self.tabBarController;
}

- (void)textInputViewControllerDidReceiveTextInput:(NSString *)text {
    NSString *path = [self pathForFileWithName:text];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        UIAlertView *itemAlreadyExistsAlert = [[UIAlertView alloc]
                                               initWithTitle:@"Video Already Exists"
                                               message:@"A video with this name already exists. Please rename the existing video or choose a different name for this one."
                                               delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
        [itemAlreadyExistsAlert show];
        [itemAlreadyExistsAlert release];
    }
    else {
        // The errors are handled in this way so that only one error message will be shown.
        
        BOOL videoRenamingError = NO;
        
        NSString *videoDirectoryFilePath = [self pathForFileWithName:pendingVideoFolderName];
        
        NSString *metadataDictionaryFilePath = [videoDirectoryFilePath stringByAppendingPathComponent:kMetadataFileNameStr];
        NSMutableDictionary *metadataDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:metadataDictionaryFilePath];
        if (metadataDictionary) {
            [metadataDictionary setObject:text forKey:kVideoTitleKey];
            [metadataDictionary writeToFile:metadataDictionaryFilePath atomically:YES];
        }
        else {
            videoRenamingError = YES;
        }
        
        if (![fileManager moveItemAtPath:videoDirectoryFilePath toPath:path error:nil]) {
            if (!videoRenamingError) {
                UIAlertView *errorAlert = [[UIAlertView alloc]
                                           initWithTitle:@"Error Renaming Video Folder"
                                           message:@"The app encountered an error while trying to rename the video folder.\nPlease make sure the app has read and write access to the directory at /var/mobile/Media/Universal_Video_Downloader and its subdirectories and try again."
                                           delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
                [errorAlert show];
                [errorAlert release];
            }
        }
        
        if (videoRenamingError) {
            UIAlertView *errorAlert = [[UIAlertView alloc]
                                       initWithTitle:@"Error Renaming Video"
                                       message:@"The app encountered an error while trying to rename the video.\nPlease make sure the app has read and write access to the directory at /var/mobile/Media/Universal_Video_Downloader and its subdirectories and try again."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [errorAlert show];
            [errorAlert release];
        }
        
        // Modified to use iOS 5's new modal view controller functions when possible.
        UIViewController *rootViewController = self.tabBarController;
        if ([rootViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            [rootViewController dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            [rootViewController dismissModalViewControllerAnimated:YES];
        }
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        
        NSArray *videos = [self videos];
        NSString *videoDirectoryPath = [self pathForFileWithName:[videos objectAtIndex:indexPath.row]];
        
        UIView *view = self.tabBarController.view;
        
        MBProgressHUD *progressHUD = [[MBProgressHUD alloc]initWithView:view];
        progressHUD.mode = MBProgressHUDModeDeterminate;
        progressHUD.labelText = @"Deleting Video";
        [view addSubview:progressHUD];
        
        NSArray *parameters = [NSArray arrayWithObjects:videoDirectoryPath, progressHUD, nil];
        [progressHUD showWhileExecuting:@selector(deleteVideoWithParameters:) onTarget:self withObject:parameters animated:YES];
        
        [progressHUD release];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (void)deleteVideoWithParameters:(NSArray *)parameters {
    NSString *path = [parameters objectAtIndex:0];
    MBProgressHUD *hud = [parameters objectAtIndex:1];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:path error:nil];
    NSInteger contentsFileCount = [contents count];
    NSInteger fileCount = (contentsFileCount + 1);
    for (int i = 0; i < contentsFileCount; i++) {
        NSInteger currentItemNumber = (i + 1);
        
        hud.detailsLabelText = [NSString stringWithFormat:kFileDeletionFormatStr, currentItemNumber, fileCount];
        
        [fileManager removeItemAtPath:[path stringByAppendingPathComponent:[contents objectAtIndex:i]] error:nil];
        
        hud.progress = (((CGFloat)currentItemNumber) / ((CGFloat)fileCount));
    }
    
    hud.detailsLabelText = [NSString stringWithFormat:kFileDeletionFormatStr, fileCount, fileCount];
    
    if (![[NSFileManager defaultManager]removeItemAtPath:path error:nil]) {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Error Deleting Video"
                                   message:@"The app encountered an error while trying to delete this video. Please make sure the app has read and write access to the directory at /var/mobile/Media and try again."
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
    }
    
    hud.progress = 1;
    
    if ([[self videos]count] <= 0) {
        self.navigationItem.rightBarButtonItem = nil;
        if (theTableView.editing) {
            [theTableView setEditing:NO animated:NO];
        }
    }
    [theTableView reloadData];
}

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
    
    NSString *videoFolderName = [[self videos]objectAtIndex:indexPath.row];
    
    [pendingVideoFolderName setString:videoFolderName];
    
    NSString *videoFolderPath = [self pathForFileWithName:videoFolderName];
    
    NSDictionary *metadataDictionary = [NSDictionary dictionaryWithContentsOfFile:[videoFolderPath stringByAppendingPathComponent:kMetadataFileNameStr]];
    
    NSTimeInterval initialPlaybackTime = 0;
    if ([[NSUserDefaults standardUserDefaults]boolForKey:kResumeVideosKey]) {
        initialPlaybackTime = [[metadataDictionary objectForKey:kCurrentPlaybackTimeKey]doubleValue];
    }
    
    if ([[metadataDictionary objectForKey:kIsVideoStreamKey]boolValue]) {
        HTTPServer *httpServer = [(AppDelegate *)[[UIApplication sharedApplication]delegate]httpServer];
        [httpServer setDocumentRoot:videoFolderPath];
        
        NSString *indexFileName = [metadataDictionary objectForKey:kIndexFileNameKey];
        
        NSURL *indexFileURL = [[NSURL alloc]initWithScheme:@"http" host:[NSString stringWithFormat:@"127.0.0.1:%hu", [httpServer listeningPort]] path:[@"/" stringByAppendingString:indexFileName]];
        
        MoviePlayerViewController *moviePlayerViewController = [[MoviePlayerViewController alloc]initWithDelegate:self contentURL:indexFileURL initialPlaybackTime:initialPlaybackTime];
        
        [indexFileURL release];
        
        [moviePlayerViewController.moviePlayer prepareToPlay];
        
        if ([self isAirPlaySupported]) {
            [moviePlayerViewController.moviePlayer setAllowsAirPlay:YES];
        }
        
        // If this is set to MPMovieSourceTypeStreaming, it will cause the video player to crash on devices running iOS 6.
        [moviePlayerViewController.moviePlayer setMovieSourceType:MPMovieSourceTypeUnknown];
        
        [moviePlayerViewController.moviePlayer setRepeatMode:MPMovieRepeatModeNone];
        [moviePlayerViewController.moviePlayer setShouldAutoplay:YES];
        
        // If this isn't set to NO, it can sometimes cause the app to mute videos (this is a bug in iOS 5).
        [moviePlayerViewController.moviePlayer setUseApplicationAudioSession:NO];
        
        [self.tabBarController presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
        
        [moviePlayerViewController release];
    }
    else {
        NSURL *videoFileURL = [NSURL fileURLWithPath:[videoFolderPath stringByAppendingPathComponent:[metadataDictionary objectForKey:kVideoFileNameKey]]];
        MoviePlayerViewController *moviePlayerViewController = [[MoviePlayerViewController alloc]initWithDelegate:self contentURL:videoFileURL initialPlaybackTime:initialPlaybackTime];
        
        [moviePlayerViewController.moviePlayer prepareToPlay];
        
        if ([self isAirPlaySupported]) {
            [moviePlayerViewController.moviePlayer setAllowsAirPlay:YES];
        }
        
        [moviePlayerViewController.moviePlayer setMovieSourceType:MPMovieSourceTypeFile];
        
        [moviePlayerViewController.moviePlayer setRepeatMode:MPMovieRepeatModeNone];
        [moviePlayerViewController.moviePlayer setShouldAutoplay:YES];
        
        // If this isn't set to NO, it can sometimes cause the app to mute videos (this is a bug in iOS 5).
        [moviePlayerViewController.moviePlayer setUseApplicationAudioSession:NO];
        
        [self.tabBarController presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
        
        [moviePlayerViewController release];
    }
}

- (void)moviePlayerViewControllerDidFinishPlayingVideoAtPlaybackTime:(NSTimeInterval)playbackTime {
    NSString *metadataDictionaryFilePath = [[self pathForFileWithName:pendingVideoFolderName]stringByAppendingPathComponent:kMetadataFileNameStr];
    NSMutableDictionary *metadataDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:metadataDictionaryFilePath];
    if (metadataDictionary) {
        [metadataDictionary setObject:[NSNumber numberWithDouble:playbackTime] forKey:kCurrentPlaybackTimeKey];
        [metadataDictionary writeToFile:metadataDictionaryFilePath atomically:YES];
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
    self.editButton = nil;
    self.doneButton = nil;
    self.decimalNumberHandler = nil;
    self.pendingVideoFolderName = nil;
}

- (void)dealloc {
    [theTableView release];
    [editButton release];
    [doneButton release];
    [decimalNumberHandler release];
    [pendingVideoFolderName release];
    [super dealloc];
}

@end
