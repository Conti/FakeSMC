//
//  sgFan.m
//  HWSensors
//
//  Created by Navi on 02.03.12.
//  Copyright (c) 2012 Navi. All rights reserved.
//

#import "sgFan.h"
#import "FakeSMCDefinitions.h"

@implementation sgFan

@synthesize calibrationDataUpward;
@synthesize calibrationDataDownward;
@synthesize Calibrated;
@synthesize Controlable;

+ (UInt16) swap_value:(UInt16) value
{
    return ((value & 0xff00) >> 8) | ((value & 0xff) << 8);
}

+ (UInt16) encode_fp2e:(UInt16) value
{
    UInt32 tmp = value;
    tmp = (tmp << 14) / 1000;
    value = (UInt16)(tmp & 0xffff);
    return [sgFan swap_value: value];
}

+ (UInt16) encode_fp4c:(UInt16) value
{
    
    UInt32 tmp = value;
    tmp = (tmp << 12) / 1000;
    value = (UInt16)(tmp & 0xffff);
    return [sgFan swap_value: value];
}

+ (UInt16)  encode_fpe2:(UInt16) value
{
    return [sgFan swap_value: value<<2];
}

+ (UInt16)  decode_fpe2:(UInt16) value
{
    return [sgFan swap_value: value] >> 2;
}

+ (NSData *)writeValueForKey:(NSString *)key data:(NSData *) aData
{
    NSData * value = NULL;
    
    io_service_t service = IOServiceGetMatchingService(0, IOServiceMatching(kFakeSMCDeviceService));
    
    if (service) {
        //        CFTypeRef message = (CFTypeRef) CFStringCreateWithCString(kCFAllocatorDefault, [key cStringUsingEncoding:NSASCIIStringEncoding], kCFStringEncodingASCII);
        CFMutableDictionaryRef message =  CFDictionaryCreateMutable(kCFAllocatorDefault,1, NULL, NULL);
        CFDictionaryAddValue(message, CFStringCreateWithCString(kCFAllocatorDefault,[key cStringUsingEncoding:NSASCIIStringEncoding], kCFStringEncodingASCII), CFDataCreate(kCFAllocatorDefault, [aData bytes], [aData length]));
        if (kIOReturnSuccess == IORegistryEntrySetCFProperty(service, CFSTR(kFakeSMCDeviceUpdateKeyValue), message)) 
        {
            NSDictionary * values = (__bridge_transfer /*__bridge_transfer*/ NSDictionary *)IORegistryEntryCreateCFProperty(service, CFSTR(kFakeSMCDeviceValues), kCFAllocatorDefault, 0);
            
            if (values)
                value = [values objectForKey:key];
        }
        
        CFRelease(message);
        IOObjectRelease(service);
    }
    
    return value;
}

+ (NSDictionary *)populateValues
{
    NSDictionary * values = NULL;
    
    io_service_t service = IOServiceGetMatchingService(0, IOServiceMatching(kFakeSMCDeviceService));
    
    if (service) { 
        CFTypeRef message = (CFTypeRef) CFStringCreateWithCString(kCFAllocatorDefault, "magic", kCFStringEncodingASCII);
        
        if (kIOReturnSuccess == IORegistryEntrySetCFProperty(service, CFSTR(kFakeSMCDevicePopulateValues), message))
            values = (__bridge_transfer NSDictionary *)IORegistryEntryCreateCFProperty(service, CFSTR(kFakeSMCDeviceValues), kCFAllocatorDefault, 0);
        
        CFRelease(message);
        IOObjectRelease(service);
    }
    
    return values;
    
}

+ (NSData *) readValueForKey:(NSString *)key
{
    NSData * value = nil;
    
    
    
    NSDictionary * values = [sgFan populateValues];
    
    if (values) 
        value = [values valueForKey:key];
    
    
    
    return value;
}


+(UInt32) numberOfFans {
    
    UInt32 value = 0; 
    NSData * data = [sgFan readValueForKey:@"FNum"];
    if(data)
        bcopy([data bytes],&value,[data length]<4 ? [data length] : 4);
    return value;
}

-(id) initWithKeys:(NSDictionary*) keys
{
    
    _tempSensorSource=0;
    _automatic=0;
    _manualPWM=0;
    _deltaTemp=0;
    _startPWMValue=0;
    _slopeSmooth=0;
    _deltaPWM = 0.0;
    ControlFanKeys = keys;
    return self;
}

