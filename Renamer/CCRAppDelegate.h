//
//  CCRAppDelegate.h
//  Renamer
//
//  Created by Curt Clifton on 9/18/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CCRAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

- (IBAction)renameAndFile:(id)sender;

@end
