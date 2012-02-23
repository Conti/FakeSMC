//
//  sgModel.h
//  HWSensors
//
//  Created by Navi on 22.02.12.
//  Copyright (c) 2012 . All rights reserved.
//

#import <Foundation/Foundation.h>
#include "FakeSMCDefinitions.h"


#define SpinTransactionTime 3.0
#define SpinTime  10.0
@interface sgModel : NSObject {

NSMutableDictionary *   fans; 
    
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
-(NSDictionary *) testPrepareFan2;

-(BOOL) addFan: (NSDictionary *) desc withName: (NSString *) name;
-(BOOL) calibrateFan:(NSString *) fanId;
@end
