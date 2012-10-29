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
static CGFloat MinimumControlsPaneWidth = 358.0;

@interface CCRAppDelegate ()
- (void)_addURLsToSourceList:(NSArray *)urls;
- (void)_addFilenamesToSourceList:(NSArray *)filenames;
- (void)_windowDidResize:(NSNotification *)notification;
@end

@implementation CCRAppDelegate

#pragma mark -
#pragma mark NSApplicationDelegate

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename;
{
    NSLog(@"opening* %@", filename);
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

#pragma mark - Actions

- (IBAction)renameAndFile:(id)sender;
{
    NSLog(@"Rename all the things");
}

- (IBAction)open:(id)sender {
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

#pragma mark - Private API

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
    NSLog(@"Split view subviews: %@", self.splitView.subviews);
    
    NSSize sourceListSize = self.sourceListContainerView.frame.size;
    NSSize controlsPaneSize = self.controlsPaneContainerView.frame.size;
    NSLog(@"widths: %f, %f", sourceListSize.width, controlsPaneSize.width);
    
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

    NSLog(@"attempted widths: %f, %f", sourceListSize.width, controlsPaneSize.width);
    
    [self.sourceListContainerView setFrameSize:sourceListSize];
    [self.controlsPaneContainerView setFrameSize:controlsPaneSize];
    [self.splitView adjustSubviews];

    [self.sourceListContainerView setNeedsDisplay:YES];
    [self.controlsPaneContainerView setNeedsDisplay:YES];
}

@end
