//
//  IOBatteryStatus.m
//  HWSensors
//
//  Created by Navi on 04.01.13.
//
//

#import "IOBatteryStatus.h"

@implementation IOBatteryStatus


+(BOOL) keyboardAvailable
{
    io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("AppleBluetoothHIDKeyboard"));
    BOOL value=YES;
   
    if (!service ) {
		value =  NO;
    }
    IOObjectRelease(service);
    return value;
}



+(BOOL) trackpadAvailable
{
    io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("BNBTrackpadDevice"));
    BOOL value=YES;
    
    if (!service ) {
		value =  NO;
    }
    IOObjectRelease(service);
    return value;
}

+(BOOL) mouseAvailable
{
    io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("BNBMouseDevice"));
    BOOL value=YES;
    
    if (!service ) {
		value =  NO;
    }
    IOObjectRelease(service);
    return value;
}

+(NSString *) getKeyboardName
{
    io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("AppleBluetoothHIDKeyboard"));
    NSString * value = nil;
    
    if (!service ) {
		return nil;
    }
    value = (__bridge_transfer  NSString *)IORegistryEntryCreateCFProperty(service, CFSTR("Product"), kCFAllocatorDefault, 0);
    
    IOObjectRelease(service);
    return value;
    
}

+(NSString *) getTrackpadName
{
    io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("BNBTrackpadDevice"));
    NSString * value = nil;
    
  if (!service ) {
		return nil;
    }
    value = (__bridge_transfer  NSString *)IORegistryEntryCreateCFProperty(service, CFSTR("Product"), kCFAllocatorDefault, 0);
    
    IOObjectRelease(service);
    return value;
    
}

+(NSString *) getMouseName
{
    io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("BNBMouseDevice"));
    NSString * value = nil;
    
   if (!service ) {
		return nil;
    }
    value = (__bridge_transfer  NSString *)IORegistryEntryCreateCFProperty(service, CFSTR("Product"), kCFAllocatorDefault, 0);
    
    IOObjectRelease(service);
    return value;
    
}

+(NSInteger ) getKeyboardBatteryLevel
{
    io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("AppleBluetoothHIDKeyboard"));
   
    
    if (!service ) {
		return nil;
    }
    NSNumber * percent = (__bridge_transfer  NSNumber *)IORegistryEntryCreateCFProperty(service, CFSTR("BatteryPercent"), kCFAllocatorDefault, 0);
    
    IOObjectRelease(service);
    return [percent integerValue];
    
}

+(NSInteger ) getTrackpadBatteryLevel
{
    io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("BNBTrackpadDevice"));

    
    if (!service ) {
		return nil;
    }
    NSNumber * percent = (__bridge_transfer  NSNumber *)IORegistryEntryCreateCFProperty(service, CFSTR("BatteryPercent"), kCFAllocatorDefault, 0);
    
    IOObjectRelease(service);
    return [percent integerValue];
    
}

+(NSInteger ) getMouseBatteryLevel
{
    io_service_t service = IOServiceGetMatchingService(0, IOServiceNameMatching("BNBMouseDevice"));

    
    if (!service ) {
		return nil;
    }
    NSNumber * percent = (__bridge_transfer  NSNumber *)IORegistryEntryCreateCFProperty(service, CFSTR("BatteryPercent"), kCFAllocatorDefault, 0);
    
    IOObjectRelease(service);
    return [percent integerValue];
    
}


+(NSDictionary *) getAllBatteriesLevel
{
    NSMutableDictionary * dataset = [[NSMutableDictionary alloc] initWithCapacity:0];
    NSInteger value = 0;
    if([IOBatteryStatus keyboardAvailable])
    {
        value = [IOBatteryStatus getKeyboardBatteryLevel];
        [dataset setValue:[NSData dataWithBytes:&value  length:sizeof(value)]  forKey:[IOBatteryStatus getKeyboardName]];
    }
    if([IOBatteryStatus trackpadAvailable])
    {
        value = [IOBatteryStatus getTrackpadBatteryLevel];
        [dataset setValue: [NSData dataWithBytes:&value  length:sizeof(value)] forKey:[IOBatteryStatus getTrackpadName]];
    }
    if([IOBatteryStatus mouseAvailable])
    {
        value = [IOBatteryStatus getMouseBatteryLevel];
        [dataset setValue:[NSData dataWithBytes:&value  length:sizeof(value)] forKey:[IOBatteryStatus getMouseName]];
    }
    return dataset;
}
@end
