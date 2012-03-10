//
//  sgAppController.m
//  HWSensors
//
//  Created by Navi on 24.02.12.
//  Copyright (c) 2012 Navi. All rights reserved.
//

#import "sgAppController.h"




@implementation sgAppController

@synthesize model;
@synthesize ControlTabView;
@synthesize mainWindow;

@synthesize StopTempInput;
@synthesize FullOnTempInput;
@synthesize calibrationYesButton;
@synthesize calibrationNoButton;
@synthesize calibrationWarning;
@synthesize calibrationQuestion;
@synthesize StartTempInput;

@synthesize tempSource;
@synthesize sgTableView;
@synthesize CalibrationGraphView;
@synthesize FanSettingGraphView;
@synthesize panelToShow;
@synthesize FansCalibrationView;
@synthesize needCalibration;


-(id) init
{
    self = [super init];
    if(self)
    {
        okStatus = NO;
        if([sgFan smartGuardianAvailable])
        NSLog(@"Found SmartGuardian");
        else
        [[NSApplication sharedApplication] terminate:self];
    }
    return  self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        needCalibration=NO;
        // Initialization code here.
        model = [[sgModel alloc]init];
        
        for (int i=0; i<[sgFan numberOfFans]; i++) {
            [model addFan:[model initialPrepareFan:i] withName:[NSString stringWithFormat:@"FAN%d",i]];
            
        }
        
        [[model fans] setObject:@KEY_FORMAT_FAN_MAIN_CONTROL forKey:@"FanMainControl"];
        [[model fans] setObject:@KEY_FORMAT_FAN_REG_CONTROL forKey:@"FanRegControl"];
        
        if([model readSettings]==NO) needCalibration=YES;
        okStatus = YES;
            
  

   
    }
    
    
    return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
 
    [self tableView: sgTableView selectionIndexesForProposedSelection:   [NSIndexSet indexSetWithIndex:0]];
    
   NSDictionary * dict = [sgFan tempSensorNameAndKeys];
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        for (int i=0; i<[tempSource segmentCount]; i++) {
            if([[tempSource labelForSegment:i] isEqual:obj])
            {
                [tempSource setEnabled:YES forSegment:i];
                [tempSource setTag:[key intValue] forSegment:i];
            }
                
        }
            
    }];

        [model selectCurrentFan:[NSString stringWithFormat:@"FAN0"]];
           [dictController bind:NSContentObjectBinding toObject:self withKeyPath:@"model.currentFan" options:nil];

    [FanSettingGraphView bind:@"PlotData" toObject:dictController withKeyPath:@"selection.lawGraphData" options:nil];
    [FanSettingGraphView bind:@"VerticalMarks" toObject:dictController withKeyPath:@"selection.tempMarks" options:nil];
    [CalibrationGraphView bind:@"PlotData" toObject:dictController withKeyPath:@"selection.CalibrationGraphData" options:nil];
    

          
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                [self methodSignatureForSelector:@selector(updateTitles)]];
    [invocation setTarget:self];
    [invocation setSelector:@selector(updateTitles)];
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:1 invocation:invocation repeats:YES] forMode:NSRunLoopCommonModes];
    
    FansOperationQueue = [[NSOperationQueue alloc] init];
    __block id me = self;

    [FansOperationQueue setMaxConcurrentOperationCount:4];
    if(needCalibration==YES)
    {
        [[me model] selectCurrentFan:@"FAN0"];
        [self showPanelModalAgainstWindow: mainWindow];

    }
    else
    okStatus=YES;
}


- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    NSUInteger i = [proposedSelectionIndexes lastIndex];;
    sgFan * fan = [[model fans] valueForKey:[NSString stringWithFormat:@"FAN%d",i]];
    [model selectCurrentFan:[NSString stringWithFormat:@"FAN%d",i]];

    
    if (fan.Calibrated && fan.Controlable) {
        [dictController bind:NSContentObjectBinding toObject:self withKeyPath:@"model.currentFan" options:nil];
        [fan setLawGraphData:nil];
        [fan setTempMarks:nil];
        [fan setCalibrationGraphData:nil];
    }

    
    return proposedSelectionIndexes;
}


-(void) FanInitialization
{
    FansCalibrationView.Hidden=NO;
    [model findControllers];

    
    NSEnumerator * enumerator = [[model fans] keyEnumerator];
    id  nextFan;
    __unsafe_unretained id me = self;
    while (nextFan = [enumerator nextObject]) 
        [FansOperationQueue addOperationWithBlock:^{
            if([nextFan hasPrefix:@"FAN"] && [[[[[me model]  fans ] objectForKey:nextFan ] valueForKey:KEY_CONTROLABLE] boolValue])
            {
                NSLog(@"Starting thread for %@",nextFan);
                [[[[me model]  fans ] objectForKey:nextFan ] calibrateFan]; 
            }
        }];
    
    
    
}

-(void) updateTitles
{

    [[model fans] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if([key hasPrefix:@"FAN"]){
            [obj setCurrentRPM:0];
            [obj setTempSensorValue:0];

        }
        
    } ];
    
    
    
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    __block NSUInteger i=0;
    [[model fans] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if([key hasPrefix:@"FAN"]) i++;
    } ];
    return i;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [[model fans] objectForKey:[NSString stringWithFormat:@"FAN%d",rowIndex]];
}

-(void) applicationWillTerminate:(NSNotification *)notification
{
    if(okStatus==YES)
        [model saveSettings];
}

- (id)showPanelModalAgainstWindow: (NSWindow *)window
{
    [[NSApplication sharedApplication] beginSheet: panelToShow
                                   modalForWindow: window
                                    modalDelegate: self
                                   didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
                                      contextInfo: nil];
    
    [[NSApplication sharedApplication] runModalForWindow: panelToShow];
    if (m_returnCode == NSCancelButton) return nil;
    return nil;
}


- (void)sheetDidEnd:(NSWindow *)sheet
         returnCode:(int)returnCode
        contextInfo:(void  *)contextInfo
{

    m_returnCode = returnCode;
}

- (IBAction)clickCalibrate:(id)sender {
    
    if([sender isEqual:calibrationNoButton])
    {
        okStatus=NO;
        [panelToShow orderOut:nil];
        [[NSApplication sharedApplication] stopModal];
        [[NSApplication sharedApplication] terminate:self];
        return;
    }
    
    calibrationNoButton.Hidden = YES;
    calibrationYesButton.Hidden = YES;
    calibrationWarning.Hidden = YES;
    calibrationQuestion.Hidden = YES;
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        [self FanInitialization];
        [FansOperationQueue waitUntilAllOperationsAreFinished];
        [panelToShow orderOut:nil];
        [[NSApplication sharedApplication] stopModal];
        [model saveSettings];


    } ];
    okStatus=YES;


}

- (BOOL)windowShouldClose:(id)sender
{
    [NSApp terminate:self];
    return YES;
}

@end
