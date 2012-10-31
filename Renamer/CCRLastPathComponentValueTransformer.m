//
//  CCRReadablePathValueTransformer.m
//  Renamer
//
//  Created by Curt Clifton on 10/30/12.
//  Copyright (c) 2012 Curt Clifton. All rights reserved.
//

#import "CCRLastPathComponentValueTransformer.h"

@implementation CCRLastPathComponentValueTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation;
{
    return NO;
}

- (id)transformedValue:(id)value;
{
    if (value == nil)
        return @"";
    
    NSAssert([value isKindOfClass:[NSURL class]] , @"Expects NSURL");
    return [value lastPathComponent];
}
@end
