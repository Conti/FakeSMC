//
//  sgAppDelegate.h
//  SmartGuardian
//
//  Created by Navi on 21.02.12.
//  Copyright (c) 2012 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "sgModel.h"
@interface sgAppDelegate : NSObject <NSApplicationDelegate>{

sgModel *  model;

}
@property (assign) IBOutlet NSWindow *window;

@end
