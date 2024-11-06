//
//  VideoDownloadOptionsViewController.m
//  Universal Video Downloader
//
//  Created by Harrison White on 2/17/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import "VideoDownloadOptionsViewController.h"
#import "TextFieldCell.h"

// From tests I have determined that the absolute maximum length of a file name is 262 characters, but I read online that the limit is supposed to be 255, so I decided to set the limit to 255 to be safe.
#define MAXIMUM_TEXT_LENGTH                 255

#define kFileNameReplacementStringsArray    [NSArray arrayWithObjects:@"/", @"-", nil]

@interface VideoDownloadOptionsViewController ()

@property (nonatomic, retain) IBOutlet UINavigationBar *theNavigationBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *downloadButton;
@property (nonatomic, retain) IBOutlet UITableView *theTableView;

@property (nonatomic, retain) NSMutableString *customVideoTitle;

@property (nonatomic) NSInteger selectedAudioTrackIndex;
@property (nonatomic) NSInteger selectedVideoIndex;

@property (readwrite) BOOL didInitiallyAssignFirstResponder;

- (IBAction)cancelButtonPressed;
- (IBAction)downloadButtonPressed;

- (BOOL)videoExistsWithTitle:(NSString *)videoTitle;
- (NSString *)defaultVideoTitle;
- (NSArray *)audioTracks;
- (BOOL)languageOptionsAvailable;
- (NSString *)titleForLanguageAtIndex:(NSInteger)index;
- (BOOL)languageAtIndexIsDefault:(NSInteger)index;
- (NSArray *)videos;
- (NSInteger)bandwidthForVideoAtIndex:(NSInteger)index;
- (NSInteger)videoBandwidthDenominator;

- (void)textFieldEditingChanged:(id)sender;

@end

@implementation VideoDownloadOptionsViewController

/*
// Simulator Debugging
#warning Don't forget to remove the simulator debugging code.
static NSString *kTemporaryFileDownloadPathStr          = @"/Users/Harrison/Desktop/Downloads";
static NSString *kDownloadDestinationPathStr            = @"/Users/Harrison/Desktop/Finished_Downloads";
static NSString *kVideoFolderDestinationPath            = @"/Users/Harrison/Desktop/Universal_Video_Downloader";
*/

/*
// Device Debugging
#warning Don't forget to remove the device debugging code.
#define kTemporaryFileDownloadPathStr                   [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:@"Downloads"]
#define kDownloadDestinationPathStr                     [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:@"Finished_Downloads"]
#define kVideoFolderDestinationPath                     [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
*/


// Deployment
static NSString *kTemporaryFileDownloadPathStr          = @"/private/var/mobile/Library/Universal_Video_Downloader/Downloads";
static NSString *kDownloadDestinationPathStr            = @"/private/var/mobile/Library/Universal_Video_Downloader/Finished_Downloads";
static NSString *kVideoFolderDestinationPath            = @"/private/var/mobile/Media/Universal_Video_Downloader";


static NSString *kMultipleLanguageOptionsSubtitleStr    = @"This video is available in multiple languages. Please choose the language you would like to download the video in.";

// Final newline added to improve the appearance of the UI. A space is required if the newline is the last character for the newline itself to work.
static NSString *kMultipleVideoQualitiesSubtitleStr     = @"This video is available in multiple qualities. Please choose the quality you would like to download the video in.\n ";
 
static NSString *kUntitledVideoStr                      = @"Untitled Video";
static NSString *kCopyFormatStr                         = @" (%i)";

static NSString *kAudioTrackLanguageTitleKey            = @"Audio Track Language Title";
static NSString *kIsDefaultAudioTrackKey                = @"Default Audio Track";
static NSString *kBandwidthKey                          = @"Bandwidth";

@synthesize delegate;

@synthesize theTableView;
@synthesize theNavigationBar;
@synthesize cancelButton;
@synthesize downloadButton;

@synthesize customVideoTitle;

@synthesize selectedAudioTrackIndex;
@synthesize selectedVideoIndex;

@synthesize didInitiallyAssignFirstResponder;

#pragma mark - View lifecycle

- (IBAction)cancelButtonPressed {
    if (delegate) {
        if ([delegate respondsToSelector:@selector(videoDownloadOptionsViewControllerDidCancel)]) {
            [delegate videoDownloadOptionsViewControllerDidCancel];
        }
    }
}

