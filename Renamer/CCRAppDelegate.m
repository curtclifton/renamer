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
- (void)_windowDidResize:(NSNotification *)notification;
- (void)_updateEnabledState;
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
        // CCC, 11/1/2012. Prompt for save location.
        return;
    }

    // CCC, 11/1/2012. just do it.
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
    // Throw up a sheet with a QLPreviewView. See headers: no docs still.
    NSLog(@"quicklook the thing: %@", [self.sourceList urlForRow:self.sourceListTableView.selectedRow]);
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

- (BOOL)_validateAndAppendComboBoxValue:(NSComboBox *)comboBox attributedString:(NSMutableAttributedString *)string errorString:(NSString *)errorString;
{
    NSString *boxValue = [comboBox.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSAttributedString *stringToAppend;
    BOOL valid;
    if ([boxValue length] == 0) {
        // append error string
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

- (void)_updateEnabledState;
{
    self.enableControls = [self.sourceListTableView selectedRow] >= 0;
    
    // CCC, 10/29/2012. Validate fields also:
    BOOL fieldsValid = YES;
    if (self.enableControls) {
        NSMutableAttributedString *computedName = [[NSMutableAttributedString alloc] initWithString:@""];

        // CCC, 11/1/2012. Break out helper methods for adding and validating the substrings.
        [computedName appendAttributedString:[[NSAttributedString alloc] initWithString:self.yearTextField.stringValue]];
        [computedName appendAttributedString:shortSeparator];
        [computedName appendAttributedString:[[NSAttributedString alloc] initWithString:self.monthTextField.stringValue]];
        
        if (self.includeDayCheckbox.state == NSOnState) {
            [computedName appendAttributedString:shortSeparator];
            [computedName appendAttributedString:[[NSAttributedString alloc] initWithString:self.dayTextField.stringValue]];
        }
        
        [computedName appendAttributedString:longSeparator];
        fieldsValid = [self _validateAndAppendComboBoxValue:self.tagComboBox attributedString:computedName errorString:NSLocalizedString(@"missing tag", @"error message embedded in computed name")] && fieldsValid;
        [computedName appendAttributedString:longSeparator];
        fieldsValid = [self _validateAndAppendComboBoxValue:self.titleComboBox attributedString:computedName errorString:NSLocalizedString(@"missing title", @"error message embedded in computed name")] && fieldsValid;
        
        [self.computedNameTextField setAttributedStringValue:computedName];
    } else {
        [self.computedNameTextField setStringValue:@"—"];
    }
    
    [self.renameAndFileButton setEnabled:self.enableControls && fieldsValid];

}

@end
