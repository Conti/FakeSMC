//
//  sgFan.m
//  HWSensors
//
//  Created by Navi on 02.03.12.
//  Copyright (c) 2012 Navi. All rights reserved.
//

#import "sgFan.h"
#import "FakeSMCDefinitions.h"


#define Debug true

#ifdef Debug
#define DebugLog(string, args...)	do { if (Debug) { NSLog (string , ## args); } } while(0)
#else
#define DebugLog
#endif


#define SCALE_FACTOR 1.25f

@implementation sgFan

@synthesize calibrationDataUpward;
//@synthesize calibrationDataDownward;
@synthesize Calibrated;
@synthesize Controlable;
@synthesize progress;

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
        CFStringRef local_key =  CFStringCreateWithCString(kCFAllocatorDefault,[key cStringUsingEncoding:NSASCIIStringEncoding], kCFStringEncodingASCII);
        CFDataRef   local_data =  CFDataCreate(kCFAllocatorDefault, [aData bytes], [aData length]);
        CFDictionaryAddValue(message,local_key,local_data);
        if (kIOReturnSuccess == IORegistryEntrySetCFProperty(service, CFSTR(kFakeSMCDeviceUpdateKeyValue), message)) 
        {
            NSDictionary * values = (__bridge_transfer /*__bridge_transfer*/ NSDictionary *)IORegistryEntryCreateCFProperty(service, CFSTR(kFakeSMCDeviceValues), kCFAllocatorDefault, 0);
            
            if (values)
                value = [values objectForKey:key];
        }
        CFRelease(local_key);
        CFRelease(local_data);
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

+(NSString *) smcKeyForSensor: (NSString *) name
{
    if ([name isEqual:@"CPU"]) 
        return @KEY_CPU_HEATSINK_TEMPERATURE;
    if ([name isEqual:@"System"]) 
        return @KEY_NORTHBRIDGE_TEMPERATURE;
    if ([name isEqual:@"Ambient"]) 
        return @KEY_AMBIENT_TEMPERATURE;
    return nil;   
}


+(NSDictionary *) tempSensorNameAndKeys
{
    io_service_t service = IOServiceGetMatchingService(0, IOServiceMatching("IT87x"));
    if(!service)
        return nil;
    NSString *  model = (__bridge_transfer NSString *)IORegistryEntryCreateCFProperty(service, CFSTR(kFakeSuperIOMonitorModel), kCFAllocatorDefault, 0);
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:0];
    if (model)
    {
        NSDictionary* list = (__bridge_transfer NSDictionary *)IORegistryEntryCreateCFProperty(service, CFSTR("Sensors Configuration"), kCFAllocatorDefault, 0);
        NSDictionary* configuration = list ? [list valueForKey:model]  : nil;
        
        if (list && !configuration) 
            configuration = [list objectForKey:@"Default"];
        // Temperature Sensors
        if (configuration) {
            for (int i = 0; i < 3; i++) 
            {				
                               
                NSString * key = [NSString stringWithFormat:@"TEMPIN%X", i];
                if ([[configuration objectForKey:key] isEqual:@"CPU"]) 
                    if([sgFan readValueForKey:@KEY_CPU_HEATSINK_TEMPERATURE])
                        [dict setObject:@"CPU" forKey:[NSNumber numberWithInt:i]];
                if ([[configuration objectForKey:key] isEqual:@"System"]) 
                    if([sgFan readValueForKey:@KEY_NORTHBRIDGE_TEMPERATURE])
                        [dict setObject:@"System" forKey:[NSNumber numberWithInt:i]];
                if ([[configuration objectForKey:key] isEqual:@"Ambient"]) 
                    if([sgFan readValueForKey:@KEY_AMBIENT_TEMPERATURE])
                        [dict setObject:@"Ambient" forKey:[NSNumber numberWithInt:i]];

            }
            return dict;
        }
    }
    return nil;
}

+(NSString *) smcKeyForSensorId:(NSNumber *) num
{
    return [sgFan smcKeyForSensor: [[sgFan tempSensorNameAndKeys] objectForKey: num]];
}

