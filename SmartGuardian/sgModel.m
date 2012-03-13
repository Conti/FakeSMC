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
#define MAX_FAN_TO_SEARCH 5 

@implementation sgModel

@synthesize fans;


-(void) setCurrentFan:(sgFan *)CurrentFan
{
    _currentFan = CurrentFan;
}

-(sgFan *) currentFan
{
    return _currentFan;
}

-(sgFan *) initialPrepareFan:(NSUInteger) fanId 
{
    if (fanId < [sgFan numberOfFans]) {
        
        return  [[sgFan alloc] initWithFanId: fanId];
        
    }
    return nil;
}

-(sgModel *) init
{
    fans = [NSMutableDictionary dictionaryWithCapacity:0];
    return self;
}

-(BOOL) addFan: (sgFan *) desc withName:(NSString *) name
{
    [fans setValue:desc forKey: name];
    return YES;
}

-(void) saveSettings
{
    NSMutableDictionary * toSave = [NSMutableDictionary dictionaryWithCapacity:0];
    [fans enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if([key hasPrefix:@"FAN"])
        {
            NSDictionary * temp = [obj valuesForSaveOperation];
            [toSave setObject:temp forKey:key];
            
        }   
        else
            [toSave setObject:obj forKey:key];

    }];
    [[NSUserDefaults standardUserDefaults] setObject:toSave forKey:@"Configuration"];
}

-(BOOL) readSettings
{
    NSMutableDictionary * temp = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Configuration"] ];
    
    __block BOOL result = NO;
    if(temp)
    {
        [temp enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            
            if([key hasPrefix:@"FAN"])
            {
                obj = [[sgFan alloc] initWithKeys:obj];
                result = YES;
            }
            
            [fans setObject:obj forKey:key];
            
        }];
        
    }
    return result;
}

-(BOOL) calibrateFan:(NSString *) fanId
{
    sgFan * fan;
    DebugLog(@"Starting calibration for %@",fanId);
    if ((fan = [fans valueForKey:fanId])) {
        if ([fan Controlable] == NO) return NO;
         return [fan calibrateFan];
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



-(void) findControllers
{
    NSMutableArray * cur, * prev, * names;
    
    cur = [NSMutableArray arrayWithCapacity:0];
    prev = [NSMutableArray arrayWithCapacity:0];
    names = [NSMutableArray arrayWithCapacity:0];
    
    [fans enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if([key hasPrefix:@"FAN"])
        {
            [names addObject:key];
        }    
    }];
    int i=0,temp=0;
    
    for (i=0; i<MAX_FAN_TO_SEARCH; i++) {
        NSData * originalPWM = [sgFan readValueForKey:[NSString stringWithFormat:@KEY_FORMAT_FAN_TARGET_SPEED,i]];
        temp=0;
        [sgFan writeValueForKey:[NSString stringWithFormat:@KEY_FORMAT_FAN_TARGET_SPEED,i]  data:[NSData dataWithBytes:&temp length:1]];
        [NSThread sleepForTimeInterval:SpinTime];
        [fans enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if([key hasPrefix:@"FAN"])
            {
            [prev addObject:[NSNumber numberWithInteger:[obj currentRPM]]];
            [names addObject:key];
            }    
        }];
        temp=127;
        [sgFan writeValueForKey:[NSString stringWithFormat:@KEY_FORMAT_FAN_TARGET_SPEED,i]  data:[NSData dataWithBytes:&temp length:1]];
        [NSThread sleepForTimeInterval:SpinTime];
        [fans enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if([key hasPrefix:@"FAN"])
              [cur addObject:[NSNumber numberWithInteger:[obj currentRPM]]];
        }];
        if(originalPWM)
        [sgFan writeValueForKey:[NSString stringWithFormat:@KEY_FORMAT_FAN_TARGET_SPEED,i]  data:originalPWM];
        NSInteger index = [sgModel whoDiffersFor:cur andPrevious:prev andMaxDev:MAXRPM_TO_DIFFER];
        if ( index != NSNotFound) {
            [[fans objectForKey:[names objectAtIndex:index]] updateKey:KEY_FAN_CONTROL withValue:[NSString stringWithFormat:@KEY_FORMAT_FAN_TARGET_SPEED,i] ];
            [[fans objectForKey:[names objectAtIndex:index]] updateKey:KEY_START_TEMP_CONTROL withValue:[NSString stringWithFormat:@KEY_FORMAT_FAN_START_TEMP,i] ];
            [[fans objectForKey:[names objectAtIndex:index]] updateKey:KEY_STOP_TEMP_CONTROL withValue:[NSString stringWithFormat:@KEY_FORMAT_FAN_OFF_TEMP,i] ];
            [[fans objectForKey:[names objectAtIndex:index]] updateKey:KEY_FULL_TEMP_CONTROL withValue:[NSString stringWithFormat:@KEY_FORMAT_FAN_FULL_TEMP,i] ];
            [[fans objectForKey:[names objectAtIndex:index]] updateKey:KEY_START_PWM_CONTROL withValue:[NSString stringWithFormat:@KEY_FORMAT_FAN_START_PWM,i] ];
            [[fans objectForKey:[names objectAtIndex:index]] updateKey:KEY_DELTA_TEMP_CONTROL withValue:[NSString stringWithFormat:@KEY_FORMAT_FAN_TEMP_DELTA,i] ];
            [[fans objectForKey:[names objectAtIndex:index]] updateKey:KEY_DELTA_PWM_CONTROL withValue:[NSString stringWithFormat:@KEY_FORMAT_FAN_CONTROL,i] ];
            [[fans objectForKey:[names objectAtIndex:index]] setControlable:YES];
        }
        [cur removeAllObjects];
        [prev removeAllObjects];
    }
    
}

-(BOOL) selectCurrentFan:(NSString *)name
{
    self.currentFan = [fans valueForKey:name];
    
    if(self.currentFan) return YES;
    return NO;
}

@end
