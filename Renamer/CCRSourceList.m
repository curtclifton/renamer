//
//  CCRSourceList.m
//  Renamer
//
//  Created by Curt Clifton on 10/28/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import "CCRSourceList.h"

@interface CCRSourceList ()
@property (nonatomic, strong) NSMutableArray *sourceURLs;
@end

@implementation CCRSourceList

#pragma mark Initialization

- (id)init
{
    self = [super init];
    if (self) {
        _sourceURLs = [NSMutableArray new];
    }
    return self;
}

#pragma mark - 
#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
{
    return [self.sourceURLs count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
{
    if (row < 0 || row >= [self.sourceURLs count]) {
        NSLog(@"Unexpected row index: %ld", row);
        return nil;
    }
    
    NSURL *url = self.sourceURLs[row];
    return [url lastPathComponent];
}

#pragma mark NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification;
{
    // CCC, 10/28/2012. Implement. Want to enable/initialize renaming UI if we have a selection.
    NSLog(@"In %@, with notification: %@", NSStringFromSelector(_cmd), notification);
}

- (void)tableViewSelectionIsChanging:(NSNotification *)notification;
{
    // CCC, 10/28/2012. Implement. Want to disable renaming UI.
    NSLog(@"In %@, with notification: %@", NSStringFromSelector(_cmd), notification);
}

- (NSString *)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation;
{
    NSURL *url = self.sourceURLs[row];
    return [url path];
}

#pragma mark - Public API
- (void)addURLs:(NSArray *)urls;
{
    for (id object in urls) {
        NSAssert([object isKindOfClass:[NSURL class]], @"expect objects to be URLs: %@", object);
    }
    
    // Unique and sort.
    NSArray *sortedURLs = [urls sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return NSOrderedSame;
    }];
    
    // CCC, 10/28/2012. HERE: do the merge pass of merge sort.
    [self.sourceURLs addObjectsFromArray:sortedURLs];
}

@end
