//
//  sgModel.m
//  HWSensors
//
//  Created by Navi on 22.02.12.
//  Copyright (c) 2012 . All rights reserved.
//
#import "sgModel.h"

#define Debug true

#ifdef Debug
#define DebugLog(string, args...)	do { if (Debug) { NSLog (string , ## args); } } while(0)
#else
#define DebugLog
#endif

#define MAXRPM_TO_DIFFER 100

@implementation sgModel

@synthesize fans;

+ (UInt16) swap_value:(UInt16) value
{
    return ((value & 0xff00) >> 8) | ((value & 0xff) << 8);
}

+ (UInt16) encode_fp2e:(UInt16) value
{
    UInt32 tmp = value;
    tmp = (tmp << 14) / 1000;
    value = (UInt16)(tmp & 0xffff);
    return [sgModel swap_value: value];
}

+ (UInt16) encode_fp4c:(UInt16) value
{
    
    UInt32 tmp = value;
    tmp = (tmp << 12) / 1000;
    value = (UInt16)(tmp & 0xffff);
    return [sgModel swap_value: value];
}

+ (UInt16)  encode_fpe2:(UInt16) value
{
    return [sgModel swap_value: value<<2];
}

+ (UInt16)  decode_fpe2:(UInt16) value
{
    return [sgModel swap_value: value] >> 2;
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
    NSData * value = NULL;
    
    io_service_t service = IOServiceGetMatchingService(0, IOServiceMatching(kFakeSMCDeviceService));
    
    if (service) {
        NSDictionary * values = (__bridge_transfer /*__bridge_transfer*/ NSDictionary *)IORegistryEntryCreateCFProperty(service, CFSTR(kFakeSMCDeviceValues), kCFAllocatorDefault, 0);
        
        if (values) 
            value = [values valueForKey:key];
        
        IOObjectRelease(service);
    }
    
    return value;
}


+(UInt32) numberOfFans {
  
    UInt32 value = 0; 
    NSData * data = [sgModel readValueForKey:@"FNum"];
    if(data)
        bcopy([data bytes],&value,[data length]<4 ? [data length] : 4);
    return value;
}




-(NSDictionary *) initialPrepareFan:(NSUInteger) fanId 
{
    if (fanId < [sgModel numberOfFans]) {
        NSMutableDictionary * fan = [NSMutableDictionary dictionaryWithCapacity:20] ; 
        NSString * fanReadKey = [NSString stringWithFormat:@"F%dAc",fanId];
        NSString * description = [[NSString alloc] initWithData:[sgModel readValueForKey:[[NSString alloc] initWithFormat:@"F%XID",fanId] ]encoding: NSUTF8StringEncoding];
        [fan setObject:@"" forKey:KEY_NAME];
        [fan setObject:description forKey:KEY_DESCRIPTION];
        [fan setObject:fanReadKey forKey:KEY_READ_RPM];
        [fan setObject:@"" forKey:KEY_FAN_CONTROL];
        [fan setObject:[NSNumber numberWithBool:NO] forKey:KEY_CONTROLABLE];
        [fan setObject:[NSNumber numberWithBool:NO]  forKey:KEY_CALIBRATED];
        
        NSData * dataptr = [sgModel readValueForKey: fanReadKey];
        UInt16 value = [sgModel decode_fpe2:*((UInt16 *)[dataptr bytes])];
        [fan setObject:[NSString stringWithFormat:@"%d RPM", value ] forKey:KEY_CURRENT_RPM];
        [fan setObject: [NSMutableArray arrayWithCapacity:0] forKey:KEY_DATA_UPWARD];
        [fan setObject: [NSMutableArray arrayWithCapacity:0] forKey:KEY_DATA_DOWNWARD];
        return fan; 
    }
    return nil;
}

-(sgModel *) init
{
    fans = [NSMutableDictionary dictionaryWithCapacity:0];
    return self;
}

-(BOOL) addFan: (NSDictionary *) desc withName:(NSString *) name
{
    [fans setValue:desc forKey: name];
    return YES;
}

-(BOOL) writeFanDictionatyToFile: (NSString *) filename
{
    return [fans writeToFile:filename atomically:YES];
}