+(BOOL) smartGuardianAvailable
{
      io_service_t service = IOServiceGetMatchingService(0, IOServiceMatching("IT87x"));
    if(!service)
        return NO;
    NSString *  model = (__bridge_transfer NSString *)IORegistryEntryCreateCFProperty(service, CFSTR(kFakeSuperIOMonitorModel), kCFAllocatorDefault, 0);
    
    if (model)
    {
        NSDictionary* list = (__bridge_transfer NSDictionary *)IORegistryEntryCreateCFProperty(service, CFSTR("Sensors Configuration"), kCFAllocatorDefault, 0);
        NSDictionary* configuration = list ? [list valueForKey:model]  : nil;
        
        if (list && !configuration) 
            configuration = [list objectForKey:@"Default"];
        BOOL hasSmartGuardian = [[configuration valueForKey:@"SmartGuardian"] boolValue];
        return hasSmartGuardian;
    }
    return NO;
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
    NSMutableDictionary * me = [NSMutableDictionary dictionaryWithCapacity:0];
    if(keys)
    {
//        calibrationDataDownward = [keys valueForKey:KEY_DATA_DOWNWARD];
        calibrationDataUpward = [keys valueForKey:KEY_DATA_UPWARD];
        Calibrated = [[keys valueForKey:KEY_CALIBRATED] boolValue];
        Controlable = [[keys valueForKey:KEY_CONTROLABLE] boolValue];

        [keys enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            
            // Ugly but there is no other way yet
            if([key hasPrefix:@"F"] && [key hasSuffix:@"ID"])
            {
                [sgFan writeValueForKey:key data:obj];
                [me setObject:key forKey:KEY_DESCRIPTION];
            };
            if([key hasPrefix:@"F"] && [key hasSuffix:@"Ac"])
            {
//                [sgFan writeValueForKey:key data:obj];  //READ Only key!!!
                [me setObject:key forKey:KEY_READ_RPM];
            };
            if([key hasPrefix:@"F"] && [key hasSuffix:@"Tg"])
                {
                    [sgFan writeValueForKey:key data:obj];
                    [me setObject:key forKey:KEY_FAN_CONTROL];
                };
            if([key hasPrefix:@"F"] && [key hasSuffix:@"St"])
            {
                [sgFan writeValueForKey:key data:obj];
                [me setObject:key forKey:KEY_START_TEMP_CONTROL];
            };
            if([key hasPrefix:@"F"] && [key hasSuffix:@"Ss"])
            {
                [sgFan writeValueForKey:key data:obj];
                [me setObject:key forKey:KEY_STOP_TEMP_CONTROL];
            };
            if([key hasPrefix:@"F"] && [key hasSuffix:@"Ft"])
            {
                [sgFan writeValueForKey:key data:obj];
                [me setObject:key forKey:KEY_FULL_TEMP_CONTROL];
            };
            if([key hasPrefix:@"F"] && [key hasSuffix:@"Pt"])
            {
                [sgFan writeValueForKey:key data:obj];
                [me setObject:key forKey:KEY_START_PWM_CONTROL];
            };
            if([key hasPrefix:@"F"] && [key hasSuffix:@"Fo"])
            {
                [sgFan writeValueForKey:key data:obj];
                [me setObject:key forKey:KEY_DELTA_TEMP_CONTROL];
            };
            if([key hasPrefix:@"F"] && [key hasSuffix:@"Ct"])
            {
                [sgFan writeValueForKey:key data:obj];
                [me setObject:key forKey:KEY_DELTA_PWM_CONTROL];
            };
            if([key hasPrefix:@"T"])
            {
                [sgFan writeValueForKey:key data:obj];
                [me setObject:key forKey:KEY_TEMP_VALUE];
            };
        }];
        ControlFanKeys = me;
        NSUInteger temp;
        temp=self.fanStopTemp;
        temp=self.fanStartTemp;
        temp=self.fanFullOnTemp;
        temp=self.automatic;
        temp=self.startPWMValue;
        temp=self.deltaPWM;
        temp=self.manualPWM;
        temp=self.slopeSmooth;
        temp=self.deltaTemp;
        temp=self.tempSensorSource;
    }
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
    calibrationDataUpward = [NSMutableArray arrayWithCapacity:0];
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
    [me setObject:@KEY_CPU_HEATSINK_TEMPERATURE forKey:KEY_TEMP_VALUE];

    

    
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

-(void) setName:(NSString *)name
{
    
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
    if(fanStartTemp < self.fanStopTemp) self.fanStopTemp = fanStartTemp;
    if(fanStartTemp > self.fanFullOnTemp ) self.fanFullOnTemp = fanStartTemp;
    [sgFan writeValueForKey: [ControlFanKeys valueForKey:KEY_START_TEMP_CONTROL] data:[NSData dataWithBytes:&fanStartTemp length:1]];
    [self setLawGraphData:nil];
    [self setTempMarks:nil];
}

-(UInt8) fanStopTemp
{
    NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_STOP_TEMP_CONTROL]];
    return  *((UInt8 *)[dataptr bytes]);   
}

