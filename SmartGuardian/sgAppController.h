//
//  sgAppController.h
//  HWSensors
//
//  Created by Иван Синицин on 24.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "sgModel.h"

@interface sgAppController : NSViewController <NSTableViewDataSource,NSApplicationDelegate>{
    NSOperationQueue * FansOperationQueue;
}

-(void) FanInitialization;


@property (strong) IBOutlet NSPanel *mainWindow;
@property (retain) IBOutlet sgModel * model; 
@property (strong) IBOutlet NSTableView *sgTableView;
@end
