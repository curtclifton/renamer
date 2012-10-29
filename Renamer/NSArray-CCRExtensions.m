//
//  NSArray-CCRExtensions.m
//  Renamer
//
//  Created by Curt Clifton on 10/28/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import "NSArray-CCRExtensions.h"

@implementation NSArray (CCRExtensions)

- (NSArray *)arrayByMappingBlock:(id (^)(id object))block;
{
    if ([self count] == 0)
        return [NSArray new];

    if ([self count] == 1) {
        id result = block(self[0]);
        if (result == nil)
            return [NSArray new];
        return [NSArray arrayWithObject:result];
    }
    
    NSMutableArray *temporaryArray = [NSMutableArray arrayWithCapacity:[self count]];
    for (id object in self) {
        id result = block(object);
        if (result != nil)
            [temporaryArray addObject:result];
    }
    return [NSArray arrayWithArray:temporaryArray];
}


@end
