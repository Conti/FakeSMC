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
    [model addFan:[model testPrepareFan]];
    [model calibrateFan:0];
    
}

@end
