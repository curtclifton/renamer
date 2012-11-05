//
//  CCRQuickLookViewController.h
//  Renamer
//
//  Created by Curt Clifton on 11/4/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface CCRQuickLookViewController : NSViewController <NSPopoverDelegate>

@property (weak) IBOutlet QLPreviewView *previewView;

@property (nonatomic, weak) NSPopover *popover;

- (id)initWithURL:(NSURL *)url;

@end
