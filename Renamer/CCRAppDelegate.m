//
//  CCRAppDelegate.m
//  Renamer
//
//  Created by Curt Clifton on 9/18/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import "CCRAppDelegate.h"

#import "CCRSourceList.h"
#import "CCRTagsAndTitlesController.h"
#import "NSArray-CCRExtensions.h"

NSString *CCRTagsAndTitlesDictionaryPreferenceKey = @"CCRTagsAndTitlesDictionaryPreferenceKey";

static CGFloat MinimumSourceListWidth = 120.0;
static CGFloat MinimumControlsPaneWidth = 364.0;
static NSAttributedString *shortSeparator;
static NSAttributedString *longSeparator;
static NSAttributedString *extensionSeparator;

enum {
    CCRReplacementConfirmationCancel,
    CCRReplacementConfirmationReplace,
};

@interface CCRAppDelegate ()
@property (nonatomic, strong) QLPreviewPanel *quickLookPreviewPanel;

- (void)controlTextDidChange:(NSNotification *)aNotification;

- (void)_addURLsToSourceList:(NSArray *)urls;
- (NSURL *)_selectedFileURLOrNil;

- (void)_windowDidResize:(NSNotification *)notification;
- (void)_updateEnabledState;
- (void)_moveSelectionToURL:(NSURL *)destination confirmingOverwrite:(BOOL)confirming;
@end

@implementation CCRAppDelegate

+ (void)initialize;
{
    shortSeparator = [[NSAttributedString alloc] initWithString:@"-"];
    longSeparator = [[NSAttributedString alloc] initWithString:@" - "];
    extensionSeparator = [[NSAttributedString alloc] initWithString:@"."];
}

