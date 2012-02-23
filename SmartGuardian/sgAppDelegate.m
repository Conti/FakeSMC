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
    
    sgModel * model = [[sgModel alloc] init];
    [model addFan:[model testPrepareFan] withName: @"FAN0" ];
    [model addFan:[model testPrepareFan2] withName: @"FAN1" ];
    NSOperationQueue * newq = [[NSOperationQueue alloc] init];
    [newq setMaxConcurrentOperationCount:4];
    
    NSLog(@"Number of concurrent operations = %d",[newq maxConcurrentOperationCount]);
    for(int i=0; i<2;i++)
    [newq addOperationWithBlock:^{
        NSString * str = [NSString stringWithFormat:@"FAN%d",i ];
        NSLog(@"Starting thread for %@",str);
        [model calibrateFan: str];
    }];
    
}

@end
