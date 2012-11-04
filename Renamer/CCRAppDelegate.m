//
//  CCRAppDelegate.m
//  Renamer
//
//  Created by Curt Clifton on 9/18/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import "CCRAppDelegate.h"

#import "CCRSourceList.h"
#import "NSArray-CCRExtensions.h"

static CGFloat MinimumSourceListWidth = 120.0;
static CGFloat MinimumControlsPaneWidth = 364.0;
static NSAttributedString *shortSeparator;
static NSAttributedString *longSeparator;

@interface CCRAppDelegate ()
- (void)controlTextDidChange:(NSNotification *)aNotification;

- (void)_addURLsToSourceList:(NSArray *)urls;
- (void)_addFilenamesToSourceList:(NSArray *)filenames;
- (NSURL *)_selectedFileURLOrNil;

- (void)_windowDidResize:(NSNotification *)notification;
- (void)_updateEnabledState;
- (void)_moveSelectionToURL:(NSURL *)destination;
@end

@implementation CCRAppDelegate

+ (void)initialize;
{
    shortSeparator = [[NSAttributedString alloc] initWithString:@"-"];
    longSeparator = [[NSAttributedString alloc] initWithString:@" - "];
}

#pragma mark -
#pragma mark NSApplicationDelegate

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename;
{
    NSArray *filenames = [NSArray arrayWithObject:filename];
    [self _addFilenamesToSourceList:filenames];
    return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames;
{
    [self _addFilenamesToSourceList:filenames];
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

- (void)applicationWillTerminate:(NSNotification *)notification;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

#pragma mark - Actions

- (IBAction)renameAndFile:(id)sender;
{
    NSLog(@"Rename all the things");
    if (self.destinationDirectory != nil) {
        NSURL *destination = [self.destinationDirectory URLByAppendingPathComponent:self.computedNameTextField.stringValue];
        [self _moveSelectionToURL:destination];
        return;
    }

    // CCC, 11/3/2012. should you be calling setMessage: on every panel, open and save?
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldLabel:NSLocalizedString(@"New name", @"label for name field in save panel")];
    [savePanel setNameFieldStringValue:self.computedNameTextField.stringValue];
    // CCC, 11/3/2012. File extension handling?
    [savePanel setPrompt:NSLocalizedString(@"Rename", @"label for button in save panel")];
    
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        [self _moveSelectionToURL:[savePanel URL]];
    }];
}

- (IBAction)open:(id)sender;
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:YES];
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        NSArray *urls = [openPanel URLs];
        [self _addURLsToSourceList:urls];
    }];
}

- (IBAction)quicklook:(id)sender;
{
    // CCC, 11/3/2012. Implement.
    // Throw up a sheet with a QLPreviewView. See headers: no docs still.
    NSLog(@"quicklook the thing: %@", [self _selectedFileURLOrNil]);
}

- (IBAction)chooseDestination:(id)sender;
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseFiles:NO];
    
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

#pragma mark - Private API

- (void)controlTextDidChange:(NSNotification *)aNotification;
{
    [self _updateEnabledState];
}

- (void)_addURLsToSourceList:(NSArray *)urls;
{
    [self.sourceList addURLs:urls];
    [self.sourceListTableView reloadData];
}

- (void)_addFilenamesToSourceList:(NSArray *)filenames;
{
    NSArray *urls = [filenames arrayByMappingBlock:^id(id object) {
        return [NSURL fileURLWithPath:object];
    }];
    
    [self _addURLsToSourceList:urls];
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
    NSString *boxValue = [comboBox.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSAttributedString *stringToAppend;
    BOOL valid;
    if ([boxValue length] == 0) {
        stringToAppend = [[NSAttributedString alloc] initWithString:errorString attributes:@{NSForegroundColorAttributeName:[NSColor redColor]}];
        valid = NO;
    } else {
        boxValue = [boxValue lowercaseString];
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
    NSLog(@"range: %@", NSStringFromRange(range));
    return range.length;
}

- (void)_updateEnabledState;
{
    self.enableControls = [self _selectedFileURLOrNil] != nil;
    
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
        
        // CCC, 11/3/2012. Get extension from source and append to string.
        [self.computedNameTextField setAttributedStringValue:computedName];
    } else {
        [self.computedNameTextField setStringValue:@"—"];
    }
    
    [self.renameAndFileButton setEnabled:self.enableControls && fieldsValid];

}

- (void)_moveSelectionToURL:(NSURL *)destination;
{
    NSURL *urlOfFIleToRename = [self _selectedFileURLOrNil];
    NSAssert(urlOfFIleToRename != nil, @"Must have a file to rename");
    NSAssert(destination != nil, @"Must have a destination");
    NSAssert(self.enableControls, @"Controls must be enabled");
    // CCC, 11/3/2012. Assert that the extension is right on the destination.
    
    NSLog(@"Renaming %@ to %@ and storing in %@", urlOfFIleToRename, self.computedNameTextField.stringValue, destination);
    // CCC, 11/3/2012. do it!
    
    // CCC, 11/3/2012. Remove item from source list.
}
@end
