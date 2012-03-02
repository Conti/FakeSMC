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
@synthesize CurrentFan;






-(NSDictionary *) initialPrepareFan:(NSUInteger) fanId 
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

-(BOOL) writeFanDictionatyToFile: (NSString *) filename
{
    return [fans writeToFile:filename atomically:YES];
}

-(BOOL) readFanDictionatyFromFile: (NSString *) filename
{
    if((fans = [NSDictionary dictionaryWithContentsOfFile:filename])) return true;
    return false;
}

-(BOOL) calibrateFan:(NSString *) fanId
{
    sgFan * fan;
    DebugLog(@"Starting calibration for %@",fanId);
    if ((fan = [fans valueForKey:fanId])) {
        if ([fan Controlable] == NO) return NO;
        
        NSMutableArray * calibrationDataUp = [NSMutableArray arrayWithCapacity:0];
        NSMutableArray * calibrationDataDown = [NSMutableArray arrayWithCapacity:0];
        
        BOOL wasAutomatic=fan.automatic;
        uint8 tempSensorSave = fan.tempSensorSource;

        int i = 0;
        fan.automatic=NO;
        fan.manualPWM = 0;
         
        [NSThread sleepForTimeInterval:SpinTime];  // Give a time to stop rotation
        
        // Upward disrection
        for( i=0;i<128;i++)
        {
            fan.manualPWM = i;
            [NSThread sleepForTimeInterval:SpinTransactionTime]; //  Give some time for fan to reach the stable rotation
            NSNumber * num = [NSNumber numberWithInt: fan.currentRPM];
            [calibrationDataUp addObject:num];
            DebugLog(@"RPMs for FAN %@ at PWM = %d  is %d", [fan name] , i, [num intValue]) ;
        }
        //Downward direction
        for( i=127;i>=0;i--)
        {
            
            fan.manualPWM = i;
            [NSThread sleepForTimeInterval:SpinTransactionTime]; //  Give some time for fan to reach the stable rotation
            NSNumber * num = [NSNumber numberWithInt:fan.currentRPM];
            [calibrationDataDown insertObject:num atIndex: 0];
            DebugLog(@"RPMs for FAN %@ at PWM = %d  is %d", [fan name] , i, [num intValue]) ;
        }
        
        fan.automatic = wasAutomatic;
        fan.tempSensorSource = tempSensorSave;
        fan.Calibrated = YES;
        fan.calibrationDataUpward = calibrationDataUp;
        fan.calibrationDataDownward = calibrationDataDown;
        [self writeFanDictionatyToFile:@"/Users/ivan/Development/Fans.plist"];
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



-(void) findControllers
{
    NSMutableArray * cur, * prev, * names;
    
    cur = [NSMutableArray arrayWithCapacity:0];
    prev = [NSMutableArray arrayWithCapacity:0];
    names = [NSMutableArray arrayWithCapacity:0];
    
    int i=0,temp=0;
    
    for (i=0; i<[sgFan numberOfFans]; i++) {
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
        [sgFan writeValueForKey:[NSString stringWithFormat:@KEY_FORMAT_FAN_TARGET_SPEED,i]  data:originalPWM];
        NSInteger index = [sgModel whoDiffersFor:cur andPrevious:prev andMaxDev:MAXRPM_TO_DIFFER];
        if ( index != NSNotFound) {
            [[fans objectForKey:[names objectAtIndex:index]] updateKey:KEY_FAN_CONTROL withValue:[NSString stringWithFormat:@KEY_FORMAT_FAN_TARGET_SPEED,i] ];
            [[fans objectForKey:[names objectAtIndex:index]] updateKey:KEY_START_TEMP_CONTROL withValue:[NSString stringWithFormat:@KEY_FORMAT_FAN_START_TEMP,i] ];
            [[fans objectForKey:[names objectAtIndex:index]] updateKey:KEY_STOP_TEMP_CONTROL withValue:[NSString stringWithFormat:@KEY_FORMAT_FAN_OFF_TEMP,i] ];
            [[fans objectForKey:[names objectAtIndex:index]] updateKey:KEY_FULL_TEMP_CONTROL withValue:[NSString stringWithFormat:@KEY_FORMAT_FAN_FULL_TEMP,i] ];
            
            [[fans objectForKey:[names objectAtIndex:index]] setControlable:YES];
        }
        [cur removeAllObjects];
        [prev removeAllObjects];
        [names removeAllObjects];
    }
    
}

-(BOOL) selectCurrentFan:(NSString *)name
{
    CurrentFan = [fans valueForKey:name];
    if(CurrentFan) return YES;
    return NO;
}

@end
