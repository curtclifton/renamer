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

@interface CCRAppDelegate ()
- (void)_addURLsToSourceList:(NSArray *)urls;
- (void)_addFilenamesToSourceList:(NSArray *)filenames;
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


@end
