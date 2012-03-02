//
//  nameToActualValueTransformer.m
//  HWSensors
//
//  Created by Navi on 25.02.12.
//  Copyright (c) 2012 Navi. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "sgModel.h"
#import "nameToActualValueTransformer.h"

@implementation nameToActualValueTransformer


+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
    return [NSString stringWithFormat:@"%d rpm",[value intValue]];
}


@end
