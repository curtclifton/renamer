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
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox;
{
    if (aComboBox == self.tagComboBox) {
        return self.tagsToArrayOfTitlesDictionary.count;
    } else if (aComboBox == self.titleComboBox) {
        NSArray *titles = self.tagsToArrayOfTitlesDictionary[self.tagComboBox.stringValue];
        if (titles == nil)
            return 0;
        else
            return titles.count;
    }

    // During initial construction of the view hierarchy, we can get called before we have our combo box properties set, so…
    return 0;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index;
{
    if (aComboBox == self.tagComboBox) {
        return [self _sortedTags][index];
    } else if (aComboBox == self.titleComboBox) {
        NSArray *titles = self.tagsToArrayOfTitlesDictionary[self.tagComboBox.stringValue];
        if (titles == nil)
            return @"";
        else
            return titles[index];
    }
    
    // During initial construction of the view hierarchy, we can get called before we have our combo box properties set, so…
    return @"";
}


//- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)string;
//{
//    // CCC, 11/4/2012. Implement.
//    if ([string isEqualToString:@"zero"])
//        return 0;
//    return NSNotFound;
//}
//
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
