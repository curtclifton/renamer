//
//  CCRAppDelegate.h
//  Renamer
//
//  Created by Curt Clifton on 9/18/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

extern NSString *CCRTagsAndTitlesDictionaryPreferenceKey;
extern NSString *CCRSourceBookmarksRestorationCoderKey;

@class CCRSourceList, CCRTagsAndTitlesController;

@interface CCRAppDelegate : NSObject <NSApplicationDelegate, NSComboBoxDelegate, NSSplitViewDelegate, NSTableViewDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate>

// class methods
+ (NSString *)stringBySanitizingString:(NSString *)tagOrTitleString;

// bindings
@property (nonatomic) BOOL enableControls;
// CCC, 11/11/2012. Delete if you decide to remove the UI for showing this:
@property (nonatomic, strong) NSURL *destinationDirectory;

// main app window
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet CCRSourceList *sourceList;
@property (weak) IBOutlet NSTableView *sourceListTableView;
@property (weak) IBOutlet NSSplitView *splitView;
@property (weak) IBOutlet NSView *sourceListContainerView;
@property (weak) IBOutlet NSView *controlsPaneContainerView;
@property (weak) IBOutlet NSView *previewContainerView;
@property (weak) IBOutlet CCRTagsAndTitlesController *tagsAndTItlesController;
@property (weak) IBOutlet NSButton *renameAndFileButton;
@property (weak) IBOutlet NSTextField *computedNameTextField;

@property (weak) IBOutlet NSTextField *yearTextField;
@property (weak) IBOutlet NSTextField *monthTextField;
@property (weak) IBOutlet NSTextField *dayTextField;
@property (weak) IBOutlet NSButton *includeDayCheckbox;
@property (weak) IBOutlet NSComboBox *tagComboBox;
@property (weak) IBOutlet NSComboBox *titleComboBox;

- (IBAction)renameAndFile:(id)sender;
- (IBAction)open:(id)sender;
- (IBAction)quicklook:(id)sender;
- (IBAction)includeDayChanged:(id)sender;

// other API
- (void)quickLookSelection;
- (void)addPathsToSourceList:(NSArray *)filenames;
- (void)removeSelectedItem;

@end