- (IBAction)downloadButtonPressed {
    NSInteger length = [customVideoTitle length];
    if (length > MAXIMUM_TEXT_LENGTH) {
        UIAlertView *videoNameLengthExceedsLimitAlert = [[UIAlertView alloc]
                                                         initWithTitle:@"Video Name Length Exceeds Limit"
                                                         message:[NSString stringWithFormat:@"Due to filesystem limitations, video names cannot exceed %i characters. Please enter a shorter name for this video.", MAXIMUM_TEXT_LENGTH]
                                                         delegate:self
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
        [videoNameLengthExceedsLimitAlert show];
        [videoNameLengthExceedsLimitAlert release];
    }
    else {
        if (length <= 0) {
            [customVideoTitle setString:[self defaultVideoTitle]];
        }
        if ([self videoExistsWithTitle:customVideoTitle]) {
            UIAlertView *videoAlreadyExistsAlert = [[UIAlertView alloc]
                                                    initWithTitle:@"Video Already Exists"
                                                    message:@"A video with this name already exists. Please rename the existing video or choose a different name."
                                                    delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
            [videoAlreadyExistsAlert show];
            [videoAlreadyExistsAlert release];
        }
        else {
            UITextField *videoTitleTextField = [(TextFieldCell *)[theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]textField];
            if (videoTitleTextField) {
                if ([videoTitleTextField isFirstResponder]) {
                    [videoTitleTextField resignFirstResponder];
                }
            }
            if (delegate) {
                if ([delegate respondsToSelector:@selector(videoDownloadOptionsViewControllerDidSelectOptionsWithVideoTitle:audioTrackIndex:videoFileIndex:)]) {
                    [delegate videoDownloadOptionsViewControllerDidSelectOptionsWithVideoTitle:customVideoTitle audioTrackIndex:selectedAudioTrackIndex videoFileIndex:selectedVideoIndex];
                }
            }
        }
    }
}

- (BOOL)videoExistsWithTitle:(NSString *)videoTitle {
    NSMutableString *videoDestinationDirectoryFileName = [NSMutableString stringWithString:videoTitle];
    for (int i = 0; i < ([kFileNameReplacementStringsArray count] / 2.0); i++) {
		[videoDestinationDirectoryFileName setString:[videoDestinationDirectoryFileName stringByReplacingOccurrencesOfString:[kFileNameReplacementStringsArray objectAtIndex:(i * 2)] withString:[kFileNameReplacementStringsArray objectAtIndex:((i * 2) + 1)]]];
	}
    
    BOOL videoExists = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *searchPathsArray = [NSArray arrayWithObjects:kTemporaryFileDownloadPathStr, kDownloadDestinationPathStr, kVideoFolderDestinationPath, nil];
    for (NSString *searchPath in searchPathsArray) {
        NSString *videoPath = [searchPath stringByAppendingPathComponent:videoDestinationDirectoryFileName];
        if ([fileManager fileExistsAtPath:videoPath]) {
            videoExists = YES;
            break;
        }
    }
    return videoExists;
}

- (NSString *)defaultVideoTitle {
    if ([self videoExistsWithTitle:kUntitledVideoStr]) {
        NSInteger copyNumber = 2;
        while ([self videoExistsWithTitle:[kUntitledVideoStr stringByAppendingFormat:kCopyFormatStr, copyNumber]]) {
            copyNumber += 1;
        }
        return [kUntitledVideoStr stringByAppendingFormat:kCopyFormatStr, copyNumber];
    }
    else {
        return kUntitledVideoStr;
    }
}

- (NSArray *)audioTracks {
    return [delegate videoDownloadOptionsViewControllerAudioTracks];
}

- (BOOL)languageOptionsAvailable {
    return ([[self audioTracks]count] > 0);
}

- (NSString *)titleForLanguageAtIndex:(NSInteger)index {
    NSDictionary *languageMetadata = [[self audioTracks]objectAtIndex:index];
    return [languageMetadata objectForKey:kAudioTrackLanguageTitleKey];
}

- (BOOL)languageAtIndexIsDefault:(NSInteger)index {
    NSDictionary *languageMetadata = [[self audioTracks]objectAtIndex:index];
    return [[languageMetadata objectForKey:kIsDefaultAudioTrackKey]boolValue];
}

- (NSArray *)videos {
    return [delegate videoDownloadOptionsViewControllerVideoFiles];
}

- (NSInteger)bandwidthForVideoAtIndex:(NSInteger)index {
    NSDictionary *videoMetadata = [[self videos]objectAtIndex:index];
    return [[videoMetadata objectForKey:kBandwidthKey]integerValue];
}

- (NSInteger)videoBandwidthDenominator {
    return [self bandwidthForVideoAtIndex:0];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    customVideoTitle = [[NSMutableString alloc]initWithString:[self defaultVideoTitle]];
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
    if (section == 0) {
        return @"Video Name";
    }
    else if (section == 1) {
        if ([self languageOptionsAvailable]) {
            return @"Language";
        }
        else {
            return @"Video Quality";
        }
    }
    else if (section == 2) {
        return @"Video Quality";
    }
    else {
        return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"Please enter a name for this video.";
    }
    else if (section == 1) {
        if ([self languageOptionsAvailable]) {
            if ([[self audioTracks]count] > 1) {
                return kMultipleLanguageOptionsSubtitleStr;
            }
        }
        else {
            if ([[self videos]count] > 1) {
                return kMultipleVideoQualitiesSubtitleStr;
            }
        }
    }
    else if (section == 2) {
        if ([[self videos]count] > 1) {
            return kMultipleVideoQualitiesSubtitleStr;
        }
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if ([delegate videoDownloadOptionsViewControllerPendingVideoIsVideoStream]) {
        if ([self languageOptionsAvailable]) {
            return 3;
        }
        else {
            return 2;
        }
    }
    else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0) {
        return 1;
    }
    else if (section == 1) {
        if ([self languageOptionsAvailable]) {
            return [[self audioTracks]count];
        }
        else {
            return [[self videos]count];
        }
    }
    else {
        return [[self videos]count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *CellIdentifier = @"Cell 1";
        
        TextFieldCell *cell = (TextFieldCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[TextFieldCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier]autorelease];
        }
        
        // Configure the cell...
        
        cell.textField.placeholder = [self defaultVideoTitle];
        cell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        cell.textField.returnKeyType = UIReturnKeyDone;
        [cell.textField addTarget:self action:@selector(textFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
        cell.textField.delegate = self;
        
        if (!didInitiallyAssignFirstResponder) {
            [cell.textField becomeFirstResponder];
            didInitiallyAssignFirstResponder = YES;
        }
        
        return cell;
    }
    else if (indexPath.section == 1) {
        static NSString *CellIdentifier = @"Cell 2";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier]autorelease];
        }
        
        // Configure the cell...
        
        if ([self languageOptionsAvailable]) {
            if ([self languageAtIndexIsDefault:indexPath.row]) {
                cell.textLabel.text = [[self titleForLanguageAtIndex:indexPath.row]stringByAppendingString:@" (Default)"];
            }
            else {
                cell.textLabel.text = [self titleForLanguageAtIndex:indexPath.row];
            }
            
            if (indexPath.row == selectedAudioTrackIndex) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else {
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Full Quality";
            }
            else {
                cell.textLabel.text = [NSString stringWithFormat:@"%i%% Quality", (NSInteger)(((CGFloat)([self bandwidthForVideoAtIndex:indexPath.row]) / (CGFloat)([self videoBandwidthDenominator])) * 100)];
            }
            
            if (indexPath.row == selectedVideoIndex) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        
        return cell;
    }
    else {
        static NSString *CellIdentifier = @"Cell 3";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier]autorelease];
        }
        
        // Configure the cell...
        
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Full Quality";
        }
        else {
            cell.textLabel.text = [NSString stringWithFormat:@"%i%% Quality", (NSInteger)(((CGFloat)([self bandwidthForVideoAtIndex:indexPath.row]) / (CGFloat)([self videoBandwidthDenominator])) * 100)];
        }
        
        if (indexPath.row == selectedVideoIndex) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        return cell;
    }
}

