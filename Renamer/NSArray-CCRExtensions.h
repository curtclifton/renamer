//
//  NSArray+CCRExtensions.h
//  Renamer
//
//  Created by Curt Clifton on 10/28/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (CCRExtensions)

// If the block returns nil for an object, that object will have no corresponding value in the resulting array. To ensure a 1-1 mapping between self and the result array, the block must not return nil. On the other hand, a block that returns nil can be used to filter an array.
- (NSArray *)arrayByMappingBlock:(id (^)(id object))block;
@end
