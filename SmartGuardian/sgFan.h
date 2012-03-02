//
//  sgFan.h
//  HWSensors
//
//  Created by Navi on 02.03.12.
//  Copyright (c) 2012 Navi. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KEY_NAME                @"Name"
#define KEY_READ_RPM            @"RPMReadKey"
#define KEY_CURRENT_RPM         @"CurrentRPM"
#define KEY_FAN_CONTROL         @"FanControlKey"
#define KEY_DATA_UPWARD         @"CalibrationDataUpward"
#define KEY_DATA_DOWNWARD       @"CalibrationDataDownward"
#define KEY_DESCRIPTION         @"Description"
#define KEY_CONTROLABLE         @"Controlable"
#define KEY_CALIBRATED          @"Calibrated"
#define KEY_START_TEMP_CONTROL  @"StartTempControl"
#define KEY_STOP_TEMP_CONTROL   @"StopTempControl"
#define KEY_FULL_TEMP_CONTROL   @"FullOnTempControl"
#define KEY_DELTA_TEMP_CONTROL  @"DeltaTempControl"
#define KEY_DELTA_PWM_CONTROL   @"DeltaPWMControl"
#define KEY_START_PWM_CONTROL   @"StartPWMControl"

@interface sgFan : NSObject {
    NSDictionary * ControlFanKeys;
    BOOL _automatic;
    UInt8 _tempSensorSource;
    UInt8 _deltaTemp;
    UInt8 _startPWMValue;
    UInt8 _manualPWM;
    BOOL  _slopeSmooth;
    float _deltaPWM;
}


@property (readonly)         NSString *     name;
@property (assign,readwrite) NSInteger      currentRPM;
@property (assign,readwrite) UInt8          fanStartTemp;
@property (assign,readwrite) UInt8          fanStopTemp;
@property (assign,readwrite) UInt8          fanFullOnTemp;
@property (assign,readwrite) BOOL           automatic;
@property (assign,readwrite) UInt8          startPWMValue;
@property (assign,readonly)  float          deltaPWM;
@property (assign,readwrite) UInt8          manualPWM;
@property (assign,readwrite) BOOL           slopeSmooth;
@property (assign,readwrite) UInt8          deltaTemp;
@property (assign,readwrite) UInt8          tempSensorSource;
@property (assign,readwrite) NSArray *      calibrationDataUpward;
@property (assign,readwrite) NSArray *      calibrationDataDownward;
@property (assign,readwrite) BOOL           Controlable;
@property (assign,readwrite) BOOL           Calibrated;

+(UInt32) numberOfFans;

+ (NSData *) readValueForKey:(NSString *)key;
+ (NSDictionary *)populateValues;
+ (NSData *)writeValueForKey:(NSString *)key data:(NSData *) aData;
+ (UInt16) swap_value:(UInt16) value;
+ (UInt16)  decode_fpe2:(UInt16) value;
+ (UInt16) encode_fp4c:(UInt16) value;



-(id) initWithKeys:(NSDictionary*) keys;
-(id) initWithFanId:(NSUInteger) fanId;
-(void) updateKey:(NSString *) key withValue:(id) value; 

@end