+ (NSString *)stringBySanitizingString:(NSString *)tagOrTitleString;
{
    NSString *result = [[tagOrTitleString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    return result;
}

#pragma mark -
#pragma mark NSApplicationDelegate

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename;
{
    NSArray *filenames = [NSArray arrayWithObject:filename];
    [self addPathsToSourceList:filenames];
    return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames;
{
    [self addPathsToSourceList:filenames];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender;
{
    return YES;
}

// CCC, 10/28/2012. Use restorable state stuff to squirrel away security scoped bookmarks for the source list URLs. See also NSWindowRestoration.h.
/*
 
 - (void)application:(NSApplication *)app willEncodeRestorableState:(NSCoder *)coder;
 {
 //    NSArray *bookmarks = [urls arrayByMappingBlock:^id(id object) {
 //        NSError *error;
 //        NSData *bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
 //
 //        if (bookmark == nil) {
 //            NSLog(@"error creating security-scoped bookmark: %@", error);
 //        }
 //
 //        return bookmark;
 //    }];
 }
 
- (void)application:(NSApplication *)app didDecodeRestorableState:(NSCoder *)coder;
 {
 }
 */

- (void)applicationWillFinishLaunching:(NSNotification *)notification;
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowDidResize:) name:NSWindowDidResizeNotification object:self.window];
    [self.sourceListTableView registerForDraggedTypes:@[NSFilenamesPboardType]];
    [self _updateEnabledState];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
{
    NSDictionary *tagsAndTitlesDictionary = @{}; // CCC, 11/6/2012.  @{@"regence" : @[@"expense ratio letter", @"explanation of benefits", @"privacy statement"], @"omni" : @[@"employment offer", @"reimbursement"], @"planet bike" : @[]};
    NSDictionary *appDefaults = @{CCRTagsAndTitlesDictionaryPreferenceKey : tagsAndTitlesDictionary};
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
}

- (void)applicationWillTerminate:(NSNotification *)notification;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark NSComboBoxDelegate
- (void)comboBoxWillDismiss:(NSNotification *)notification;
{
    // stringValue of the combo box isn't set when any of the delegate notifications fire, so turn the run loop once before updating the display:
    [self performSelector:@selector(_updateEnabledState) withObject:nil afterDelay:0];
}

#pragma mark NSSplitViewDelegate
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex;
{
    NSAssert(dividerIndex == 0, @"implementation assumes just one divider");
    return MAX(MinimumSourceListWidth, proposedMinimumPosition);
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex;
{
    NSAssert(dividerIndex == 0, @"implementation assumes just one divider");
    CGFloat allowedMaximumWidth = self.window.frame.size.width - MinimumControlsPaneWidth;
    return MIN(allowedMaximumWidth, proposedMaximumPosition);
}

#pragma mark NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification;
{
    [self _updateEnabledState];
}

- (NSString *)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation;
{
    return [[self.sourceList urlForRow:row] path];
}

#pragma mark - Quick Look support
#pragma mark QLPreviewPanelController
- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel;
{
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel;
{
    self.quickLookPreviewPanel = panel;
    panel.delegate = self;
    panel.dataSource = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel;
{
    panel.delegate = nil;
    panel.dataSource = nil;
    self.quickLookPreviewPanel = nil;
}

#pragma mark QLPreviewPanelDataSource

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel;
{
    // CCC, 11/4/2012. May eventually want to use the source list as the data source for this so you can page through the items?
    if ([self _selectedFileURLOrNil] == nil)
        return 0;
    return 1;
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index;
{
    NSAssert(panel == self.quickLookPreviewPanel, @"expected our panel: %@, got: %@", self.quickLookPreviewPanel, panel);
    NSAssert(index == 0, @"we currently only vend a single preview, but were asked for preview %ld", index);
    
    return [self _selectedFileURLOrNil];
}

#pragma mark QLPreviewPanelDelegate
- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item;
{
    NSAssert(panel == self.quickLookPreviewPanel, @"expected our panel: %@, got: %@", self.quickLookPreviewPanel, panel);
    NSAssert(item == [self _selectedFileURLOrNil], @"expected our selection: %@, got item: %@", [self _selectedFileURLOrNil], item);

    NSRect selectionRect = [self.sourceListTableView rectOfRow:self.sourceListTableView.selectedRow];
    selectionRect = [self.sourceListTableView convertRect:selectionRect toView:nil];
    return [self.window convertRectToScreen:selectionRect];
}

#pragma mark - Actions

#pragma mark Main Window

- (IBAction)renameAndFile:(id)sender;
{
    if (self.destinationDirectory != nil) {
        NSURL *destination = [self.destinationDirectory URLByAppendingPathComponent:self.computedNameTextField.stringValue];
        [self _moveSelectionToURL:destination confirmingOverwrite:YES];
        return;
    }

    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldLabel:NSLocalizedString(@"New Name:", @"label for name field in save panel")];
    [savePanel setNameFieldStringValue:self.computedNameTextField.stringValue];
    
    [savePanel setExtensionHidden:NO];
    NSString *pathExtension = [[self _selectedFileURLOrNil] pathExtension];
    [savePanel setAllowedFileTypes:@[pathExtension]];
    [savePanel setAllowsOtherFileTypes:NO];
    [savePanel setPrompt:NSLocalizedString(@"Rename", @"label for button in save panel")];
    
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        [self _moveSelectionToURL:[savePanel URL] confirmingOverwrite:NO];
    }];
}

- (IBAction)open:(id)sender;
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setMessage:NSLocalizedString(@"Choose files to be renamed.", @"Open sheet message")];
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        NSArray *urls = [openPanel URLs];
        [self _addURLsToSourceList:urls];
    }];
}

- (IBAction)quicklook:(id)sender;
{
    [self quickLookSelection];
}

- (IBAction)chooseDestination:(id)sender;
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseFiles:NO];
    [openPanel setMessage:NSLocalizedString(@"Choose the destination directory for renamed files.", @"Open sheet message")];
    [openPanel setPrompt:NSLocalizedString(@"Set Destination", @"Open sheet prompt")];
    if (self.destinationDirectory)
        [openPanel setDirectoryURL:self.destinationDirectory];

    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        self.destinationDirectory = [openPanel URL];
        [self _updateEnabledState];
    }];
}

- (IBAction)includeDayChanged:(id)sender;
{
    [self _updateEnabledState];
}

#pragma mark Replacement Confirmation Sheet

