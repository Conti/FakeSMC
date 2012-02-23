//
//  sgAppDelegate.m
//  SmartGuardian
//
//  Created by Navi on 21.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "sgAppDelegate.h"
#import "sgModel.h"


@implementation sgAppDelegate

@synthesize window = _window;




- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSData * dataptr;
    // Insert code here to initialize your application
    NSLog(@"Number of Fans = %d",[sgModel numberOfFans]);
    
    dataptr = [sgModel readValueForKey:@"F0Ac"];
    UInt16 value = *((UInt16 *)[dataptr bytes]);
    NSLog(@"RPMs for Fan 0 %d",[sgModel decode_fpe2:value]);
    
    dataptr = [sgModel readValueForKey:@"F2Tg"];
    
    
    
    UInt32 newval = 127;
    NSData * newsave = [NSData dataWithBytes:&newval length:1];
    [sgModel writeValueForKey:@"F2Tg" data: newsave];
    [sgModel writeValueForKey:@"F1Tg" data: newsave];


}

@end
