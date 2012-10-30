//
//  CCRSourceList.m
//  Renamer
//
//  Created by Curt Clifton on 10/28/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import "CCRSourceList.h"

#import "NSArray-CCRExtensions.h"

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

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation;
{
    switch (dropOperation) {
        case NSTableViewDropAbove:
            return NSDragOperationMove;
        case NSTableViewDropOn:
        default:
            return NSDragOperationNone;
    }
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation;
{
    NSLog(@"acceptDrop info: %@, row: %ld", info, row);
    NSLog(@"drop operation %@", dropOperation == NSTableViewDropAbove ? @"Above" : @"On");
    
    NSPasteboard *draggingPasteboard = [info draggingPasteboard];
    if ([[draggingPasteboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [draggingPasteboard propertyListForType:NSFilenamesPboardType];
        NSArray *urls = [files arrayByMappingBlock:^id(id object) {
            return [NSURL fileURLWithPath:object];
        }];
        [self addURLs:urls];
        [tableView reloadData];
    }
    
    return YES;
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

- (NSURL *)urlForRow:(NSInteger)row;
{
    return self.sourceURLs[row];
}
@end
