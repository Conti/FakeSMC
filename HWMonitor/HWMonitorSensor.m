//
//  NSSensor.m
//  HWSensors
//
//  Created by mozo on 22.10.11.
//  Copyright (c) 2011 mozo. All rights reserved.
//

#import "HWMonitorSensor.h"

#include "FakeSMCDefinitions.h"

@implementation HWMonitorSensor

@synthesize key;
@synthesize type;
@synthesize group;
@synthesize caption;
@synthesize object;
@synthesize favorite;

+ (unsigned int)swapBytes:(unsigned int) value
{
    return ((value & 0xff00) >> 8) | ((value & 0xff) << 8);
}



+ (NSData *) readValueForKey:(NSString *)key
{
    NSData * value = NULL;
    
    io_service_t service = IOServiceGetMatchingService(0, IOServiceMatching(kFakeSMCDeviceService));
    
    if (service) {
        CFTypeRef message = (CFTypeRef) CFStringCreateWithCString(kCFAllocatorDefault, "magic", kCFStringEncodingASCII);
        
        if (kIOReturnSuccess == IORegistryEntrySetCFProperty(service, CFSTR(kFakeSMCDevicePopulateValues), message))
        {
        NSDictionary * values = (__bridge_transfer /*__bridge_transfer*/ NSDictionary *)IORegistryEntryCreateCFProperty(service, CFSTR(kFakeSMCDeviceValues), kCFAllocatorDefault, 0);
        
        if (values) 
            value = [values valueForKey:key];
        }
        IOObjectRelease(service);
    }
    
    return value;
}

- (HWMonitorSensor *)initWithKey:(NSString *)aKey andType: aType andGroup:(NSUInteger)aGroup withCaption:(NSString *)aCaption
{
    type = aType;
    key = aKey;
    group = aGroup;
    caption = aCaption;
    
    return self;
}

- (NSString *) formateValue:(NSData *)value
{
    if (value != NULL) {
        switch (group) {
            case TemperatureSensorGroup:
            {
                unsigned int t = 0;
                
                bcopy([value bytes], &t, 2);
                
                //t = [NSSensor swapBytes:t] >> 8;
                
                return [[NSString alloc] initWithFormat:@"%d°",t];
                
            } break;
            
            case HDSmartTempSensorGroup:
            {
                unsigned int t = 0;
                
                bcopy([value bytes], &t, 2);
                
                //t = [NSSensor swapBytes:t] >> 8;
                
                return [[NSString alloc] initWithFormat:@"%d°",t];
                
            } break;
                
                
            case VoltageSensorGroup:
            {
                unsigned int encoded = 0;
                
                bcopy([value bytes], &encoded, 2);
                
                encoded = [HWMonitorSensor swapBytes:encoded];
                
                if ([type isEqualToString:@TYPE_FP4C]){ 
                float v = ((float) encoded )/ 4096.0f; //2^12
                return [[NSString alloc] initWithFormat:@"%2.3fV",v];
                }
                else if ([type isEqualToString:@TYPE_FP2E])
                { 
                float v = ((float) encoded) / 16384.0f; //2^14
                return [[NSString alloc] initWithFormat:@"%1.3fV",v]; 
                }
            } break;
                
            case TachometerSensorGroup:
            {
                unsigned int rpm = 0;
                
                bcopy([value bytes], &rpm, 2);
                
                rpm = [HWMonitorSensor swapBytes:rpm] >> 2;
                
                return [[NSString alloc] initWithFormat:@"%drpm",rpm];
                
            } break;
            case FrequencySensorGroup:
            {
                unsigned int MHZ = 0;
                
                bcopy([value bytes], &MHZ, 2);
                
                MHZ = [HWMonitorSensor swapBytes:MHZ];
                
                return [[NSString alloc] initWithFormat:@"%dMhz",MHZ];
                
            } break;  
                
            case MultiplierSensorGroup:
            {
                unsigned int mlt = 0;
                
                bcopy([value bytes], &mlt, 2);
                
                return [[NSString alloc] initWithFormat:@"x%1.1f",(float)mlt / 10.0];
                
            } break;
                
            default:
                return [[NSString alloc] initWithString:@"-"];
                break;
        }
    }
    
    return nil;
}

@end