- (void)textFieldEditingChanged:(id)sender {
    UITextField *textField = sender;
    if (![customVideoTitle isEqualToString:textField.text]) {
        [customVideoTitle setString:textField.text];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if ([textField.text length] > 0) {
        if (![customVideoTitle isEqualToString:textField.text]) {
            [customVideoTitle setString:textField.text];
        }
    }
    else {
        [customVideoTitle setString:[self defaultVideoTitle]];
        textField.text = customVideoTitle;
    }
    return NO;
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
    
    if (indexPath.section != 0) {
        if ((indexPath.section == 1) && ([self languageOptionsAvailable])) {
            if (indexPath.row != selectedAudioTrackIndex) {
                NSInteger previouslySelectedRow = selectedAudioTrackIndex;
                selectedAudioTrackIndex = indexPath.row;
                [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:previouslySelectedRow inSection:1], indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
                [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
        else {
            if (indexPath.row != selectedVideoIndex) {
                NSInteger previouslySelectedRow = selectedVideoIndex;
                selectedVideoIndex = indexPath.row;
                [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:previouslySelectedRow inSection:indexPath.section], indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
                [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    
    self.theNavigationBar = nil;
    self.cancelButton = nil;
    self.downloadButton = nil;
    self.theTableView = nil;
    
    self.customVideoTitle = nil;
}

- (void)dealloc {
    [theNavigationBar release];
    [cancelButton release];
    [downloadButton release];
    [theTableView release];
    
    [customVideoTitle release];
    [super dealloc];
}

@end
