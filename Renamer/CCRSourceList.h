//
//  CCRSourceList.h
//  Renamer
//
//  Created by Curt Clifton on 10/28/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCRSourceList : NSObject <NSTableViewDataSource>

@property (nonatomic) BOOL hasContent; // affects controls via bindings

- (void)addURLs:(NSArray *)urls;
- (void)removeURL:(NSURL *)url;
- (NSURL *)urlForRow:(NSInteger)row;
@end
