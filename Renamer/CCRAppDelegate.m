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
NSString *CCRDestinationDirectoryBookmarkPreferenceKey = @"CCRDestinationDirectoryBookmarkPreferenceKey";
NSString *CCRSourceDirectoryBookmarkPreferenceKey = @"CCRSoruceDirectoryBookmarkPreferenceKey";

static const BOOL PreviewResizeRadarIsFixed = NO; // CCC, 12/2/2012. File radar.

static CGFloat MinimumSourceListWidth = 120.0;
static CGFloat MinimumControlsPaneWidth = 364.0;

static NSInteger SoLastCentury = 69;

static NSAttributedString *shortSeparator;
static NSAttributedString *longSeparator;
static NSAttributedString *extensionSeparator;

enum {
    CCRReplacementConfirmationCancel,
    CCRReplacementConfirmationReplace,
};

typedef NSInteger(^DecimalValueTransformer)(NSInteger);

@interface CCRAppDelegate ()
@property (nonatomic, strong) QLPreviewPanel *quickLookPreviewPanel;
@property (nonatomic, strong) QLPreviewView *quickLookPreviewView;
@property (nonatomic) BOOL windowIsInLiveResize;

- (void)_guessValueForIncludeDayCheckbox;
- (void)controlTextDidChange:(NSNotification *)aNotification;

- (void)_addURLsToSourceList:(NSArray *)urls;
- (NSURL *)_selectedFileURLOrNil;

- (void)_maintainSplitViewSizeDuringWindowResize;

- (NSURL *)_directoryForPreferenceKey:(NSString *)preferenceKey;
- (void)_setDirectory:(NSURL *)updatedURL forPreferenceKey:(NSString *)preferenceKey previousDirectory:(NSURL *)previousURL;

- (BOOL)_validateAndAppendDecimalTextFieldValue:(NSTextField *)textField minimum:(NSInteger)minValue maximum:(NSInteger)maxValue attributedString:(NSMutableAttributedString *)string errorString:(NSString *)errorString transform:(DecimalValueTransformer) transformer;

- (void)_updateEnabledState;
- (void)_moveSelectionToURL:(NSURL *)destination;
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

- (void)applicationWillFinishLaunching:(NSNotification *)notification;
{
    [self.sourceListTableView registerForDraggedTypes:@[NSFilenamesPboardType]];
    
    self.quickLookPreviewView = [[QLPreviewView alloc] initWithFrame:self.previewContainerView.bounds style:QLPreviewViewStyleCompact];
    [self.quickLookPreviewView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [self.previewContainerView addSubview:self.quickLookPreviewView];
    // CCC, 12/2/2012. Set a default previewItem in the view.
    
    [self _guessValueForIncludeDayCheckbox];
    [self _updateEnabledState];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
{
    NSDictionary *tagsAndTitlesDictionary = @{}; 
    NSData *destinationDirectoryEmptyBookmark = [NSData data];
    NSData *sourceDirectoryEmptyBookmark = [NSData data];
    NSDictionary *appDefaults = @{CCRTagsAndTitlesDictionaryPreferenceKey : tagsAndTitlesDictionary, CCRDestinationDirectoryBookmarkPreferenceKey : destinationDirectoryEmptyBookmark, CCRSourceDirectoryBookmarkPreferenceKey : sourceDirectoryEmptyBookmark};
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
    NSAssert(notification.object == self.sourceListTableView, @"Expected source list table view, got %@", notification.object);
    
    NSURL *selectedURL = [self _selectedFileURLOrNil];
    if (selectedURL == nil) {
        // CCC, 12/2/2012. Set default preview image.
        self.quickLookPreviewView.previewItem = nil;
    } else {
        self.quickLookPreviewView.previewItem = selectedURL;
    }
    
    [self _updateEnabledState];
}

- (NSString *)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation;
{
    return [[self.sourceList urlForRow:row] path];
}

#pragma mark NSWindowDelegate

- (void)windowDidResize:(NSNotification *)notification;
{
    if (notification.object != self.window) // as the preview panel's delegate, we get its notifications too
        return;
    
    if (!PreviewResizeRadarIsFixed) {
        // CCC, 12/2/2012. Maybe we can subclass QLPreviewView and do something in the resize methods instead.
        if (!self.windowIsInLiveResize)
            [self.quickLookPreviewView refreshPreviewItem];
    }
    
    [self _maintainSplitViewSizeDuringWindowResize];
}

- (void)windowWillStartLiveResize:(NSNotification *)notification;
{
    if (notification.object != self.window) // as the preview panel's delegate, we get its notifications too
        return;

    self.windowIsInLiveResize = YES;
}

- (void)windowDidEndLiveResize:(NSNotification *)notification;
{
    if (notification.object != self.window) // as the preview panel's delegate, we get its notifications too
        return;

    self.windowIsInLiveResize = NO;
    if (!PreviewResizeRadarIsFixed) {
        [self.quickLookPreviewView refreshPreviewItem];
    }
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

// CCC, 12/2/2012. Do you want to lose the preview panel once in-pane preview works? Or perhaps it's good to have both to get the other nicities that the panel delivers (like Open in Preview, a bigger window, paging)?
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
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldLabel:NSLocalizedString(@"New Name:", @"label for name field in save panel")];
    [savePanel setNameFieldStringValue:self.computedNameTextField.stringValue];
    
    NSURL *destinationDirectory = [self _directoryForPreferenceKey:CCRDestinationDirectoryBookmarkPreferenceKey];
    if (destinationDirectory != nil)
        [savePanel setDirectoryURL:destinationDirectory];
    
    [savePanel setExtensionHidden:NO];
    NSString *pathExtension = [[self _selectedFileURLOrNil] pathExtension];
    [savePanel setAllowedFileTypes:@[pathExtension]];
    [savePanel setAllowsOtherFileTypes:NO];
    [savePanel setPrompt:NSLocalizedString(@"Rename", @"label for button in save panel")];
    
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        NSURL *destination = [savePanel URL];
        
        NSURL *updatedDestinationDirectory = [destination URLByDeletingLastPathComponent];
        [self _setDirectory:updatedDestinationDirectory forPreferenceKey:CCRDestinationDirectoryBookmarkPreferenceKey previousDirectory:destinationDirectory];
        
        [self _moveSelectionToURL:destination];
    }];
}

