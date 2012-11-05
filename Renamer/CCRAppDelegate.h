//
//  CCRAppDelegate.h
//  Renamer
//
//  Created by Curt Clifton on 9/18/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CCRSourceList;

@interface CCRAppDelegate : NSObject <NSApplicationDelegate, NSSplitViewDelegate, NSTableViewDelegate>

// bindings
@property (nonatomic) BOOL enableControls;
@property (nonatomic, strong) NSURL *destinationDirectory;

// main app window
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet CCRSourceList *sourceList;
@property (weak) IBOutlet NSTableView *sourceListTableView;
@property (weak) IBOutlet NSSplitView *splitView;
@property (weak) IBOutlet NSView *sourceListContainerView;
@property (weak) IBOutlet NSView *controlsPaneContainerView;
@property (weak) IBOutlet NSButton *renameAndFileButton;
@property (weak) IBOutlet NSTextField *computedNameTextField;
@property (weak) IBOutlet NSButton *quicklookButton;

@property (weak) IBOutlet NSTextField *yearTextField;
@property (weak) IBOutlet NSTextField *monthTextField;
@property (weak) IBOutlet NSTextField *dayTextField;
@property (weak) IBOutlet NSButton *includeDayCheckbox;
@property (weak) IBOutlet NSComboBox *tagComboBox;
@property (weak) IBOutlet NSComboBox *titleComboBox;

- (IBAction)renameAndFile:(id)sender;
- (IBAction)open:(id)sender;
- (IBAction)quicklook:(id)sender;
- (IBAction)chooseDestination:(id)sender;
- (IBAction)includeDayChanged:(id)sender;

// replacement confirmation sheet
@property (weak) IBOutlet NSWindow *replacementConfirmationSheet;
@property (weak) IBOutlet NSTextField *title;
@property (weak) IBOutlet NSTextField *message;

- (IBAction)cancel:(id)sender;
- (IBAction)replace:(id)sender;

@end
