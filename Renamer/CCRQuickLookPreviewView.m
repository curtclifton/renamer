//
//  CCRQuickLookPreviewView.m
//  Renamer
//
//  Created by Curt Clifton on 12/2/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import "CCRQuickLookPreviewView.h"

@implementation CCRQuickLookPreviewView

// This is a work-around for Radar 12794367:
- (void)updateConstraints;
{
    NSView *subview = self.subviews[0];
    
    [subview setTranslatesAutoresizingMaskIntoConstraints:NO];
    [super updateConstraints];
    
    NSString *horizontalHuggingConstraints = @"H:|-(0)-[view]-(0)-|";
    NSString *verticalHuggingConstraints = @"V:|-(0)-[view]-(0)-|";
    
    // Make subview fit to us:
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:horizontalHuggingConstraints options:0 metrics:nil views:@{@"view":subview}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:verticalHuggingConstraints options:0 metrics:nil views:@{@"view":subview}]];
}

@end