- (IBAction)open:(id)sender;
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:YES];
    
    NSURL *sourceDirectory = [self _directoryForPreferenceKey:CCRSourceDirectoryBookmarkPreferenceKey];
    if (sourceDirectory)
        [openPanel setDirectoryURL:sourceDirectory];
    
    [openPanel setMessage:NSLocalizedString(@"Choose files to be renamed.", @"Open sheet message")];
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        NSArray *urls = [openPanel URLs];
        
        if ([urls count] > 0) {
            NSURL *updatedSourceDirectory  = [urls[0] URLByDeletingLastPathComponent];
            [self _setDirectory:updatedSourceDirectory forPreferenceKey:CCRSourceDirectoryBookmarkPreferenceKey previousDirectory:sourceDirectory];
        }
        
        [self _addURLsToSourceList:urls];
    }];
}

- (IBAction)quicklook:(id)sender;
{
    [self quickLookSelection];
}

- (IBAction)includeDayChanged:(id)sender;
{
    [self _updateEnabledState];
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

- (void)_guessValueForIncludeDayCheckbox;
{
    NSString *trimmedValue = [CCRAppDelegate stringBySanitizingString:self.dayTextField.stringValue];
    NSInteger state = [trimmedValue isEqualToString:@""] ? NSOffState : NSOnState;
    [self.includeDayCheckbox setState:state];
}

- (void)controlTextDidChange:(NSNotification *)aNotification;
{
    if (aNotification.object == self.dayTextField)
        [self _guessValueForIncludeDayCheckbox];
    [self _updateEnabledState];
}

- (void)_addURLsToSourceList:(NSArray *)urls;
{
    NSInteger selectedItemIndex = self.sourceListTableView.selectedRow;
    NSURL *selectedItemURL = [self _selectedFileURLOrNil];
    
    [self.sourceList addURLs:urls];
    [self.sourceListTableView reloadData];
    
    if (selectedItemIndex < 0 && urls != nil && [urls count] > 0) {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
        [self.sourceListTableView selectRowIndexes:indexSet byExtendingSelection:NO];
        return;
    }
    
    if (selectedItemURL != nil) {
        NSUInteger newSelectionIndex = [self.sourceList rowIndexForURL:selectedItemURL];
        if (newSelectionIndex != NSNotFound) {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:newSelectionIndex];
            [self.sourceListTableView selectRowIndexes:indexSet byExtendingSelection:NO];
        }
    }
}

- (NSURL *)_selectedFileURLOrNil;
{
    if (self.sourceListTableView.selectedRow < 0)
        return nil;
    return [self.sourceList urlForRow:self.sourceListTableView.selectedRow];
}

