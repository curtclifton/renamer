//
//  CCRTagsAndTitlesController.m
//  Renamer
//
//  Created by Curt Clifton on 11/4/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import "CCRTagsAndTitlesController.h"

#import "CCRAppDelegate.h"

@interface CCRTagsAndTitlesController ()
@property (nonatomic, strong) NSMutableDictionary *tagsToArrayOfTitlesDictionary;

- (NSArray *)arrayBySortingArray:(NSArray *)array;
- (NSArray *)_sortedTags;
@end

@implementation CCRTagsAndTitlesController

- (id)init;
{
    self = [super init];
    if (self) {
        // any initialization needed?
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

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)string;
{
    NSArray *sourceArray = [self _sourceArrayForComboBox:aComboBox];

    NSUInteger matchingIndex = [sourceArray indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSString *object = obj;
        if ([object hasPrefix:string]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    
    if (matchingIndex == NSNotFound)
        return string;

    return sourceArray[matchingIndex];
}

#pragma mark - Public API

- (void)clearFieldsAndRemember:(BOOL)remember;
{
    NSString *tag = [CCRAppDelegate stringBySanitizingString:self.tagComboBox.stringValue];
    NSString *title = [CCRAppDelegate stringBySanitizingString:self.titleComboBox.stringValue];
    NSArray *currentTitles = self.tagsToArrayOfTitlesDictionary[tag];
    if (currentTitles == nil) {
        currentTitles = [NSArray arrayWithObject:title];
    } else {
        if ( ! [currentTitles containsObject:title])
            currentTitles = [self arrayBySortingArray:[currentTitles arrayByAddingObject:title]];
    }
    self.tagsToArrayOfTitlesDictionary[tag] = currentTitles;
    [[NSUserDefaults standardUserDefaults] setObject:self.tagsToArrayOfTitlesDictionary forKey:CCRTagsAndTitlesDictionaryPreferenceKey];
    
    self.titleComboBox.stringValue = @"";
}

#pragma mark - Private API
- (NSMutableDictionary *)tagsToArrayOfTitlesDictionary;
{
    if (_tagsToArrayOfTitlesDictionary == nil) {
        NSDictionary *tagsAndTitlesDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:CCRTagsAndTitlesDictionaryPreferenceKey];
g        if (tagsAndTitlesDictionary == nil) {
            _tagsToArrayOfTitlesDictionary = [NSMutableDictionary dictionary];
        } else {
            _tagsToArrayOfTitlesDictionary = [NSMutableDictionary dictionaryWithDictionary:tagsAndTitlesDictionary];
        }
    }
    return _tagsToArrayOfTitlesDictionary;
}

- (NSArray *)arrayBySortingArray:(NSArray *)array;
{
    return [array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (NSArray *)_sortedTags;
{
    return [self arrayBySortingArray:[self.tagsToArrayOfTitlesDictionary allKeys]];
}

@end
