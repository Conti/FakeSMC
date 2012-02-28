//
//  sgAppController.h
//  HWSensors
//
//  Created by Navi on 24.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GraphView.h"
#import "sgModel.h"

@interface sgAppController : NSViewController <NSTableViewDataSource,NSTableViewDelegate,NSApplicationDelegate>{
    NSOperationQueue * FansOperationQueue;
}

-(void) FanInitialization;
-(void) FanSelected;

@property (assign,readwrite) NSDictionary * currentFan;

@property (strong) IBOutlet NSPanel *mainWindow;
@property (retain) IBOutlet sgModel * model; 
@property (strong) IBOutlet NSTableView *sgTableView;
@property (strong) IBOutlet GraphView *CalibrationGraphView;
@end
