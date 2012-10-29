//
//  CCRSourceList.h
//  Renamer
//
//  Created by Curt Clifton on 10/28/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCRSourceList : NSObject <NSTableViewDataSource, NSTableViewDelegate>
- (void)addURLs:(NSArray *)urls;
@end
