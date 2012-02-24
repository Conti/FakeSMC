//
//  sgAppDelegate.m
//  SmartGuardian
//
//  Created by Navi on 21.02.12.
//  Copyright (c) 2012 . All rights reserved.
//

#import "sgAppDelegate.h"
#import "sgModel.h"


@implementation sgAppDelegate

@synthesize window = _window;

- (void) applicationWillTerminate:(NSNotification *)notification
{
        [model writeFanDictionatyToFile:@"/Users/ivan/Development/Fans.plist"]; 
        
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    int i;
    NSData * dataptr;
    // Insert code here to initialize your application
    NSLog(@"Number of Fans = %d",[sgModel numberOfFans]);
    
    model = [[sgModel alloc] init];
    for(i=0;i<[sgModel numberOfFans];i++)
        [model addFan:[model initialPrepareFan:i] withName:[NSString stringWithFormat:@"FAN%d",i]];
    
    [model findControllers];

    NSOperationQueue * newq = [[NSOperationQueue alloc] init];
    [newq setMaxConcurrentOperationCount:4];
    
    NSLog(@"Number of concurrent operations = %d",[newq maxConcurrentOperationCount]);
    NSDictionary * fans = [model fans];
    NSEnumerator * enumerator = [fans keyEnumerator];
    NSString * nextFan;
    while (nextFan = [enumerator nextObject]) 
    [newq addOperationWithBlock:^{
        
        NSLog(@"Starting thread for %@",nextFan);
        [model calibrateFan: nextFan];
    }];
    

    
}

@end
