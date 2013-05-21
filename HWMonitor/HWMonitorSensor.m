//
//  NSSensor.m
//  HWSensors
//
//  Created by mozo on 22.10.11.
//  Copyright (c) 2011 mozo. All rights reserved.
//

#import "HWMonitorSensor.h"

#include "FakeSMCDefinitions.h"
#include "smc.h"

#define SMC_ACCESS
#define BIT(x) (1 << (x))
#define bit_get(x, y) ((x) & (y))
#define bit_clear(x, y) ((x) &= (~y))


int getIndexOfHexChar(char);
float decodeNumericValue(NSData*, NSString*);

int getIndexOfHexChar(char c) {
    return c > 96 && c < 103 ? c - 87 : c > 47 && c < 58 ? c - 48 : 0;
}

float decodeNumericValue(NSData* _data, NSString*_type)
{
    if (_type && _data && [_type length] >= 3) {
        if (([_type characterAtIndex:0] == 'u' || [_type characterAtIndex:0] == 's') && [_type characterAtIndex:1] == 'i') {

            BOOL signd = [_type characterAtIndex:0] == 's';

            switch ([_type characterAtIndex:2]) {
                case '8':
                    if ([_data length] == 1) {
                        UInt8 encoded = 0;

                        bcopy([_data bytes], &encoded, 1);

                        if (signd && bit_get(encoded, BIT(7))) {
                            bit_clear(encoded, BIT(7));
                            return -encoded;
                        }

                        return encoded;
                    }
                    break;

                case '1':
                    if ([_type characterAtIndex:3] == '6' && [_data length] == 2) {
                        UInt16 encoded = 0;

                        bcopy([_data bytes], &encoded, 2);

                        encoded = OSSwapBigToHostInt16(encoded);

                        if (signd && bit_get(encoded, BIT(15))) {
                            bit_clear(encoded, BIT(15));
                            return -encoded;
                        }

                        return encoded;
                    }
                    break;

                case '3':
                    if ([_type characterAtIndex:3] == '2' && [_data length] == 4) {
                        UInt32 encoded = 0;

                        bcopy([_data bytes], &encoded, 4);

                        encoded = OSSwapBigToHostInt32(encoded);

                        if (signd && bit_get(encoded, BIT(31))) {
                            bit_clear(encoded, BIT(31));
                            return -encoded;
                        }

                        return encoded;
                    }
                    break;
            }
        }
        else if (([_type characterAtIndex:0] == 'f' || [_type characterAtIndex:0] == 's') && [_type characterAtIndex:1] == 'p' && [_data length] == 2) {
            UInt16 encoded = 0;

            bcopy([_data bytes], &encoded, 2);

            UInt8 i = getIndexOfHexChar([_type characterAtIndex:2]);
            UInt8 f = getIndexOfHexChar([_type characterAtIndex:3]);

            if (i + f != ([_type characterAtIndex:0] == 's' ? 15 : 16) )
                return 0;

            UInt16 swapped = OSSwapBigToHostInt16(encoded);

            BOOL signd = [_type characterAtIndex:0] == 's';
            BOOL minus = bit_get(swapped, BIT(15));

            if (signd && minus) bit_clear(swapped, BIT(15));

            return ((float)swapped / (float)BIT(f)) * (signd && minus ? -1 : 1);
        }
    }

    return 0;
}

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
    
#ifndef SMC_ACCESS
    NSData * value = NULL;
    
    io_service_t service = IOServiceGetMatchingService(0, IOServiceMatching(kFakeSMCDeviceService));
    
    if (service) {
        CFTypeRef message = (CFTypeRef) CFStringCreateWithCString(kCFAllocatorDefault, "magic", kCFStringEncodingASCII);
        
        if (kIOReturnSuccess == IORegistryEntrySetCFProperty(service, CFSTR(kFakeSMCDevicePopulateValues), message))
        {
            NSDictionary * values = (__bridge_transfer  NSDictionary *)IORegistryEntryCreateCFProperty(service, CFSTR(kFakeSMCDeviceValues), kCFAllocatorDefault, 0);
            
            //           NSDictionary * values = (__bridge NSDictionary *)IORegistryEntryCreateCFProperty(service, CFSTR(kFakeSMCDeviceValues), kCFAllocatorDefault, 0);
            if (values)
                value = [values valueForKey:key];
        }
        IOObjectRelease(service);
        CFRelease(message);
    }
    
    return value;