-(void) setFanStopTemp:(UInt8)fanStopTemp
{
    if(fanStopTemp > self.fanStartTemp ) self.fanStartTemp = fanStopTemp;
    if(fanStopTemp > self.fanFullOnTemp ) self.fanFullOnTemp = fanStopTemp;


    [sgFan writeValueForKey: [ControlFanKeys valueForKey:KEY_STOP_TEMP_CONTROL] data:[NSData dataWithBytes:&fanStopTemp length:1]];
    [self setLawGraphData:nil];
    [self setTempMarks:nil];
}


-(UInt8) fanFullOnTemp
{
    NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_FULL_TEMP_CONTROL]];
    return  *((UInt8 *)[dataptr bytes]);   
}

-(void) setFanFullOnTemp:(UInt8)fanFullOnTemp
{
    if(fanFullOnTemp < self.fanStartTemp ) self.fanStartTemp = fanFullOnTemp;
    if(fanFullOnTemp < self.fanStopTemp ) self.fanStopTemp = fanFullOnTemp;
    [sgFan writeValueForKey: [ControlFanKeys valueForKey:KEY_FULL_TEMP_CONTROL] data:[NSData dataWithBytes:&fanFullOnTemp length:1]];
    [self setLawGraphData:nil];
    [self setTempMarks:nil];
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
    [self setLawGraphData:nil];
    [self setTempMarks:nil];
}

-(UInt8) tempSensorSource
{
    if (_automatic && [ControlFanKeys valueForKey:KEY_FAN_CONTROL]) {
        NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_FAN_CONTROL]];
        _tempSensorSource =  *((UInt8 *)[dataptr bytes]) & 0x3;
        [ControlFanKeys setValue:[sgFan smcKeyForSensorId:[NSNumber numberWithInt:_tempSensorSource]] forKey:KEY_TEMP_VALUE];
    } else
        _tempSensorSource = 0;
    return _tempSensorSource;
}

-(void) setTempSensorSource:(UInt8)tempSensorSource
{
    _tempSensorSource = tempSensorSource;
    [ControlFanKeys setValue:[sgFan smcKeyForSensorId:[NSNumber numberWithInt:_tempSensorSource]] forKey:KEY_TEMP_VALUE];
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
    _startPWMValue =  *((UInt8 *)[dataptr bytes]) & 0x7F;   
    return _startPWMValue;
}

-(void) setStartPWMValue:(UInt8)startPWMValue
{
    _startPWMValue = startPWMValue;
    NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_START_PWM_CONTROL]];
    UInt8 temp = (*((UInt8 *)[dataptr bytes]) & 0x80) | ( _startPWMValue & 0x7f);
    [sgFan writeValueForKey: [ControlFanKeys valueForKey:KEY_START_PWM_CONTROL] data:[NSData dataWithBytes:&temp length:1]];
    [self setLawGraphData:nil];
    [self setTempMarks:nil];
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
    [self setLawGraphData:nil];
    [self setTempMarks:nil];
}

-(float) deltaPWM
{
    NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_DELTA_PWM_CONTROL]];
    
        NSData * dataptr2 = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_START_PWM_CONTROL]];
    float fract = (*((UInt8 *)[dataptr bytes]) & 0x7) / 8.0;
    float dec =  (*((UInt8 *)[dataptr2 bytes]) & 0x80) >> 4 | (*((UInt8 *)[dataptr bytes]) & 0x38) >> 3; 
    _deltaPWM = dec +fract;
    return _deltaPWM;
}

-(void) setDeltaPWM:(float)deltaPWM
{

    _deltaPWM =deltaPWM;
    UInt8 integerPart = (UInt8)deltaPWM;
    UInt8 fract = (UInt8)((deltaPWM - integerPart)*8.0);
    integerPart &= 0xF;
    fract &= 0x7;
    UInt8 highBit = (integerPart & 0x8) << 4;   
    NSData * dataptr2 = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_START_PWM_CONTROL]];
    *((UInt8 *)[dataptr2 bytes]) = (*((UInt8 *)[dataptr2 bytes]) & 0x7f) | highBit;
    [sgFan writeValueForKey:[ControlFanKeys valueForKey:KEY_START_PWM_CONTROL] data:dataptr2];
     NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_DELTA_PWM_CONTROL]];
    *((UInt8 *)[dataptr bytes]) = ( (*((UInt8 *)[dataptr bytes]) & 0x80) | (( integerPart & 0x7) << 3) | fract);
    [sgFan writeValueForKey:[ControlFanKeys valueForKey:KEY_DELTA_PWM_CONTROL] data:dataptr];
    [self setLawGraphData:nil];
    [self setTempMarks:nil];
}

