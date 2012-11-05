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
@end

@implementation CCRTagsAndTitlesController

- (id)init;
{
    self = [super init];
    if (self) {
        _tagsToArrayOfTitlesDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - 
#pragma mark NSComboBoxDataSource
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox;
{
    // CCC, 11/4/2012. Implement.
    return 1;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index;
{
    // CCC, 11/4/2012.  implement.
    return @"zero";
}

- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)string;
{
    // CCC, 11/4/2012. Implement.
    if ([string isEqualToString:@"zero"])
        return 0;
    return NSNotFound;
}

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)string;
{
    // CCC, 11/4/2012. Implement.
    return string;
}

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
    self.titleComboBox.stringValue = @"";
    // CCC, 11/4/2012. Remember.
}

@end