- (void)_maintainSplitViewSizeDuringWindowResize;
{
    NSSize sourceListSize = self.sourceListContainerView.frame.size;
    NSSize controlsPaneSize = self.controlsPaneContainerView.frame.size;
    
    if (sourceListSize.width >= MinimumSourceListWidth && controlsPaneSize.width >= MinimumControlsPaneWidth)
        return;
    
    NSAssert(!(sourceListSize.width < MinimumSourceListWidth && controlsPaneSize.width < MinimumControlsPaneWidth), @"Don't expect resizing to be able to make both subviews of the split view smaller than their minimum sizes simultaneously. Minimum window size in the nib should be at least the some of the minimum widths set in source code.");
    
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

- (NSURL *)_directoryForPreferenceKey:(NSString *)preferenceKey;
{
    NSData *destinationDirectoryBookmark = [[NSUserDefaults standardUserDefaults] objectForKey:preferenceKey];
    if (destinationDirectoryBookmark == nil || [destinationDirectoryBookmark length] == 0)
        return nil;
    
    BOOL isStale = NO;
    NSError *error = nil;
    NSURL *destinationDirectory = [NSURL URLByResolvingBookmarkData:destinationDirectoryBookmark options:NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:&isStale error:&error];
    
    if (destinationDirectory == nil)
        NSLog(@"failed to resolve URL from bookmark: %@\nerror: %@", destinationDirectoryBookmark, error);
    
    if (isStale)
        destinationDirectory = nil;
    
    return destinationDirectory;
}

- (void)_setDirectory:(NSURL *)updatedURL forPreferenceKey:(NSString *)preferenceKey previousDirectory:(NSURL *)previousURL;
{
    if ([[updatedURL absoluteString] isEqualToString:[previousURL absoluteString]])
        return;
    
    NSError *error = nil;
    NSData *destinationDirectoryBookmark = [updatedURL bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
    if (destinationDirectoryBookmark == nil) {
        NSLog(@"Failed to create bookmark for %@. Error: %@", updatedURL, error);
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:destinationDirectoryBookmark forKey:preferenceKey];
    }
}

- (BOOL)_validateAndAppendDecimalTextFieldValue:(NSTextField *)textField minimum:(NSInteger)minValue maximum:(NSInteger)maxValue attributedString:(NSMutableAttributedString *)string errorString:(NSString *)errorString transform:(DecimalValueTransformer) transformer;
{
    NSInteger value = [textField integerValue];
    BOOL fieldIsEmpty = [[CCRAppDelegate stringBySanitizingString:[textField stringValue]] length] == 0;
    if (transformer != NULL && !fieldIsEmpty)
        value = transformer(value);
    
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

        fieldsValid = [self _validateAndAppendDecimalTextFieldValue:self.yearTextField minimum:1 maximum:9999 attributedString:computedName errorString:@"yyyy" transform:^NSInteger(NSInteger inputValue) {
            if (SoLastCentury <= inputValue && inputValue < 100)
                return 1900 + inputValue;
            else if (0 <= inputValue && inputValue < SoLastCentury)
                return 2000 + inputValue;
            else
                return inputValue;
        }] && fieldsValid;
        [computedName appendAttributedString:shortSeparator];
        fieldsValid = [self _validateAndAppendDecimalTextFieldValue:self.monthTextField minimum:1 maximum:12 attributedString:computedName errorString:@"mm" transform:NULL] && fieldsValid;
        
        if (self.includeDayCheckbox.state == NSOnState) {
            [computedName appendAttributedString:shortSeparator];
            
            NSInteger daysInMonth = fieldsValid ? [self _daysInMonth] : 31;
            fieldsValid = [self _validateAndAppendDecimalTextFieldValue:self.dayTextField minimum:1 maximum:daysInMonth attributedString:computedName errorString:@"dd" transform:NULL] && fieldsValid;
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
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setAlignment:NSCenterTextAlignment];
        [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        [computedName addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, computedName.length)];
        
        [self.computedNameTextField setAttributedStringValue:computedName];
    } else {
        [self.computedNameTextField setStringValue:@""];
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
    [self.window makeFirstResponder:self.sourceListTableView];
}

- (void)_moveSelectionToURL:(NSURL *)destination;
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
        NSError *error = nil;
        BOOL removeSucceeded = [manager removeItemAtURL:destination error:&error];
        if (!removeSucceeded) {
            // CCC, 11/3/2012. This is crappy, but better than nothing for now.
            // CCC, 11/3/2012. Localize.
            NSBeginAlertSheet(@"Unable to Remove Existing File", @"Drat", nil, nil, self.window, nil, NULL, NULL, NULL, @"Sorry. An error occurred while trying to delete the existing file: %@", error);
            return;
        }
    } else if ( ! ([[error domain] isEqualToString:NSCocoaErrorDomain] && [error code] == NSFileReadNoSuchFileError)) {
        // We expect to get a NSFileReadNoSuchFileError. Anything else is an issue.
        NSLog(@"Destination unreachable for reason other than not existing: %@", error);
    }
    
    error = nil;
    BOOL renameSucceeded = [manager moveItemAtURL:urlOfFIleToRename toURL:destination error:&error];
    if (!renameSucceeded) {
        // CCC, 11/3/2012. This is crappy, but better than nothing for now.
        // CCC, 11/3/2012. Localize.
        NSBeginAlertSheet(@"Unable to Rename File", @"Drat", nil, nil, self.window, nil, NULL, NULL, NULL, @"Sorry. An error occurred while trying to rename the file: %@", error);
        return;
    }

    [self _renameCompletedForURL:urlOfFIleToRename];
}

@end
