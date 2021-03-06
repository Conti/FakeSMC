//
//  AppDelegate.m
//  HWMonitor
//
//  Created by mozo,Navi on 20.10.11.
//  Copyright (c) 2011 mozo. All rights reserved.
//

#import "AppDelegate.h"
#import "NSString+TruncateToWidth.h"
#import "IOBatteryStatus.h"
#include "FakeSMCDefinitions.h"

@implementation AppDelegate

#define SMART_UPDATE_INTERVAL 5*60

- (void)updateTitles
{
  
  NSEnumerator * enumerator = nil;
  HWMonitorSensor * sensor = nil;
  
  NSMutableString * statusString = [[NSMutableString alloc] init];
  int count = 0;
  io_service_t service = IOServiceGetMatchingService(0, IOServiceMatching(kFakeSMCDeviceService));
  
  NSMutableDictionary * values;
  CFTypeRef message;
  if (service) {
    
    message = (CFTypeRef) CFStringCreateWithCString(kCFAllocatorDefault, "magic", kCFStringEncodingASCII);
    if (kIOReturnSuccess == IORegistryEntrySetCFProperty(service, CFSTR(kFakeSMCDevicePopulateValues), message))
      values = (__bridge_transfer NSMutableDictionary *)IORegistryEntryCreateCFProperty(service, CFSTR(kFakeSMCDeviceValues), kCFAllocatorDefault, 0);
	}
	else
		values = [NSMutableDictionary dictionaryWithCapacity:0];
      
      
      if(smart)
      {
        if (fabs([lastcall timeIntervalSinceNow]) > SMART_UPDATE_INTERVAL) 
        {
          lastcall = [NSDate date];
          [smartController update];
        }
        [values addEntriesFromDictionary:[smartController getDataSet:1]];
      }
      NSDictionary * temp = [IOBatteryStatus getAllBatteriesLevel];
      if ([temp count] >0)
      {
        [values addEntriesFromDictionary:temp];
        BOOL __block needFooter = YES;
        [temp enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
          BOOL found = NO;
          NSEnumerator * sensorsEnumerator = [sensorsList objectEnumerator];
          HWMonitorSensor * localSensor;
          while (localSensor = (HWMonitorSensor *)[sensorsEnumerator nextObject]) {
            if ([key isEqualToString:[localSensor key]]) {
              found = YES;
              needFooter = NO;
            }
          }
          if(!found){
            [self addSensorWithKey:key andType:@TYPE_FPE2 andCaption:key intoGroup:BatterySensorsGroup];
          }
          
          
        }];
        if(needFooter)
          [self insertFooterAndTitle:NSLocalizedString(@"BATTERIES",nil) andImage:[NSImage imageNamed:@"modern-battery-icon"]];
      }
      
      if (values) {
        
        enumerator = [sensorsList objectEnumerator];
        
        
        while (sensor = (HWMonitorSensor *)[enumerator nextObject]) {
          
          if (isMenuVisible) {
            
            
            NSString * value =[sensor formatedValue:[values objectForKey:[sensor key]] ? [values objectForKey:[sensor key]] : [HWMonitorSensor readValueForKey:[sensor key]]];
            
            
            // Update menu item title
            
            NSString * str = [[sensor caption] stringByPaddingToLength:28 withString:@" " startingAtIndex:0];
            
            if(![[(NSMenuItem *)[sensor object] title] isEqualToString:str])
              [(NSMenuItem *)[sensor object] setTitle:[NSString stringWithFormat:@"%@%@",str,value ]] ;
          }
          
          if ([sensor favorite]) {
            NSString * value =[sensor formatedValue:[values objectForKey:[sensor key]] ? [values objectForKey:[sensor key]] : [HWMonitorSensor readValueForKey:[sensor key]]];
            
            
            [statusString appendString:@" "];
            [statusString appendString:value];
            
            count++;
          }
        }
      }
    
if (service) {
    CFRelease(message);
    IOObjectRelease(service);
	}
    if (count > 0) {
      // Update status bar title
      NSMutableAttributedString * title = [[NSMutableAttributedString alloc] initWithString:statusString attributes:statusItemAttributes];
      [title addAttribute:NSFontAttributeName value:statusItemFont range:NSMakeRange(0, [title length])];
      [statusItem setAttributedTitle:title];
      
    }
  
}

