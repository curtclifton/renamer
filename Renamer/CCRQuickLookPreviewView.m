//
//  CCRQuickLookPreviewView.m
//  Renamer
//
//  Created by Curt Clifton on 12/2/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import "CCRQuickLookPreviewView.h"

@implementation CCRQuickLookPreviewView

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize;
{
    [super resizeWithOldSuperviewSize:oldSize];
    NSView *subview = self.subviews[0];
    [subview setFrameSize:self.frame.size];
}

@end
