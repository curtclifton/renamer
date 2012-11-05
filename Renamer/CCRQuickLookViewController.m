//
//  CCRQuickLookViewController.m
//  Renamer
//
//  Created by Curt Clifton on 11/4/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import "CCRQuickLookViewController.h"

@interface CCRQuickLookViewController ()
@property (nonatomic,strong) NSURL *url;
@end

@implementation CCRQuickLookViewController

- (id)initWithURL:(NSURL *)url;
{
    self = [super initWithNibName:@"Quicklook" bundle:nil];
    if (self) {
        _url = url;
    }

    return self;
}

#pragma mark NSPopoverDelegate protocol

- (void)popoverDidShow:(NSNotification *)notification;
{
    NSAssert(notification.object == self.popover, @"expect notification from our popover");
    
    self.previewView.previewItem = self.url;
    [self.previewView refreshPreviewItem];
}

#pragma mark - Public API

- (void)setPopover:(NSPopover *)popover;
{
    if (popover == _popover)
        return;
    
    _popover.delegate = nil;
    _popover = popover;

    popover.contentViewController = self;
    popover.behavior = NSPopoverBehaviorSemitransient;
    popover.delegate = self;
}

@end