- (HWMonitorSensor *)addSensorWithKey:(NSString *)key andType:(NSString *) aType andCaption:(NSString *)caption intoGroup:(SensorGroup)group 
{
    if(group==HDSmartTempSensorGroup || [HWMonitorSensor readValueForKey:key] || group==BatterySensorsGroup)
    {
        caption = [caption stringByTruncatingToWidth:180.0f withFont:statusMenuFont];
        HWMonitorSensor * sensor = [[HWMonitorSensor alloc] initWithKey:key andType: aType andGroup:group withCaption:caption];
        
        [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:key]];
        
        NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:caption action:nil keyEquivalent:@""];
        
        [menuItem setRepresentedObject:sensor];
        [menuItem setAction:@selector(menuItemClicked:)];
        
        if ([sensor favorite]) [menuItem setState:TRUE];
        
        [statusMenu insertItem:menuItem atIndex:menusCount++];
        
        [sensor setObject:menuItem];
        
        [sensorsList addObject:sensor];
        
        return sensor;

    }
      return NULL;
}

- (void)insertFooterAndTitle:(NSString *)title andImage:(NSImage *)img
{
    if (lastMenusCount < menusCount) {
        NSMenuItem * titleItem = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
        if(img)
            [titleItem setImage:img];
        [titleItem setEnabled:FALSE];
        //[titleItem setIndentationLevel:1];
        
        [statusMenu insertItem:titleItem atIndex:lastMenusCount]; menusCount++;       
        [statusMenu insertItem:[NSMenuItem separatorItem] atIndex:menusCount++];
        
        lastMenusCount = menusCount;
    }
}

// Events

- (void)menuWillOpen:(NSMenu *)menu {
    isMenuVisible = YES;
    
    [self updateTitles];
}

- (void)menuDidClose:(NSMenu *)menu {
    isMenuVisible = NO;
}

- (void)menuItemClicked:(id)sender {
    NSMenuItem * menuItem = (NSMenuItem *)sender;
    
    [menuItem setState:![menuItem state]];
    
    HWMonitorSensor * sensor = (HWMonitorSensor *)[menuItem representedObject];
    
    [sensor setFavorite:[menuItem state]];
    
    [self updateTitles];
    
    [[NSUserDefaults standardUserDefaults] setBool:[menuItem state] forKey:[sensor key]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                [self methodSignatureForSelector:@selector(updateTitles)]];
    [invocation setTarget:self];
    [invocation setSelector:@selector(updateTitles)];
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:3 invocation:invocation repeats:YES] forMode:NSRunLoopCommonModes];
    
    [self updateTitles];
}

