//
//  HWMonitorExtra.m
//  HWSensors
//
//  Created by mozo on 03/02/12.
//  Copyright (c) 2012 mozodojo. All rights reserved.
//

#import "HWMonitorExtra.h"
#import "HWMonitorView.h"

#include "FakeSMCDefinitions.h"

@implementation HWMonitorExtra

- (void)updateTitles:(BOOL)force
{
    io_service_t service = IOServiceGetMatchingService(0, IOServiceMatching(kFakeSMCDeviceService));
    
    if (service) {
        
        NSEnumerator * enumerator = nil;
        HWMonitorSensor * sensor = nil;
        
        CFMutableArrayRef list = (CFMutableArrayRef)CFArrayCreateMutable(kCFAllocatorDefault, 0, nil);
        
        enumerator = [sensorsList  objectEnumerator];
        
        while (sensor = (HWMonitorSensor *)[enumerator nextObject]) {
            if (force || [self isMenuDown] || [sensor favorite]) {
                CFTypeRef name = (CFTypeRef) CFStringCreateWithCString(kCFAllocatorDefault, [[sensor key] cStringUsingEncoding:NSASCIIStringEncoding], kCFStringEncodingASCII);
                
                CFArrayAppendValue(list, name);
            }
        }
        
        if (kIOReturnSuccess == IORegistryEntrySetCFProperty(service, CFSTR(kFakeSMCDevicePopulateList), list)) 
        {           
            NSDictionary * values = (__bridge_transfer NSDictionary *)IORegistryEntryCreateCFProperty(service, CFSTR(kFakeSMCDeviceValues), kCFAllocatorDefault, 0);
            
            if (values) {
                
                NSMutableArray * favorites = [[NSMutableArray alloc] init];
                
                enumerator = [sensorsList  objectEnumerator];
                
                while (sensor = (HWMonitorSensor *)[enumerator nextObject]) {
                    if (force || [self isMenuDown] || [sensor favorite]) {
                        
                        NSString * value = /*[self isMenuDown] ?*/ [[NSString alloc] initWithString:[sensor readValue]] /*: [[NSString alloc] initWithString:[sensor populateValue]]*/;
                        
                        if (force || [self isMenuDown]) {
                            NSMutableAttributedString * title = [[NSMutableAttributedString alloc] initWithString:[[NSString alloc] initWithFormat:@"%S\t%S",[[sensor caption] cStringUsingEncoding:NSUTF16StringEncoding],[value cStringUsingEncoding:NSUTF16StringEncoding]] attributes:statusMenuAttributes];
                            
                            [title addAttribute:NSFontAttributeName value:statusMenuFont range:NSMakeRange(0, [title length])];

                            // Update menu item title
                            [(NSMenuItem *)[sensor object] setAttributedTitle:title];
                        }
                        
                        if ([sensor favorite])
                            [favorites addObject:[[NSString alloc] initWithFormat:@"%S", [value cStringUsingEncoding:NSUTF16StringEncoding]]];
                    }
                }
        
                if ([favorites count] > 0)
                    [view setTitles:favorites];
                else 
                    [view setTitles:nil];
                
                [view setNeedsDisplay:YES];
            }
        }
        
        CFArrayRemoveAllValues(list);
        CFRelease(list);
        
        IOObjectRelease(service);
    }
}

- (void)updateTitlesForced
{
    [self updateTitles:YES];
}

- (void)updateTitlesDefault
{
    [self updateTitles:NO];
}

- (HWMonitorSensor *)addSensorWithKey:(NSString *)key andCaption:(NSString *)caption intoGroup:(SensorGroup)group
{
    if ([HWMonitorSensor populateValueForKey:key]) {
        HWMonitorSensor * sensor = [[HWMonitorSensor alloc] initWithKey:key andGroup:group withCaption:caption];
        
        [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:key]];
        
        NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:caption action:@selector(menuItemClicked:) keyEquivalent:@""];
        
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:sensor];
        
        if ([sensor favorite]) [menuItem setState:TRUE];
        
        [menu insertItem:menuItem atIndex:menusCount++];
        
        [sensor setObject:menuItem];
        
        [sensorsList addObject:sensor];
        
        return sensor;
    }
    
    return NULL;
}

- (void)insertFooterAndTitle:(NSString *)title
{
    if (lastMenusCount < menusCount) {
        NSMutableAttributedString * atributedTitle = [[NSMutableAttributedString alloc] initWithString:title attributes:statusMenuAttributes];
        
        [atributedTitle addAttribute:NSFontAttributeName value:statusMenuFont range:NSMakeRange(0, [title length])];
               
        NSMenuItem * titleItem = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
        
        [titleItem setEnabled:FALSE];
        [titleItem setAttributedTitle:atributedTitle];
        
        [menu insertItem:titleItem atIndex:lastMenusCount]; 
        menusCount++;
        
        if (lastMenusCount > 0) {
            [menu insertItem:[NSMenuItem separatorItem] atIndex:lastMenusCount];
            menusCount++;
        }
        
        lastMenusCount = menusCount;
    }
}

