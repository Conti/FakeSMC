//
//  sgAppController.h
//  HWSensors
//
//  Created by Navi on 24.02.12.
//  Copyright (c) 2012 Navi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GraphView.h"
#import "sgModel.h"

@interface sgAppController : NSViewController <NSTableViewDataSource,NSTableViewDelegate,NSApplicationDelegate> 
{
    IBOutlet NSObjectController	*dictController;
    NSOperationQueue * FansOperationQueue;

}

-(void) FanInitialization;


@property (readwrite)     bool needCalibration;
@property (strong) IBOutlet NSTextFieldCell *StartTempInput;
@property (strong) IBOutlet NSTextFieldCell *StopTempInput;
@property (strong) IBOutlet NSTextFieldCell *FullOnTempInput;

@property (retain) IBOutlet sgModel * model; 
@property (strong) IBOutlet NSTabView *ControlTabView;

@property (strong) IBOutlet NSTableView *sgTableView;
@property (strong) IBOutlet GraphView *CalibrationGraphView;
@property (strong) IBOutlet GraphView *FanSettingGraphView;
@end

