//
//  TextInputViewController.m
//  Universal Video Downloader
//
//  Created by Harrison White on 2/17/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import "TextInputViewController.h"
#import "TextFieldCell.h"

// From tests I have determined that the absolute maximum length of a file name is 262 characters, but I read online that the limit is supposed to be 255, so I decided to set the limit to 255 to be safe.
#define MAXIMUM_TEXT_LENGTH 255

@interface TextInputViewController ()

- (IBAction)cancelButtonPressed;
- (IBAction)doneButtonPressed;
- (void)didFinishTextEntry;
- (void)assignFirstResponder;

@end

@implementation TextInputViewController

@synthesize delegate;

@synthesize theTableView;
@synthesize theNavigationBar;
@synthesize cancelButton;
@synthesize doneButton;

#pragma mark - View lifecycle

- (IBAction)cancelButtonPressed {
    // Modified to use iOS 5's new modal view controller functions when possible.
    UIViewController *textInputViewControllerParentViewController = [delegate textInputViewControllerParentViewController];
    if ([textInputViewControllerParentViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [textInputViewControllerParentViewController dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [textInputViewControllerParentViewController dismissModalViewControllerAnimated:YES];
    }
}

- (IBAction)doneButtonPressed {
    [self didFinishTextEntry];
}

- (void)didFinishTextEntry {
    NSString *text = [[(TextFieldCell *)[theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]]textField]text];
    NSInteger length = [text length];
    if (length > 0) {
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
            if (delegate) {
                if ([delegate respondsToSelector:@selector(textInputViewControllerDidReceiveTextInput:)]) {
                    [delegate textInputViewControllerDidReceiveTextInput:text];
                }
            }
        }
    }
    else {
        UIAlertView *emptyTitleAlert = [[UIAlertView alloc]
                                        initWithTitle:@"Empty Title"
                                        message:@"The title field cannot be left blank."
                                        delegate:self
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
        [emptyTitleAlert show];
        [emptyTitleAlert release];
    }
}

- (void)assignFirstResponder {
    [[(TextFieldCell *)[theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]]textField]becomeFirstResponder];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self assignFirstResponder];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    theNavigationBar.topItem.title = [delegate textInputViewControllerNavigationBarTitle];
}

- (void)viewWillAppear:(BOOL)animated {
    [theTableView reloadData];
    [self assignFirstResponder];
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            return [@"\n\n\n" stringByAppendingString:[delegate textInputViewControllerHeader]];
        }
        else {
            return [@"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" stringByAppendingString:[delegate textInputViewControllerHeader]];
        }
    }
    else {
        return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 1) {
        return 1;
    }
    else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    TextFieldCell *cell = (TextFieldCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[TextFieldCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier]autorelease];
    }
    
    // Configure the cell...
    
    cell.textField.delegate = self;
    cell.textField.placeholder = [delegate textInputViewControllerPlaceholder];
    cell.textField.text = [delegate textInputViewControllerDefaultText];
    cell.textField.returnKeyType = UIReturnKeyDone;
    
    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self didFinishTextEntry];
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
    self.doneButton = nil;
    self.theTableView = nil;
}

- (void)dealloc {
    [theNavigationBar release];
    [cancelButton release];
    [doneButton release];
    [theTableView release];
    [super dealloc];
}

@end