- (void)awakeFromNib
{
  menusCount = 0;
  lastcall = [NSDate date];
  smartController = [[ISPSmartController alloc] init];
	if (smartController) {
    smart = YES;
    [smartController getPartitions];
    [smartController update];
    DisksList = [smartController getDataSet:1];
  }
	
  BatteriesList = [IOBatteryStatus getAllBatteriesLevel];
  
  statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  [statusItem setMenu:statusMenu];
  [statusItem setHighlightMode:YES];
  [statusItem setImage:[NSImage imageNamed:@"temperature_small"]];
  [statusItem setAlternateImage:[NSImage imageNamed:@"temperature_small"]];
  
  statusItemFont = [NSFont fontWithName:@"Lucida Grande Bold" size:9.0];
  
  NSMutableParagraphStyle * style = [[NSMutableParagraphStyle alloc] init];
  [style setLineSpacing:0];
  
  statusItemAttributes = [NSDictionary dictionaryWithObject:style forKey:NSParagraphStyleAttributeName];
  
  statusMenuFont = [NSFont fontWithName:@"Menlo" size:11];
  [statusMenu setFont:statusMenuFont];
  
  style = [[NSMutableParagraphStyle alloc] init];
  [style setTabStops:[NSArray array]];
  [style addTabStop:[[NSTextTab alloc] initWithType:NSRightTabStopType location:190.0]];
  //[style setDefaultTabInterval:390.0];
  statusMenuAttributes = [NSDictionary dictionaryWithObject:style forKey:NSParagraphStyleAttributeName];
  
  // Init sensors
  sensorsList = [[NSMutableArray alloc] init];
  lastMenusCount = menusCount;
  //Temperatures
  NSString* type;
    
  for (int i=0; i<0xA; i++)
  {
	[self addSensorWithKey:[NSString stringWithFormat:@"TC%XD",i] andType: ((type = [HWMonitorSensor getTypeOfKey:[NSString stringWithFormat:@"TC%XD",i]]) ? type : @TYPE_SP78) andCaption:[[NSString alloc] initWithFormat:@"CPU %X Diode",i] intoGroup:TemperatureSensorGroup ];
    [self addSensorWithKey:[NSString stringWithFormat:@"TC%XH",i] andType: ((type = [HWMonitorSensor getTypeOfKey:[NSString stringWithFormat:@"TC%XH",i]]) ? type : @TYPE_SP78) andCaption:[[NSString alloc] initWithFormat:@"CPU %X Core",i] intoGroup:TemperatureSensorGroup ];
  }
  [self addSensorWithKey:@"TC0P" andType: ((type = [HWMonitorSensor getTypeOfKey:@"TC0P"]) ? type : @TYPE_SP78) andCaption:NSLocalizedString( @"CPU Proximity", nil) intoGroup:TemperatureSensorGroup ];
  [self addSensorWithKey:@"Th0H" andType: ((type = [HWMonitorSensor getTypeOfKey:@"Th0H"]) ? type : @TYPE_SP78) andCaption:NSLocalizedString( @"CPU Heatsink", nil) intoGroup:TemperatureSensorGroup ];
  [self addSensorWithKey:@"TN0P" andType: ((type = [HWMonitorSensor getTypeOfKey:@"TN0P"]) ? type : @TYPE_SP78) andCaption:NSLocalizedString(@"Motherboard",nil) intoGroup:TemperatureSensorGroup ];
  [self addSensorWithKey:@"Tm0P" andType: ((type = [HWMonitorSensor getTypeOfKey:@"Tm0P"]) ? type : @TYPE_SP78) andCaption:NSLocalizedString(@"Memory",nil) intoGroup:TemperatureSensorGroup ];
  [self addSensorWithKey:@"TA0P" andType: ((type = [HWMonitorSensor getTypeOfKey:@"TA0P"]) ? type : @TYPE_SP78) andCaption:NSLocalizedString(@"Ambient",nil) intoGroup:TemperatureSensorGroup ];
  
  for (int i=0; i<0xA; i++) {
    [self addSensorWithKey:[NSString stringWithFormat:@"TG%XD",i] andType: ((type = [HWMonitorSensor getTypeOfKey:[NSString stringWithFormat:@"TG%XD",i]]) ? type : @TYPE_SP78) andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %X Core",nil) ,i] intoGroup:TemperatureSensorGroup ];
    [self addSensorWithKey:[NSString stringWithFormat:@"TG%XH",i] andType: ((type = [HWMonitorSensor getTypeOfKey:[NSString stringWithFormat:@"TG%XH",i]]) ? type : @TYPE_SP78) andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %X Board",nil),i] intoGroup:TemperatureSensorGroup ];
    [self addSensorWithKey:[NSString stringWithFormat:@"TG%XP",i] andType: ((type = [HWMonitorSensor getTypeOfKey:[NSString stringWithFormat:@"TG%XP",i]]) ? type : @TYPE_SP78) andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %X Proximity",nil),i] intoGroup:TemperatureSensorGroup ];
  }
  
  [self insertFooterAndTitle:NSLocalizedString( @"TEMPERATURES",nil) andImage:[NSImage imageNamed:@"temp_alt_small"]];  
  
  for (int i=0; i<16; i++)
    [self addSensorWithKey:[[NSString alloc] initWithFormat:@"FRC%X",i] andType: @TYPE_FREQ andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"CPU %X",nil),i] intoGroup:FrequencySensorGroup ]; // no need to detect type, because we write these keys
  
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
  
  [self addSensorWithKey:@KEY_CPU_VOLTAGE andType: ((type = [HWMonitorSensor getTypeOfKey:@KEY_CPU_VOLTAGE]) ? type : @TYPE_FP2E) andCaption:NSLocalizedString(@"CPU Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_CPU_VRM_SUPPLY0 andType: ((type = [HWMonitorSensor getTypeOfKey:@KEY_CPU_VRM_SUPPLY0]) ? type : @TYPE_FP2E) andCaption:NSLocalizedString(@"CPU VRM Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_MEMORY_VOLTAGE andType: ((type = [HWMonitorSensor getTypeOfKey:@KEY_MEMORY_VOLTAGE]) ? type : @TYPE_FP2E) andCaption:NSLocalizedString(@"DIMM Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_12V_VOLTAGE andType: ((type = [HWMonitorSensor getTypeOfKey:@KEY_12V_VOLTAGE]) ? type : @TYPE_SP4B) andCaption:NSLocalizedString(@"+12V Bus Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_5VC_VOLTAGE andType: ((type = [HWMonitorSensor getTypeOfKey:@KEY_5VC_VOLTAGE]) ? type : @TYPE_SP4B) andCaption:NSLocalizedString(@"+5V Bus Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_N12VC_VOLTAGE andType: ((type = [HWMonitorSensor getTypeOfKey:@KEY_N12VC_VOLTAGE]) ? type : @TYPE_SP4B) andCaption:NSLocalizedString(@"-12V Bus Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_5VSB_VOLTAGE andType: ((type = [HWMonitorSensor getTypeOfKey:@KEY_5VSB_VOLTAGE]) ? type : @TYPE_SP4B) andCaption:NSLocalizedString(@"-5V Bus Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_3VCC_VOLTAGE andType: ((type = [HWMonitorSensor getTypeOfKey:@KEY_3VCC_VOLTAGE]) ? type : @TYPE_FP2E) andCaption:NSLocalizedString(@"3.3 VCC Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_3VSB_VOLTAGE andType: ((type = [HWMonitorSensor getTypeOfKey:@KEY_3VSB_VOLTAGE]) ? type : @TYPE_FP2E) andCaption:NSLocalizedString(@"3.3 VSB Voltage",nil) intoGroup:VoltageSensorGroup ];
  [self addSensorWithKey:@KEY_VBAT_VOLTAGE andType: ((type = [HWMonitorSensor getTypeOfKey:@KEY_VBAT_VOLTAGE]) ? type : @TYPE_FP2E) andCaption:NSLocalizedString(@"Battery Voltage",nil) intoGroup:VoltageSensorGroup ];
  for (int i=0; i<0xA; i++) {
    [self addSensorWithKey:[NSString stringWithFormat:@KEY_FORMAT_GPU_VOLTAGE,i] andType: ((type = [HWMonitorSensor getTypeOfKey:[NSString stringWithFormat:@KEY_FORMAT_GPU_VOLTAGE,i]]) ? type : @TYPE_FP2E) andCaption:[[NSString alloc] initWithFormat:NSLocalizedString(@"GPU %X Voltage",nil) ,i] intoGroup:VoltageSensorGroup ];
  }
  
  [self insertFooterAndTitle:NSLocalizedString(@"VOLTAGES",nil) andImage:[NSImage imageNamed:@"voltage_small"]];
  
  // Fans
  
  for (int i=0; i<10; i++)   {
    FanTypeDescStruct * fds;
    NSData * keydata = [HWMonitorSensor readValueForKey:[[NSString alloc] initWithFormat:@"F%XID",i]];
    NSString * caption;
    if(keydata) {
      fds = (FanTypeDescStruct*)[keydata bytes];
      caption = [[[NSString alloc] initWithBytes:  fds->strFunction length: DIAG_FUNCTION_STR_LEN encoding: NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[[NSCharacterSet letterCharacterSet] invertedSet]];
    } else {
      caption = @"";
    }
    if([caption length]<=0) {
      caption = [[NSString alloc] initWithFormat:@"Fan %d",i];
    }
    [self addSensorWithKey:[NSString stringWithFormat:@"F%XAc",i] andType: ((type = [HWMonitorSensor getTypeOfKey:[NSString stringWithFormat:@"F%XAc",i]]) ? type : @TYPE_FPE2) andCaption:caption intoGroup:TachometerSensorGroup ];
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
    NSMenuItem * item = [[NSMenuItem alloc] initWithTitle:@"No sensors found or FakeSMCDevice unavailable" action:nil keyEquivalent:@""];
    
    [item setEnabled:FALSE];
    
    [statusMenu insertItem:item atIndex:0];
  }
}

@end