-(BOOL) calibrateFan:(NSString *) fanId
{
    NSMutableDictionary * fan;
    DebugLog(@"Starting calibration for %@",fanId);
    if ((fan = [fans valueForKey:fanId])) {
        if ([[fan valueForKey:KEY_CONTROLABLE] boolValue] == NO) return NO;
        
        NSMutableArray * calibrationDataUp = [fan valueForKey:KEY_DATA_UPWARD];
        NSMutableArray * calibrationDataDown = [fan valueForKey:KEY_DATA_DOWNWARD];


        NSString * FanRPMReadKey = [fan valueForKey:KEY_READ_RPM];
        NSString * FanControlKey = [fan valueForKey:KEY_FAN_CONTROL];
        NSData * originalPWM = [sgModel readValueForKey:FanControlKey];
        int i = 0;
        [sgModel writeValueForKey:FanControlKey data:[NSData dataWithBytes:&i length:1]]; 
        [NSThread sleepForTimeInterval:SpinTime];  // Give a time to stop rotation
        
        // Upward disrection
        for( i=0;i<128;i++)
        {
            [sgModel writeValueForKey:FanControlKey data:[NSData dataWithBytes:&i length:1]];  
            [NSThread sleepForTimeInterval:SpinTransactionTime]; //  Give some time for fan to reach the stable rotation
            NSData * dataptr = [sgModel readValueForKey:FanRPMReadKey];
            UInt16 value = [sgModel decode_fpe2:*((UInt16 *)[dataptr bytes])];
            NSNumber * num = [NSNumber numberWithInt:value];
            [calibrationDataUp addObject:num];
            DebugLog(@"RPMs for FAN %@ at PWM = %d  is %d",FanRPMReadKey, i, value);
        }
        //Downward direction
        for( i=127;i>=0;i--)
        {
            [sgModel writeValueForKey:FanControlKey data:[NSData dataWithBytes:&i length:1]];  
            [NSThread sleepForTimeInterval:SpinTransactionTime]; //  Give some time for fan to reach the stable rotation
            NSData * dataptr = [sgModel readValueForKey:FanRPMReadKey];
            UInt16 value = [sgModel decode_fpe2:*((UInt16 *)[dataptr bytes])];
            NSNumber * num = [NSNumber numberWithInt:value];
            [calibrationDataDown insertObject:num atIndex: 0];
            DebugLog(@"RPMs for FAN %@  at PWM = %d  is %d",FanRPMReadKey, i, value);
        }
            
        [sgModel writeValueForKey:FanControlKey data:originalPWM];
        [fan setObject:[NSNumber numberWithBool:YES] forKey:KEY_CALIBRATED];
        return YES;
    }
    return NO;
}

+(NSUInteger) whoDiffersFor:(NSArray *) current andPrevious:(NSArray *) previous andMaxDev:(NSUInteger) maxDev;
{
    if([current count]!=[previous count]) return NSNotFound; // Arrays must be equal in size
    __block NSUInteger maxDeviation = maxDev;
    [current enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DebugLog(@"%ld - %ld",[obj integerValue],[[previous objectAtIndex:idx] integerValue]);
        if(labs([obj integerValue] - [[previous objectAtIndex:idx] integerValue])> maxDeviation)
            maxDeviation=abs([obj intValue] - [[previous objectAtIndex:idx] intValue]);
    }];
    if(maxDev>=maxDeviation) return NSNotFound;
    return [current indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop)
             {
                 DebugLog(@"Difference %ld, max deviation %ld",labs([obj integerValue] - [[previous objectAtIndex:idx] integerValue]),maxDeviation );
                 if(labs([obj integerValue] - [[previous objectAtIndex:idx] integerValue]) >= maxDeviation)
                    {
                        *stop=YES;
                        return YES;
                    }
                 return NO;
            }
    ];
    
}

-(NSUInteger) rpmForFan: (NSString *) name
{
    NSDictionary * fan;
    if ((fan = [fans valueForKey:name])) 
    {
        NSData * dataptr = [sgModel readValueForKey:[fan valueForKey:KEY_READ_RPM]];
        UInt16 value = [sgModel decode_fpe2:*((UInt16 *)[dataptr bytes])];
        return value;
    }
        
    return NSNotFound;
}

-(void) findControllers
{
    NSMutableArray * cur, * prev, * names;
    
    cur = [NSMutableArray arrayWithCapacity:0];
    prev = [NSMutableArray arrayWithCapacity:0];
    names = [NSMutableArray arrayWithCapacity:0];
    
    int i=0,temp=0;
    
    for (i=0; i<[sgModel numberOfFans]; i++) {
        NSData * originalPWM = [sgModel readValueForKey:[NSString stringWithFormat:@"F%dTg",i]];
        temp=0;
        [sgModel writeValueForKey:[NSString stringWithFormat:@"F%dTg",i]  data:[NSData dataWithBytes:&temp length:1]];
        [NSThread sleepForTimeInterval:SpinTime];
        [fans enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [prev addObject:[NSNumber numberWithInteger:[self rpmForFan:key]]];
            [names addObject:key];
        }];
        temp=127;
        [sgModel writeValueForKey:[NSString stringWithFormat:@"F%dTg",i]  data:[NSData dataWithBytes:&temp length:1]];
        [NSThread sleepForTimeInterval:SpinTime];
        [fans enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [cur addObject:[NSNumber numberWithInteger:[self rpmForFan:key]]];
        }];
        [sgModel writeValueForKey:[NSString stringWithFormat:@"F%dTg",i]  data:originalPWM];
        NSInteger index = [sgModel whoDiffersFor:cur andPrevious:prev andMaxDev:MAXRPM_TO_DIFFER];
        if ( index != NSNotFound) {
            [[fans objectForKey:[names objectAtIndex:index]] setObject:[NSString stringWithFormat:@"F%dTg",i] forKey:KEY_FAN_CONTROL];
            [[fans objectForKey:[names objectAtIndex:index]] setObject: [NSNumber numberWithBool:YES] forKey:KEY_CONTROLABLE];
        }
        [cur removeAllObjects];
        [prev removeAllObjects];
        [names removeAllObjects];
    }
    
}

@end