-(id) initWithFanId:(NSUInteger) fanId
{
    _tempSensorSource=0;
    _automatic=0;
    _manualPWM=0;
    _deltaTemp=0;
    _startPWMValue=0;
    _slopeSmooth=0;
    _deltaPWM = 0.0;
    NSMutableDictionary * me = [NSMutableDictionary dictionaryWithCapacity:0];
    [me setObject:[NSString stringWithFormat:@KEY_FORMAT_FAN_ID,fanId] forKey:KEY_DESCRIPTION];    
    [me setObject:[NSString stringWithFormat:@KEY_FORMAT_FAN_TARGET_SPEED,fanId] forKey:KEY_FAN_CONTROL];
    [me setObject:[NSString stringWithFormat:@KEY_FORMAT_FAN_SPEED,fanId] forKey:KEY_READ_RPM];
    [me setObject:[NSString stringWithFormat:@KEY_FORMAT_FAN_START_PWM,fanId] forKey:KEY_START_PWM_CONTROL];
    [me setObject:[NSString stringWithFormat:@KEY_FORMAT_FAN_START_TEMP,fanId] forKey:KEY_START_TEMP_CONTROL];
    [me setObject:[NSString stringWithFormat:@KEY_FORMAT_FAN_OFF_TEMP,fanId] forKey:KEY_STOP_TEMP_CONTROL];
    [me setObject:[NSString stringWithFormat:@KEY_FORMAT_FAN_FULL_TEMP,fanId] forKey:KEY_FULL_TEMP_CONTROL];
    [me setObject:[NSString stringWithFormat:@KEY_FORMAT_FAN_TEMP_DELTA,fanId] forKey:KEY_DELTA_TEMP_CONTROL];
    [me setObject:[NSString stringWithFormat:@KEY_FORMAT_FAN_CONTROL,fanId] forKey:KEY_DELTA_PWM_CONTROL];
    

    
    ControlFanKeys = me;
    return self;
}

-(void) updateKey:(NSString *) key withValue:(id) value; 
{
    [ControlFanKeys setValue:value forKey:key];
}

-(NSString *) name
{
    
    return [NSString stringWithCString: [[sgFan readValueForKey: [ControlFanKeys valueForKey:KEY_DESCRIPTION]] bytes] encoding: NSUTF8StringEncoding ];
}

-(NSInteger) currentRPM
{
    NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_READ_RPM]];
    return  [sgFan decode_fpe2:*((UInt16 *)[dataptr bytes])];   
}

-(void) setCurrentRPM:(NSInteger)currentRPM
{
    
}

-(UInt8) fanStartTemp
{
    NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_START_TEMP_CONTROL]];
    return  *((UInt8 *)[dataptr bytes]);   
}

-(void) setFanStartTemp:(UInt8)fanStartTemp
{
    [sgFan writeValueForKey: [ControlFanKeys valueForKey:KEY_START_TEMP_CONTROL] data:[NSData dataWithBytes:&fanStartTemp length:1]];
}

-(UInt8) fanStopTemp
{
    NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_STOP_TEMP_CONTROL]];
    return  *((UInt8 *)[dataptr bytes]);   
}

-(void) setFanStopTemp:(UInt8)fanStopTemp
{
    [sgFan writeValueForKey: [ControlFanKeys valueForKey:KEY_STOP_TEMP_CONTROL] data:[NSData dataWithBytes:&fanStopTemp length:1]];
}


-(UInt8) fanFullOnTemp
{
    NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_FULL_TEMP_CONTROL]];
    return  *((UInt8 *)[dataptr bytes]);   
}

-(void) setFanFullOnTemp:(UInt8)fanFullOnTemp
{
    [sgFan writeValueForKey: [ControlFanKeys valueForKey:KEY_FULL_TEMP_CONTROL] data:[NSData dataWithBytes:&fanFullOnTemp length:1]];
}

-(BOOL) automatic
{
    NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_FAN_CONTROL]];
    _automatic =   *((UInt8 *)[dataptr bytes]) >> 7 ? YES : NO;
    return _automatic;
}