-(NSDictionary *) valuesForSaveOperation
{
    NSMutableDictionary * saveData = [NSMutableDictionary dictionaryWithCapacity:0];
    [ControlFanKeys enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [saveData setObject:[sgFan readValueForKey:obj] forKey:obj];
         }];
    if(Calibrated)
    {
    [saveData setObject:calibrationDataUpward forKey: KEY_DATA_UPWARD];
//    [saveData setObject:calibrationDataDownward forKey:KEY_DATA_DOWNWARD];
    }
    [saveData setObject:[NSNumber numberWithBool:Controlable] forKey:KEY_CONTROLABLE];
    [saveData setObject:[NSNumber numberWithBool: Calibrated] forKey:KEY_CALIBRATED];
    
        return saveData;
}

-(UInt16) tempSensorValue
{
  NSData * dataptr = [sgFan readValueForKey:  [ControlFanKeys valueForKey:KEY_TEMP_VALUE]];   
  return  *((UInt16 *)[dataptr bytes]);
}

-(void) setTempSensorValue:(UInt16)tempSensorValue
{
    
}

-(NSDictionary *) lawGraphData
{
    NSMutableArray * data = [NSMutableArray arrayWithCapacity:0];
    NSMutableDictionary * fan_allPlots = [NSMutableDictionary dictionaryWithCapacity:1];    
    NSMutableDictionary * fan_plotdataUp = [NSMutableDictionary dictionaryWithCapacity:1];
    
    if(!self.Calibrated) return fan_allPlots;
    
    if(self.automatic)
    {
    int i=0;
        int fStop = self.fanStopTemp;
        int fStart = self.fanStartTemp;
        int fFullOn = self.fanFullOnTemp;
        int sPwm = self.startPWMValue;
        float dPwm = self.deltaPWM;
    for (i=0; i<fStop; i++) 
    [data addObject: [self.calibrationDataUpward objectAtIndex:0]];

    for (i=fStop; i<fStart; i++) 
        [data addObject:[self.calibrationDataUpward objectAtIndex:sPwm]];
    for (i=fStart; i<fFullOn; i++) 
    {
        int newindex =   (sPwm + dPwm*(i-fStart)); 
        [data addObject:[self.calibrationDataUpward objectAtIndex: newindex> 127 ? 127 : newindex]];
    }
    for (i=fFullOn; i<128; i++) 
        [data addObject:[self.calibrationDataUpward lastObject]];
        
    
    [fan_plotdataUp setObject:[NSNumber numberWithFloat:SCALE_FACTOR*[[self.calibrationDataUpward lastObject] floatValue]] forKey:@"Scale"];
    }
    
    else
    {
        [data addObject:[self.calibrationDataUpward objectAtIndex:self.manualPWM]];
        [data addObject:[self.calibrationDataUpward objectAtIndex:self.manualPWM]];
        [fan_plotdataUp setObject:[self.calibrationDataUpward lastObject] forKey:@"Scale"];

    }

           [fan_plotdataUp setObject:[NSColor redColor] forKey:@"Color"];
            [fan_plotdataUp setObject:data forKey:@"Data" ];
            [fan_allPlots setObject:fan_plotdataUp forKey:@"LawGraph"];
         
    return fan_allPlots;
}

-(void) setLawGraphData:(NSArray *)lawGraphData
{
    
}

-(NSDictionary *) tempMarks
{
    NSMutableDictionary * mark_plots = [NSMutableDictionary dictionaryWithCapacity:3];    
    NSMutableDictionary * stop_mark = [NSMutableDictionary dictionaryWithCapacity:1];
    NSMutableDictionary * start_mark = [NSMutableDictionary dictionaryWithCapacity:1];
    NSMutableDictionary * full_on_mark = [NSMutableDictionary dictionaryWithCapacity:1];
    
    
    
    [stop_mark setObject:[NSColor blueColor] forKey:@"Color"];
    [start_mark setObject:[NSColor greenColor] forKey:@"Color"];
    [full_on_mark setObject:[NSColor whiteColor] forKey:@"Color"];
    
    [stop_mark setObject:[NSNumber numberWithInt:self.fanStopTemp] forKey:@"Data"];
    [start_mark setObject:[NSNumber numberWithInt:self.fanStartTemp]  forKey:@"Data"];
    [full_on_mark setObject:[NSNumber numberWithInt:self.fanFullOnTemp]  forKey:@"Data"];
    
    [mark_plots setObject:stop_mark forKey:@"Stop"];
    [mark_plots setObject:start_mark forKey:@"Start"];
    [mark_plots setObject:full_on_mark forKey:@"FullOn"];
    
    return mark_plots;
    
}