#else
    SMCOpen(&conn);
    
    UInt32Char_t  readkey = "\0";
    strncpy(readkey,[key cStringUsingEncoding:NSASCIIStringEncoding]==NULL ? "" : [key cStringUsingEncoding:NSASCIIStringEncoding],4);
    readkey[4]=0;
    SMCVal_t      val;
    
    kern_return_t result = SMCReadKey(readkey, &val);
                if (result != kIOReturnSuccess)
                    return NULL;
    SMCClose(conn);
    if (val.dataSize > 0)
    {

        /*if (strncmp(val.dataType, TYPE_SP78, 4))
        {
            
        } */
        return [NSData dataWithBytes:val.bytes length:val.dataSize];
    }
    return nil;
#endif
}

+ (NSString *) getTypeOfKey:(NSString *)key
{
    
#ifndef SMC_ACCESS
	return @TYPE_SP78;
/*	for (int i=0; i<0xA; i++)
  {
    [self addSensorWithKey:[[NSString alloc] initWithFormat:@"TC%XD",i] andType: @TYPE_SP78 andCaption:[[NSString alloc] initWithFormat:@"CPU %X Diode",i] intoGroup:TemperatureSensorGroup ];
    [self addSensorWithKey:[[NSString alloc] initWithFormat:@"TC%XH",i] andType: @TYPE_SP78 andCaption:[[NSString alloc] initWithFormat:@"CPU %X Core",i] intoGroup:TemperatureSensorGroup ];
  }
  [self addSensorWithKey:@"TC0P" andType: @TYPE_SP78 andCaption:NSLocalizedString( @"CPU Proximity", nil) intoGroup:TemperatureSensorGroup ];
  [self addSensorWithKey:@"Th0H" andType: @TYPE_SP78 andCaption:NSLocalizedString( @"CPU Heatsink", nil) intoGroup:TemperatureSensorGroup ];
  [self addSensorWithKey:@"TN0P" andType: @TYPE_SP78 andCaption:NSLocalizedString(@"Motherboard",nil) intoGroup:TemperatureSensorGroup ];
  [self addSensorWithKey:@"Tm0P" andType: @TYPE_SP78 andCaption:NSLocalizedString(@"Memory",nil) intoGroup:TemperatureSensorGroup ];
  [self addSensorWithKey:@"TA0P" andType: @TYPE_SP78 andCaption:NSLocalizedString(@"Ambient",nil) intoGroup:TemperatureSensorGroup ];
  
  for (int i=0; i<0xA; i++) {
    [self addSensorWithKey:[[NSString alloc] initWithFormat:@"TG%XD",i] andType: @TYPE_SP78 andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %X Core",nil) ,i] intoGroup:TemperatureSensorGroup ];
    [self addSensorWithKey:[[NSString alloc] initWithFormat:@"TG%XH",i] andType: @TYPE_SP78 andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %X Board",nil),i] intoGroup:TemperatureSensorGroup ];
    [self addSensorWithKey:[[NSString alloc] initWithFormat:@"TG%XP",i] andType: @TYPE_SP78 andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %X Proximity",nil),i] intoGroup:TemperatureSensorGroup ];
  }
  
  [self insertFooterAndTitle:NSLocalizedString( @"TEMPERATURES",nil) andImage:[NSImage imageNamed:@"temp_alt_small"]];  
  
  for (int i=0; i<16; i++)
    [self addSensorWithKey:[[NSString alloc] initWithFormat:@"FRC%X",i] andType: @TYPE_FREQ andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"CPU %X",nil),i] intoGroup:FrequencySensorGroup ];
  
  //
  for (int i=0; i<0xA; i++) {
    [self addSensorWithKey:[[NSString alloc] initWithFormat:@KEY_FAKESMC_FORMAT_GPU_FREQUENCY,i] andType: @TYPE_SP78 andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %X Core",nil) ,i] intoGroup:FrequencySensorGroup ];
    [self addSensorWithKey:[[NSString alloc] initWithFormat:@KEY_FAKESMC_FORMAT_GPU_SHADER_FREQUENCY,i] andType: @TYPE_SP78 andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %X Shaders",nil) ,i] intoGroup:FrequencySensorGroup ];
    
    // Temporary disable GPU ROP and Memory reporting
    //        [self addSensorWithKey:[[NSString alloc] initWithFormat:@KEY_FAKESMC_FORMAT_GPU_MEMORY_FREQUENCY,i] andType: @TYPE_SP78 andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %X Memory",nil) ,i] intoGroup:FrequencySensorGroup ];
    //        [self addSensorWithKey:[[NSString alloc] initWithFormat:@KEY_FAKESMC_FORMAT_GPU_ROP_FREQUENCY,i] andType: @TYPE_SP78 andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %X ROP",nil) ,i] intoGroup:FrequencySensorGroup ];
    //
    [self insertFooterAndTitle:NSLocalizedString(@"FREQUENCIES",nil) andImage:[NSImage imageNamed:@"freq_small"]];
  }
  //Multipliers
  
  for (int i=0; i<0xA; i++) {
    [self addSensorWithKey:[[NSString alloc] initWithFormat:@"MC%XC",i] andType: @TYPE_FP4C andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"CPU %X Multiplier",nil),i] intoGroup:MultiplierSensorGroup ];
  }
  [self addSensorWithKey:@"MPkC" andType: @TYPE_FP4C andCaption:NSLocalizedString(@"CPU Package Multiplier",nil) intoGroup:MultiplierSensorGroup ];
  
  [self insertFooterAndTitle:NSLocalizedString(@"MULTIPLIERS",nil)andImage:[NSImage imageNamed:@"multiply_small"]];
  
  // Voltages
  
  [self addSensorWithKey:@KEY_CPU_VOLTAGE andType: @TYPE_FP2E andCaption:NSLocalizedString(@"CPU Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_CPU_VRM_SUPPLY0 andType: @TYPE_FP2E andCaption:NSLocalizedString(@"CPU VRM Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_MEMORY_VOLTAGE andType: @TYPE_FP2E andCaption:NSLocalizedString(@"DIMM Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_12V_VOLTAGE andType: @TYPE_SP4B andCaption:NSLocalizedString(@"+12V Bus Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_5VC_VOLTAGE andType: @TYPE_SP4B andCaption:NSLocalizedString(@"+5V Bus Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_N12VC_VOLTAGE andType: @TYPE_SP4B andCaption:NSLocalizedString(@"-12V Bus Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_5VSB_VOLTAGE andType: @TYPE_SP4B andCaption:NSLocalizedString(@"-5V Bus Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_3VCC_VOLTAGE andType: @TYPE_FP2E andCaption:NSLocalizedString(@"3.3 VCC Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_3VSB_VOLTAGE andType: @TYPE_FP2E andCaption:NSLocalizedString(@"3.3 VSB Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_VBAT_VOLTAGE andType: @TYPE_FP2E andCaption:NSLocalizedString(@"Battery Voltage",nil) intoGroup:VoltageSensorGroup ];
  for (int i=0; i<0xA; i++) {
    [self addSensorWithKey:[[NSString alloc] initWithFormat:@KEY_FORMAT_GPU_VOLTAGE,i] andType: @TYPE_FP2E andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %X Voltage",nil) ,i] intoGroup:VoltageSensorGroup ];
  }
  
  [self insertFooterAndTitle:NSLocalizedString(@"VOLTAGES",nil) andImage:[NSImage imageNamed:@"voltage_small"]];
  
  // Fans
  
  for (int i=0; i<10; i++)   {
    FanTypeDescStruct * fds;
    NSData * keydata = [HWMonitorSensor readValueForKey:[[NSString alloc] initWithFormat:@"F%XID",i]];
    NSString * caption;
    if(keydata) {
      fds = [keydata bytes];
      caption = [[[NSString alloc] initWithBytes:  fds->strFunction length: DIAG_FUNCTION_STR_LEN encoding: NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[[NSCharacterSet letterCharacterSet] invertedSet]];
    } else {
      caption = @"";
    }
    if([caption length]<=0) {
      caption = [[NSString alloc] initWithFormat:@"Fan %d",i];
    }
    [self addSensorWithKey:[[NSString alloc] initWithFormat:@"F%XAc",i] andType: @TYPE_FPE2 andCaption:caption intoGroup:TachometerSensorGroup ];    
  }
  
  [self insertFooterAndTitle:NSLocalizedString(@"FANS",nil) andImage:[NSImage imageNamed:@"fan_small"]];
  // Disks
  NSEnumerator * DisksEnumerator = [DisksList keyEnumerator]; 
  id nextDisk;
  while (nextDisk = [DisksEnumerator nextObject]) {
    [self addSensorWithKey:nextDisk andType: @TYPE_FPE2 andCaption:nextDisk intoGroup:HDSmartTempSensorGroup];
  }
  
  [self insertFooterAndTitle:NSLocalizedString(@"HARD DRIVES TEMPERATURES",nil) andImage:[NSImage imageNamed:@"hd_small"]];
  
  NSEnumerator * BatteryEnumerator = [BatteriesList keyEnumerator];
  id nextBattery;
  
  while (nextBattery = [BatteryEnumerator nextObject]) {
    [self addSensorWithKey:nextBattery andType:@TYPE_FPE2 andCaption:nextBattery intoGroup:BatterySensorsGroup];
  }
  
  [self insertFooterAndTitle:NSLocalizedString(@"BATTERIES",nil) andImage:[NSImage imageNamed:@"modern-battery-icon"]];
  
  if (![sensorsList count]) {
    NSMenuItem * item = [[NSMenuItem alloc]initWithTitle:@"No sensors found or FakeSMCDevice unavailable" action:nil keyEquivalent:@""];
    
    [item setEnabled:FALSE];
    
    [statusMenu insertItem:item atIndex:0];
  }
*/
#else
    SMCOpen(&conn);
    
    UInt32Char_t  readkey = "\0";
    strncpy(readkey,[key cStringUsingEncoding:NSASCIIStringEncoding]==NULL ? "" : [key cStringUsingEncoding:NSASCIIStringEncoding],4);
    readkey[4]=0;
    SMCVal_t      val;
    
    kern_return_t result = SMCReadKey(readkey, &val);
                if (result != kIOReturnSuccess)
                    return NULL;
    SMCClose(conn);
    if (val.dataSize > 0)
        return [NSString stringWithFormat:@"%.4s", val.dataType];
    return nil;
#endif
}


