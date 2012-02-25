//
//  nameToActualValueTransformer.m
//  HWSensors
//
//  Created by Иван Синицин on 25.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "sgModel.h"
#import "nameToActualValueTransformer.h"

@implementation nameToActualValueTransformer


+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
    if (value != nil) {
        NSData * dataptr = [sgModel readValueForKey:value];
        UInt16 value_Ret = [sgModel decode_fpe2:*((UInt16 *)[dataptr bytes])];
        return [NSString stringWithFormat:@"%d RPM",value_Ret];

    }
    return nil;
}
@end