// CCC, 11/3/2012. Rename these actions to include replacement confirmation in name.
- (IBAction)cancelReplacementConfirmation:(id)sender {
    [NSApp endSheet:self.replacementConfirmationSheet returnCode:CCRReplacementConfirmationCancel];
}

- (IBAction)replaceReplacementConfirmation:(id)sender {
    [NSApp endSheet:self.replacementConfirmationSheet returnCode:CCRReplacementConfirmationReplace];
}

- (void)_replacementConfirmationSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
{
    NSURL *destination = (NSURL *)CFBridgingRelease(contextInfo);
    [sheet orderOut:self];
    if (returnCode == CCRReplacementConfirmationReplace)
        [self _moveSelectionToURL:destination confirmingOverwrite:NO];
}

- (void)_configureReplacementConfirmationSheetForDestination:(NSURL *)destination;
{
    if (!self.replacementConfirmationSheet) {
        [NSBundle loadNibNamed:@"ReplacementConfirmation" owner:self];
        NSView *sheetContentView = self.replacementConfirmationSheet.contentView;
        NSLog(@"sheetContentView constraints: %@", sheetContentView.constraints);
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:sheetContentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.replaceButton attribute:NSLayoutAttributeBottom multiplier:1 constant:20];
        heightConstraint.priority = NSLayoutPriorityDefaultHigh;
        [sheetContentView addConstraint:heightConstraint];
    }
    NSAssert(self.replacementConfirmationSheet != nil, @"expected to have sheet window loaded");
    
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"“%@” already exists. Do you want to replace it?", @"replacement confirmation sheet"), [destination lastPathComponent]];
    self.title.stringValue = title;
    
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"A file or folder with the same name already exists in the folder %@. Replacing it will overwrite its current contents.", @"replacement confirmation sheet"), [[destination URLByDeletingLastPathComponent] lastPathComponent]];
    self.message.stringValue = message;
}

