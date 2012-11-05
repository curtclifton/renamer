//
//  CCRTagsAndTitlesController.m
//  Renamer
//
//  Created by Curt Clifton on 11/4/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import "CCRTagsAndTitlesController.h"

@interface CCRTagsAndTitlesController ()
@property (nonatomic, strong) NSMutableDictionary *tagsToArrayOfTitlesDictionary;

- (NSArray *)_sortedTags;
@end

@implementation CCRTagsAndTitlesController

+ (NSDictionary *)_dictionaryForTesting;
{
    return @{@"regence" : @[@"privacy statement", @"explanation of benefits", @"expense ratio letter"], @"omni" : @[@"reimbursement", @"employment offer"], @"planet bike" : @[]};
}

- (id)init;
{
    self = [super init];
    if (self) {
        _tagsToArrayOfTitlesDictionary = [NSMutableDictionary dictionary];
        // CCC, 11/4/2012. For testing:
        [_tagsToArrayOfTitlesDictionary addEntriesFromDictionary:[CCRTagsAndTitlesController _dictionaryForTesting]];
    }
    return self;
}

#pragma mark - 
#pragma mark NSComboBoxDataSource
- (NSArray *)_sourceArrayForComboBox:(NSComboBox *)aComboBox;
{
    if (aComboBox == self.tagComboBox) {
        return [self _sortedTags];
    } else if (aComboBox == self.titleComboBox) {
        NSArray *titles = self.tagsToArrayOfTitlesDictionary[self.tagComboBox.stringValue];
        if (titles != nil)
            return titles;
    }
    
    return [NSArray array];
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox;
{
    return [self _sourceArrayForComboBox:aComboBox].count;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index;
{
    NSArray *sourceArray = [self _sourceArrayForComboBox:aComboBox];
    if (index >= 0 && index < sourceArray.count)
        return sourceArray[index];
    return @"";
}


- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)string;
{
    return [[self _sourceArrayForComboBox:aComboBox] indexOfObject:string];
}

//- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)string;
//{
//    // CCC, 11/4/2012. Implement.
//    return string;
//}

#pragma mark NSComboBoxDelegate
- (void)comboBoxSelectionDidChange:(NSNotification *)notification;
{
    // CCC, 11/4/2012. Is this sufficient to detect when the tag changes so that we can refresh the title?
    NSLog(@"selection did change");
}

#pragma mark NSControl delegate
- (void)controlTextDidChange:(NSNotification *)aNotification;
{
    // CCC, 11/4/2012. May need to update the title combo box if the notification's object is the tag combo box.
    [[NSApp delegate] controlTextDidChange:aNotification];
}

#pragma mark - Public API

- (void)clearFieldsAndRemember:(BOOL)remember;
{
    // CCC, 11/4/2012. Clear tag also? Perhaps not. Seems like multiple in a row with the same tag are likely.
    // CCC, 11/4/2012. Remember.
    self.titleComboBox.stringValue = @"";
}

#pragma mark - Private API
- (NSArray *)_sortedTags;
{
    return [[self.tagsToArrayOfTitlesDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

@end