-(void) setTempMarks:(NSDictionary *)tempMarks
{
    
}

-(NSDictionary *) CalibrationGraphData
{
    NSMutableDictionary * calibration_allPlots = [NSMutableDictionary dictionaryWithCapacity:1];    
    NSMutableDictionary * calibration_plotdataUp = [NSMutableDictionary dictionaryWithCapacity:1];
//    NSMutableDictionary * calibration_plotdataDown = [NSMutableDictionary dictionaryWithCapacity:1];
    
    if(!self.Calibrated) return calibration_allPlots;
    
    [calibration_plotdataUp setObject:[NSColor redColor] forKey:@"Color"];
    [calibration_plotdataUp setObject:calibrationDataUpward forKey:@"Data" ];
    [calibration_plotdataUp setObject:[NSNumber numberWithFloat:SCALE_FACTOR*[[calibrationDataUpward lastObject] floatValue]] forKey:@"Scale" ];
    [calibration_allPlots setObject:calibration_plotdataUp forKey:@"Upward"];
    
//    [calibration_plotdataDown setObject:[NSColor blueColor] forKey:@"Color"];
//    [calibration_plotdataDown setObject:calibrationDataDownward forKey:@"Data" ];
//    [calibration_plotdataDown setObject:[NSNumber numberWithFloat:SCALE_FACTOR*[[calibrationDataDownward lastObject] floatValue]] forKey:@"Scale" ];
//    [calibration_allPlots setObject:calibration_plotdataDown forKey:@"Downward"];
    return calibration_allPlots;
}

-(void) setCalibrationGraphData:(NSDictionary *)CalibrationGraphData
{
    
}

-(BOOL) calibrateFan
{
    BOOL wasAutomatic=self.automatic;
    uint8 tempSensorSave = self.tempSensorSource;
    [calibrationDataUpward removeAllObjects];
//    [calibrationDataDownward removeAllObjects];
    
    int i = 0;
    self.automatic=NO;
    self.manualPWM = 0;
    self.progress = 0;
    self.name = @"";
    [NSThread sleepForTimeInterval:SpinTime];  // Give a time to stop rotation
    
    // Upward disrection
    for( i=0;i<128;i++)
    {
        self.manualPWM = i;
        [NSThread sleepForTimeInterval:SpinTransactionTime]; //  Give some time for fan to reach the stable rotation
        NSNumber * num = [NSNumber numberWithLong: self.currentRPM];
        [calibrationDataUpward addObject:num];
        DebugLog(@"RPMs for FAN %@ at PWM = %d  is %d", [self name] , i, [num intValue]) ;
        self.progress = self.progress + 0.78125;
    }
    //Downward direction
//    for( i=127;i>=0;i--)
//    {
//        
//        self.manualPWM = i;
//        [NSThread sleepForTimeInterval:SpinTransactionTime]; //  Give some time for fan to reach the stable rotation
//        NSNumber * num = [NSNumber numberWithLong:self.currentRPM];
//        [calibrationDataDownward insertObject:num atIndex: 0];
//        DebugLog(@"RPMs for FAN %@ at PWM = %d  is %d", [self name] , i, [num intValue]) ;
//        self.progress = self.progress + 0.390625;
//    }
    
    self.automatic = wasAutomatic;
    self.tempSensorSource = tempSensorSave;
    self.Calibrated = YES;
    [self setCalibrationGraphData:nil];
    [self setLawGraphData:nil];
    [self setTempMarks:nil];
    return YES;

}



-(void) loadFromDictrionary:(NSDictionary *)dict
{
    __block bool canLoad = YES;
    
    [ControlFanKeys enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if([dict valueForKey:obj]==nil)
        {
            canLoad=NO;
            *stop=YES;
        }
    }];
    
    if(canLoad)
    {
//        calibrationDataDownward = [dict valueForKey:KEY_DATA_DOWNWARD];
        calibrationDataUpward = [dict valueForKey:KEY_DATA_UPWARD];
        Calibrated = [[dict valueForKey:KEY_CALIBRATED] boolValue];
        Controlable = [[dict valueForKey:KEY_CONTROLABLE] boolValue];
        
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([key hasPrefix:@"F"]) 
                [sgFan writeValueForKey:key data:obj];
        }];
        NSUInteger temp;
        temp=self.fanStopTemp;
        temp=self.fanStartTemp;
        temp=self.fanFullOnTemp;
        temp=self.automatic;
        temp=self.startPWMValue;
        temp=self.deltaPWM;
        temp=self.manualPWM;
        temp=self.slopeSmooth;
        temp=self.deltaTemp;
        temp=self.tempSensorSource;
    }
}
@end
