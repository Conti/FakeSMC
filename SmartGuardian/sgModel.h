//
//  sgModel.h
//  HWSensors
//
//  Created by Иван Синицин on 22.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "FakeSMCDefinitions.h"

@interface sgModel : NSObject {

NSMutableArray *   fans; 
    
}

+(UInt32) numberOfFans;

+ (NSData *) readValueForKey:(NSString *)key;
+ (NSDictionary *)populateValues;
+ (NSData *)writeValueForKey:(NSString *)key data:(NSData *) aData;
+ (UInt16) swap_value:(UInt16) value;
+ (UInt16)  decode_fpe2:(UInt16) value;
+ (UInt16) encode_fp4c:(UInt16) value;

-(sgModel *) init;
-(NSDictionary *) testPrepareFan;
-(BOOL) addFan: (NSDictionary *) desc;
-(BOOL) calibrateFan:(NSUInteger) fanId;
@end
