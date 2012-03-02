//
//  NSMutableDictionary+SMCKeys.m
//  HWSensors
//
//  Created by Иван Синицин on 01.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSMutableDictionary+SMCKeys.h"

@implementation NSMutableDictionary (SMCKeys)

-(id) valueForKey:(NSString *)key
{
    [super valueForKey:key];
    return [NSNumber numberWithInt:*((UInt16 *)[[sgModel readValueForKey:key] bytes])];
}

@end