- (HWMonitorSensor *)initWithKey:(NSString *)aKey andType: aType andGroup:(NSUInteger)aGroup withCaption:(NSString *)aCaption
{
    type = aType;
    key = aKey;
    group = aGroup;
    caption = aCaption;
    
    return self;
}

- (NSString *) formatedValue:(NSData *)value
{
    if (value != nil) {
		float v = decodeNumericValue(value, type);
        switch (group) {
            case TemperatureSensorGroup:
				return [[NSString alloc] initWithFormat:@"%2d°",(int)v];
            
            case HDSmartTempSensorGroup:
			{
                unsigned int t = 0;
                
                bcopy([value bytes], &t, 2);
                
                //t = [NSSensor swapBytes:t] >> 8;
                return [[NSString alloc] initWithFormat:@"%d°",t];
            }
                
            case BatterySensorsGroup:
			{
                NSInteger * t;
                t = (NSInteger*)[value bytes];
				return [[NSString alloc] initWithFormat:@"%ld%%",*t];
            }
                
            case VoltageSensorGroup:
            	return [[NSString alloc] initWithFormat:@"%2.3f", v];
                
            case TachometerSensorGroup:
                return [[NSString alloc] initWithFormat:@"%drpm",(int)v];
            
			case FrequencySensorGroup:
            {
                unsigned int MHZ = 0;
                
                bcopy([value bytes], &MHZ, 2);
                
                MHZ = [HWMonitorSensor swapBytes:MHZ];
                
                return [[NSString alloc] initWithFormat:@"%dMHz",MHZ];
                
            } break;  
                
            case MultiplierSensorGroup:
            {
                unsigned int mlt = 0;
                
                bcopy([value bytes], &mlt, 2);
                
                return [[NSString alloc] initWithFormat:@"x%1.1f",(float)mlt / 10.0];
            } break;
         
        }
    }
    
    return @"-";
}



@end