-(void) setAutomatic:(BOOL)automatic
{
    _automatic = automatic;
    UInt8 temp = _automatic ?  0x80 | ( _tempSensorSource & 0x03 ) : _manualPWM & 0x7F;
    [sgFan writeValueForKey: [ControlFanKeys valueForKey:KEY_FAN_CONTROL] data:[NSData dataWithBytes:&temp length:1]];
}

-(UInt8) tempSensorSource
{
    if (_automatic) {
        NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_FAN_CONTROL]];
        _tempSensorSource =  *((UInt8 *)[dataptr bytes]) & 0x3;
    } else
        _tempSensorSource = 0;
    return _tempSensorSource;
}

-(void) setTempSensorSource:(UInt8)tempSensorSource
{
    _tempSensorSource = tempSensorSource;
    UInt8 temp = _automatic ?  0x80 | ( _tempSensorSource & 0x03 ) : _manualPWM & 0x7F;
    [sgFan writeValueForKey: [ControlFanKeys valueForKey:KEY_FAN_CONTROL] data:[NSData dataWithBytes:&temp length:1]];

}

-(BOOL) slopeSmooth
{
    NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_DELTA_TEMP_CONTROL]];
    _slopeSmooth =   *((UInt8 *)[dataptr bytes]) >> 7 ? YES : NO;
    return _slopeSmooth;
    
}

-(void) setSlopeSmooth:(BOOL)slopeSmooth
{
    _slopeSmooth = slopeSmooth;
    UInt8 temp = _slopeSmooth ?  0x80 | ( _deltaTemp & 0x1F ) : _deltaTemp & 0x1F;
    [sgFan writeValueForKey: [ControlFanKeys valueForKey:KEY_DELTA_TEMP_CONTROL] data:[NSData dataWithBytes:&temp length:1]];
    
}

-(UInt8) deltaTemp
{
    NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_DELTA_TEMP_CONTROL]];
    _deltaTemp =  *((UInt8 *)[dataptr bytes]) & 0x1F;   
    return _deltaTemp;
}

-(void) setDeltaTemp:(UInt8)deltaTemp
{
    _deltaTemp = deltaTemp;
    UInt8 temp = _slopeSmooth ?  0x80 | ( _deltaTemp & 0x1F ) : _deltaTemp & 0x1F;
    [sgFan writeValueForKey: [ControlFanKeys valueForKey:KEY_DELTA_TEMP_CONTROL] data:[NSData dataWithBytes:&temp length:1]]; 
}

-(UInt8) startPWMValue
{
    NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_START_PWM_CONTROL]];
    _startPWMValue =  *((UInt8 *)[dataptr bytes]) & 0x1F;   
    return _startPWMValue;
}

-(void) setStartPWMValue:(UInt8)startPWMValue
{
    _startPWMValue = startPWMValue;
    NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_START_PWM_CONTROL]];
    UInt8 temp = (*((UInt8 *)[dataptr bytes]) & 0x80) | ( _startPWMValue & 0x7f);
    [sgFan writeValueForKey: [ControlFanKeys valueForKey:KEY_START_PWM_CONTROL] data:[NSData dataWithBytes:&temp length:1]];
}

-(UInt8) manualPWM
{
    if (_automatic) {
        _manualPWM= 0;
    } else
    {
        NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_FAN_CONTROL]];
        _manualPWM = (*((UInt8 *)[dataptr bytes]) & 0x7F);

    }
    return _manualPWM;
}

-(void) setManualPWM:(UInt8)manualPWM
{
    _manualPWM=manualPWM;
    
    if (_automatic) {
        _manualPWM= 0;
    } else
    {
        UInt8 temp = _manualPWM & 0x7F;
        [sgFan writeValueForKey: [ControlFanKeys valueForKey:KEY_FAN_CONTROL] data:[NSData dataWithBytes:&temp length:1]];
    }
}

-(float) deltaPWM
{
    NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_FAN_CONTROL]];
    
        NSData * dataptr2 = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_START_PWM_CONTROL]];
    float fract = (*((UInt8 *)[dataptr bytes]) & 0x3) / 8.0;
    float dec =  (*((UInt8 *)[dataptr2 bytes]) & 0x80) >> 3 | (*((UInt8 *)[dataptr bytes]) & 0x38) >> 3; 
    _deltaPWM = dec +fract;
    return _deltaPWM;
}
@end