#pragma mark Other Public API
- (void)quickLookSelection;
{
    if ([self _selectedFileURLOrNil] == nil) {
        NSBeep();
        return;
    }
    [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
}

- (void)addPathsToSourceList:(NSArray *)filenames;
{
    NSArray *urls = [filenames arrayByMappingBlock:^id(id object) {
        return [NSURL fileURLWithPath:object];
    }];
    
    [self _addURLsToSourceList:urls];
}

- (void)removeSelectedItem;
{
    if ([self _selectedFileURLOrNil] == nil) {
        NSBeep();
        return;
    }

    [self _removeURLFromSourceList:[self _selectedFileURLOrNil]];
}

#pragma mark - Private API

- (void)controlTextDidChange:(NSNotification *)aNotification;
{
    [self _updateEnabledState];
}

- (void)_addURLsToSourceList:(NSArray *)urls;
{
    // CCC, 11/3/2012. Whenever we add URLs from the list we should manage the selection.
    [self.sourceList addURLs:urls];
    [self.sourceListTableView reloadData];
}

- (NSURL *)_selectedFileURLOrNil;
{
    if (self.sourceListTableView.selectedRow < 0)
        return nil;
    return [self.sourceList urlForRow:self.sourceListTableView.selectedRow];
}

- (void)_windowDidResize:(NSNotification *)notification;
{
    NSSize sourceListSize = self.sourceListContainerView.frame.size;
    NSSize controlsPaneSize = self.controlsPaneContainerView.frame.size;
    
    if (sourceListSize.width >= MinimumSourceListWidth && controlsPaneSize.width >= MinimumControlsPaneWidth)
        return;
    
    NSAssert(sourceListSize.width >= MinimumSourceListWidth || controlsPaneSize.width >= MinimumControlsPaneWidth, @"Minimum window size is set wrong if this is violated");
    
    if (sourceListSize.width < MinimumSourceListWidth) {
        sourceListSize.width = MAX(sourceListSize.width, MinimumSourceListWidth);
        controlsPaneSize.width = self.window.frame.size.width - sourceListSize.width;
    } else if (controlsPaneSize.width < MinimumControlsPaneWidth) {
        controlsPaneSize.width = MAX(controlsPaneSize.width, MinimumControlsPaneWidth);
        sourceListSize.width = self.window.frame.size.width - controlsPaneSize.width;
    }

    [self.sourceListContainerView setFrameSize:sourceListSize];
    [self.controlsPaneContainerView setFrameSize:controlsPaneSize];
    [self.splitView adjustSubviews];

    [self.sourceListContainerView setNeedsDisplay:YES];
    [self.controlsPaneContainerView setNeedsDisplay:YES];
}

- (BOOL)_validateAndAppendDecimalTextFieldValue:(NSTextField *)textField minimum:(NSInteger)minValue maximum:(NSInteger)maxValue attributedString:(NSMutableAttributedString *)string errorString:(NSString *)errorString;
{
    NSInteger value = [textField integerValue];
    NSAttributedString *stringToAppend;
    BOOL valid;
    if (value < minValue || value > maxValue) {
        stringToAppend = [[NSAttributedString alloc] initWithString:errorString attributes:@{NSForegroundColorAttributeName:[NSColor redColor]}];
        valid = NO;
    } else {
        NSInteger numberOfDigits = [errorString length];
        NSString *padding = [@"" stringByPaddingToLength:numberOfDigits withString:@"0" startingAtIndex:0];
        NSString *paddedValue = [padding stringByAppendingString:[NSString stringWithFormat:@"%ld", value]];
        NSString *clippedValue = [paddedValue substringFromIndex:[paddedValue length] - numberOfDigits];
        stringToAppend = [[NSAttributedString alloc] initWithString:clippedValue];
        valid = YES;
    }
    [string appendAttributedString:stringToAppend];
    return valid;
}

- (BOOL)_validateAndAppendComboBoxValue:(NSComboBox *)comboBox attributedString:(NSMutableAttributedString *)string errorString:(NSString *)errorString;
{
    NSString *boxValue = [CCRAppDelegate stringBySanitizingString:comboBox.stringValue];
    NSAttributedString *stringToAppend;
    BOOL valid;
    if ([boxValue length] == 0) {
        stringToAppend = [[NSAttributedString alloc] initWithString:errorString attributes:@{NSForegroundColorAttributeName:[NSColor redColor]}];
        valid = NO;
    } else {
        stringToAppend = [[NSAttributedString alloc] initWithString:boxValue];
        valid = YES;
    }
    
    [string appendAttributedString:stringToAppend];
    return valid;
}

- (NSInteger)_daysInMonth;
{
    NSInteger year = self.yearTextField.integerValue;
    NSInteger month = self.monthTextField.integerValue;
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:year];
    [components setMonth:month];
    [components setDay:1];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSRange range = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:[calendar dateFromComponents:components]];
    return range.length;
}

- (void)_updateEnabledState;
{
    NSURL *selectedFileURL = [self _selectedFileURLOrNil];
    self.enableControls = selectedFileURL != nil;
    
    BOOL fieldsValid = YES;
    if (self.enableControls) {
        NSMutableAttributedString *computedName = [[NSMutableAttributedString alloc] initWithString:@""];

        fieldsValid = [self _validateAndAppendDecimalTextFieldValue:self.yearTextField minimum:1 maximum:9999 attributedString:computedName errorString:@"yyyy"] && fieldsValid;
        [computedName appendAttributedString:shortSeparator];
        fieldsValid = [self _validateAndAppendDecimalTextFieldValue:self.monthTextField minimum:1 maximum:12 attributedString:computedName errorString:@"mm"] && fieldsValid;
        
        if (self.includeDayCheckbox.state == NSOnState) {
            [computedName appendAttributedString:shortSeparator];
            
            NSInteger daysInMonth = fieldsValid ? [self _daysInMonth] : 31;
            fieldsValid = [self _validateAndAppendDecimalTextFieldValue:self.dayTextField minimum:1 maximum:daysInMonth attributedString:computedName errorString:@"dd"] && fieldsValid;
        }
        
        [computedName appendAttributedString:longSeparator];
        fieldsValid = [self _validateAndAppendComboBoxValue:self.tagComboBox attributedString:computedName errorString:NSLocalizedString(@"missing tag", @"error message embedded in computed name")] && fieldsValid;
        [computedName appendAttributedString:longSeparator];
        fieldsValid = [self _validateAndAppendComboBoxValue:self.titleComboBox attributedString:computedName errorString:NSLocalizedString(@"missing title", @"error message embedded in computed name")] && fieldsValid;
        
        NSString *fileExtension = [selectedFileURL pathExtension];
        if (fileExtension && ! [fileExtension isEqualToString:@""]) {
            [computedName appendAttributedString:extensionSeparator];
            [computedName appendAttributedString:[[NSAttributedString alloc] initWithString:fileExtension]];
        }
        
        [self.computedNameTextField setAttributedStringValue:computedName];
    } else {
        [self.computedNameTextField setStringValue:@"—"];
    }
    
    [self.renameAndFileButton setEnabled:self.enableControls && fieldsValid];

}

