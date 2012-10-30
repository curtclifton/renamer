//
//  CCRSourceList.h
//  Renamer
//
//  Created by Curt Clifton on 10/28/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCRSourceList : NSObject <NSTableViewDataSource>
- (void)addURLs:(NSArray *)urls;
- (NSString *)tooltipForRow:(NSInteger)row;
@end
