//
//  CCRSourceListTableView.m
//  Renamer
//
//  Created by Curt Clifton on 11/4/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import "CCRSourceListTableView.h"

#import "CCRAppDelegate.h"

@implementation CCRSourceListTableView

- (void)keyDown:(NSEvent *)theEvent;
{
    NSString* key = [theEvent charactersIgnoringModifiers];
    
    if ([key isEqualToString:@" "]) {
        [[NSApp delegate] quickLookSelection];
        return;
    } else if (theEvent.keyCode == 51) { // delete
        [[NSApp delegate] removeSelectedItem];
        return;
    }
    [super keyDown:theEvent];
}
@end
