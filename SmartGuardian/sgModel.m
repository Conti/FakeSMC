//
//  sgModel.m
//  HWSensors
//
//  Created by Иван Синицин on 22.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import "sgModel.h"




@implementation sgModel

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


-(sgModel *) init
{
    fans = [NSMutableArray arrayWithCapacity:1];
    return self;
}

-(NSDictionary *) testPrepareFan 
{
    NSMutableDictionary * fan = [NSMutableDictionary dictionaryWithCapacity:20];    
    [fan setObject:@"F0Ac" forKey:@"RPM Read Key"];
    [fan setObject:@"F2Tg" forKey:@"Fan Control Key"];

    [fan setObject: [NSMutableArray arrayWithCapacity:0] forKey:@"Calibration Data"];
    return fan; 
}

-(BOOL) addFan: (NSDictionary *) desc
{
    [fans addObject:desc];
    return YES;
}

-(BOOL) calibrateFan:(NSUInteger) fanId
{
    NSDictionary * fan;
    if ((fan = [fans objectAtIndex:fanId])) {
        NSMutableArray * calibrationData = [fan valueForKey:@"Calibration Data"];
//        if (calibrationData) {
//            NSNumber * stub[128];
//            calibrationData = [NSMutableArray arrayWithObjects:stub count:128];
//        }
        NSString * FanRPMReadKey = [fan valueForKey:@"RPM Read Key"];
        NSString * FanControlKey = [fan valueForKey:@"Fan Control Key"];
        NSData * originalPWM = [sgModel readValueForKey:FanControlKey];
        for(int i=0;i<128;i++)
        {
            [sgModel writeValueForKey:FanControlKey data:[NSData dataWithBytes:&i length:1]];  
            [NSThread sleepForTimeInterval:1.0]; //  Give some time for fan to reach the stable rotation
            NSData * dataptr = [sgModel readValueForKey:FanRPMReadKey];
            UInt16 value = [sgModel decode_fpe2:*((UInt16 *)[dataptr bytes])];
            NSNumber * num = [NSNumber numberWithInt:value];
            [calibrationData addObject:num];
            NSLog(@"RPMs at PWM = %d  is %d", i, value);
        }
            
        
        return YES;
    }
    return NO;
}

@end