- (void)_removeURLFromSourceList:(NSURL *)url;
{
    NSInteger selectedItemIndex = self.sourceListTableView.selectedRow;

    [self.sourceList removeURL:url];
    [self.sourceListTableView reloadData];
    
    if (selectedItemIndex < self.sourceListTableView.numberOfRows) {
        NSIndexSet *selectionIndexSet = [NSIndexSet indexSetWithIndex:selectedItemIndex];
        [self.sourceListTableView selectRowIndexes:selectionIndexSet byExtendingSelection:NO];
    } else if (selectedItemIndex == self.sourceListTableView.numberOfRows) {
        NSIndexSet *selectionIndexSet = [NSIndexSet indexSetWithIndex:self.sourceListTableView.numberOfRows - 1];
        [self.sourceListTableView selectRowIndexes:selectionIndexSet byExtendingSelection:NO];
    }
}

- (void)_renameCompletedForURL:(NSURL *)url;
{
    [self.tagsAndTItlesController clearFieldsAndRemember:YES];
    [self _removeURLFromSourceList:url];
}

- (void)_moveSelectionToURL:(NSURL *)destination confirmingOverwrite:(BOOL)confirming;
{
    NSURL *urlOfFIleToRename = [self _selectedFileURLOrNil];
    NSAssert(urlOfFIleToRename != nil, @"Must have a file to rename");
    NSAssert(destination != nil, @"Must have a destination");
    NSAssert(self.enableControls, @"Controls must be enabled");
    NSAssert([[urlOfFIleToRename pathExtension] isEqualToString:[destination pathExtension]], @"file extensions must match");
    
    if ([[urlOfFIleToRename absoluteString] isEqualToString:[destination absoluteString]]) {
        [self _renameCompletedForURL:urlOfFIleToRename];
        return;
    }
    
    // First attempt does this synchronously without any coordination. May need to use file coordination for this ultimately.    
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    if ([destination checkResourceIsReachableAndReturnError:&error]) {
        if (confirming) {
            CFTypeRef context = CFBridgingRetain(destination);
            [self _configureReplacementConfirmationSheetForDestination:destination];
            [NSApp beginSheet:self.replacementConfirmationSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(_replacementConfirmationSheetDidEnd:returnCode:contextInfo:) contextInfo:(void *)context];
            return; // We'll get called again with confirming == NO if they choose to replace.
        }
        if ( ! [manager removeItemAtURL:destination error:&error]) {
            // CCC, 11/3/2012. This is crappy, but better than nothing for now.
            // CCC, 11/3/2012. Localize.
            NSBeginAlertSheet(@"Unable to Remove Existing File", @"Drat", nil, nil, self.window, nil, NULL, NULL, NULL, @"Sorry. An error occurred while trying to delete the existing file: %@", error);
            return;
        }
    }
    
    BOOL success = [manager moveItemAtURL:urlOfFIleToRename toURL:destination error:&error];
    if (!success) {
        // CCC, 11/3/2012. This is crappy, but better than nothing for now.
        // CCC, 11/3/2012. Localize.
        NSBeginAlertSheet(@"Unable to Rename File", @"Drat", nil, nil, self.window, nil, NULL, NULL, NULL, @"Sorry. An error occurred while trying to rename the file: %@", error);
        return;
    }

    [self _renameCompletedForURL:urlOfFIleToRename];
}
@end
