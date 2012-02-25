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

#define KEY_NAME            @"Name"
#define KEY_READ_RPM        @"RPMReadKey"
#define KEY_CURRENT_RPM     @"CurrentRPM"
#define KEY_FAN_CONTROL     @"FanControlKey"
#define KEY_DATA_UPWARD     @"CalibrationDataUpward"
#define KEY_DATA_DOWNWARD   @"CalibrationDataDownward"
#define KEY_DESCRIPTION     @"Description"
#define KEY_CONTROLABLE     @"Controlable"
#define KEY_CALIBRATED      @"Calibrated"

@interface sgModel : NSObject 

@property (readwrite,retain) NSMutableDictionary *   fans; 

+(UInt32) numberOfFans;

+ (NSData *) readValueForKey:(NSString *)key;
+ (NSDictionary *)populateValues;
+ (NSData *)writeValueForKey:(NSString *)key data:(NSData *) aData;
+ (UInt16) swap_value:(UInt16) value;
+ (UInt16)  decode_fpe2:(UInt16) value;
+ (UInt16) encode_fp4c:(UInt16) value;
+(NSUInteger) whoDiffersFor:(NSArray *) current andPrevious:(NSArray *) previous andMaxDev:(NSUInteger) maxDev;;

-(sgModel *) init;
-(NSDictionary *) initialPrepareFan: (NSUInteger) fanId;
-(NSUInteger) rpmForFan: (NSString *) name;
-(BOOL) writeFanDictionatyToFile: (NSString *) filename;
-(BOOL) addFan: (NSDictionary *) desc withName: (NSString *) name;
-(BOOL) calibrateFan:(NSString *) fanId;
-(void) findControllers;
@end
