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
    NSMutableSet *currentURLs = [NSMutableSet setWithArray:self.sourceURLs];
    [currentURLs addObjectsFromArray:urls];
    
    NSArray *sortedURLs = [[currentURLs allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSURL *url1 = obj1;
        NSURL *url2 = obj2;
        return [[url1 lastPathComponent] localizedStandardCompare:[url2 lastPathComponent]];
    }];
    
    self.sourceURLs = [NSMutableArray arrayWithArray:sortedURLs];
}

@end