- (void)menuItemClicked:(id)sender {
    NSMenuItem * menuItem = (NSMenuItem *)sender;
    
    [menuItem setState:![menuItem state]];
    
    HWMonitorSensor * sensor = (HWMonitorSensor *)[menuItem representedObject];
    
    [sensor setFavorite:[menuItem state]];
    
    [self updateTitlesDefault];
    
    [[NSUserDefaults standardUserDefaults] setBool:[menuItem state] forKey:[sensor key]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)initWithBundle:(NSBundle *)bundle
{
    self = [super initWithBundle:bundle];
    
    if (self == nil) return nil;
    
    view = [[HWMonitorView alloc] initWithFrame: [[self view] frame] menuExtra:self];
    
    [self setView:view];
    
    // Set status bar icon
    [view setImage:[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForResource:@"thermo" ofType:@"png"]]];
    [view setAlternateImage:[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForResource:@"thermotemplate" ofType:@"png"]]];
    [view setFrameSize:NSMakeSize(80, [view frame].size.height)];
    
    statusBarFont = [NSFont fontWithName:@"Lucida Grande Bold" size:9.0f];
    
    menu = [[NSMenu alloc] init];
    
    [menu setAutoenablesItems: NO];
    //[menu setDelegate:(id<NSMenuDelegate>)self];
    
    NSMutableParagraphStyle * style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:0];
    
    statusMenuFont = [NSFont fontWithName:@"Lucida Grande Bold" size:10.0f];
    [menu setFont:statusMenuFont];
    
    style = [[NSMutableParagraphStyle alloc] init];
    [style setTabStops:[NSArray array]];
    [style addTabStop:[[NSTextTab alloc] initWithType:NSRightTabStopType location:190.0]];
    //[style setDefaultTabInterval:390.0];
    statusMenuAttributes = [NSDictionary dictionaryWithObject:style forKey:NSParagraphStyleAttributeName];
    
    // Init sensors
    sensorsList = [[NSMutableArray alloc] init];
    lastMenusCount = menusCount;
    
    //Temperatures
    
    for (int i=0; i<0xA; i++)
        [self addSensorWithKey:[[NSString alloc] initWithFormat:@"TC%XD",i] andCaption:[[NSString alloc] initWithFormat:@"CPU %X",i] intoGroup:TemperatureSensorGroup];
    
    [self addSensorWithKey:@"Th0H" andCaption:[bundle localizedStringForKey:@"CPU Heatsink" value:nil table:nil] intoGroup:TemperatureSensorGroup];
    [self addSensorWithKey:@"TN0P" andCaption:@"Motherboard" intoGroup:TemperatureSensorGroup];
    [self addSensorWithKey:@"TA0P" andCaption:@"Ambient" intoGroup:TemperatureSensorGroup];
    
    for (int i=0; i<0xA; i++) {
        [self addSensorWithKey:[[NSString alloc] initWithFormat:@"TG%XD",i] andCaption:[[NSString alloc] initWithFormat:@"GPU %X Core",i] intoGroup:TemperatureSensorGroup];
        [self addSensorWithKey:[[NSString alloc] initWithFormat:@"TG%XH",i] andCaption:[[NSString alloc] initWithFormat:@"GPU %X Board",i] intoGroup:TemperatureSensorGroup];
        [self addSensorWithKey:[[NSString alloc] initWithFormat:@"TG%XP",i] andCaption:[[NSString alloc] initWithFormat:@"GPU %X Proximity",i] intoGroup:TemperatureSensorGroup];
    }
    
    [self insertFooterAndTitle:@"TEMPERATURES"];  
    
    //Multipliers
    
    for (int i=0; i<0xA; i++)
        [self addSensorWithKey:[[NSString alloc] initWithFormat:@"MC%XC",i] andCaption:[[NSString alloc] initWithFormat:@"CPU %X Multiplier",i] intoGroup:MultiplierSensorGroup];
    
    [self addSensorWithKey:@"MPkC" andCaption:@"CPU Package Multiplier" intoGroup:MultiplierSensorGroup];
    
    [self insertFooterAndTitle:@"MULTIPLIERS"];
    
    // Voltages
    
    [self addSensorWithKey:@"VC0C" andCaption:@"CPU Voltage" intoGroup:VoltageSensorGroup];
    [self addSensorWithKey:@"VM0R" andCaption:@"DIMM Voltage" intoGroup:VoltageSensorGroup];
    
    [self insertFooterAndTitle:@"VOLTAGES"];
    
    // Fans
    
    for (int i=0; i<10; i++)
        [self addSensorWithKey:[[NSString alloc] initWithFormat:@"F%XAc",i] andCaption:[[NSString alloc] initWithFormat:@"Fan %X",i] intoGroup:TachometerSensorGroup];
    
    [self insertFooterAndTitle:@"FANS"];
    
    if ([sensorsList count] == 0) {
        NSMenuItem * item = [[NSMenuItem alloc]initWithTitle:@"No sensors found or FakeSMCDevice unavailable" action:nil keyEquivalent:@""];
        
        [item setEnabled:FALSE];
        
        [menu insertItem:item atIndex:0];
    }
    else {        
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                    [self methodSignatureForSelector:@selector(updateTitlesDefault)]];
        [invocation setTarget:self];
        [invocation setSelector:@selector(updateTitlesDefault)];
        [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:2.5f invocation:invocation repeats:YES] forMode:NSRunLoopCommonModes];
        
        [self performSelector:@selector(updateTitlesForced) withObject:nil afterDelay:0.0];
    }
    
    return self;
}

- (NSMenu *)menu
{
    return menu;
}

@end
