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
@synthesize StartTempInput;

@synthesize tempSource;
@synthesize sgTableView;
@synthesize CalibrationGraphView;
@synthesize FanSettingGraphView;
@synthesize panelToShow;
@synthesize needCalibration;


-(id) init
{
    self = [super init];
    if(self)
    {
        if([sgFan smartGuardianAvailable])
        NSLog(@"Found SmartGuardian");
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
    [self showPanelModalAgainstWindow: mainWindow];

          
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
                   [FansOperationQueue addOperationWithBlock:^{
                [me FanInitialization];
              

         }];
    }
    
    
}


- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    NSUInteger i = [proposedSelectionIndexes lastIndex];;
    sgFan * fan = [[model fans] valueForKey:[NSString stringWithFormat:@"FAN%d",i]];
    [model selectCurrentFan:[NSString stringWithFormat:@"FAN%d",i]];
    [dictController bind:NSContentObjectBinding toObject:self withKeyPath:@"model.currentFan" options:nil];
    if (fan.Calibrated && fan.Controlable) {
        
        NSArray * dataup = fan.calibrationDataUpward;
        NSArray * datadown = fan.calibrationDataDownward;
        NSMutableDictionary * allPlots = [NSMutableDictionary dictionaryWithCapacity:2];    
        NSMutableDictionary * plotdataUp = [NSMutableDictionary dictionaryWithCapacity:1];
        NSMutableDictionary * plotdataDown = [NSMutableDictionary dictionaryWithCapacity:1];
        //            NSMutableDictionary * middleLine = [NSMutableDictionary dictionaryWithCapacity:1];
        
        [plotdataUp setObject:[NSColor redColor] forKey:@"Color"];
        [plotdataUp setObject:dataup forKey:@"Data" ];
        [allPlots setObject:plotdataUp forKey:@"Upward"];
        
        [plotdataDown setObject:[NSColor blueColor] forKey:@"Color"];
        [plotdataDown setObject:datadown forKey:@"Data" ];
        [allPlots setObject:plotdataDown forKey:@"Downward"];
        
        //            [middleLine setObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:10],[NSNumber numberWithInt:10],nil ] forKey:@"Data"];
        //            [middleLine setObject:[NSColor yellowColor] forKey:@"Color"];
        //            [middleLine setObject:[NSNumber numberWithInt:20] forKey:@"Scale"];
        //            [allPlots setObject:middleLine forKey:@"Midlane"];
        [CalibrationGraphView setHidden:NO];
        [CalibrationGraphView setPlotData: allPlots ];
        [CalibrationGraphView setNeedsDisplay:YES];
    }
    else
    {
        NSMutableArray * plotdata = [NSMutableArray arrayWithCapacity:0];
        [CalibrationGraphView setHidden:YES];
        //            [CalibrationGraphView setPlotData: plotdata ];
        //            [CalibrationGraphView setNeedsDisplay:YES];   
    }
    
    return proposedSelectionIndexes;
}


-(void) FanInitialization
{
    
    [model findControllers];
    
    NSEnumerator * enumerator = [[model fans] keyEnumerator];
    NSString * nextFan;
    __unsafe_unretained id me = self;
    while (nextFan = [enumerator nextObject]) 
        [FansOperationQueue addOperationWithBlock:^{
            if([nextFan hasPrefix:@"FAN"] && [[[[[me model]  fans ] objectForKey:nextFan ] valueForKey:KEY_CONTROLABLE] boolValue])
            {
                NSLog(@"Starting thread for %@",nextFan);
                [[me model] calibrateFan: nextFan];
                [[me model] saveSettings];
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
}


- (void)sheetDidEnd:(NSWindow *)sheet
         returnCode:(int)returnCode
        contextInfo:(void  *)contextInfo
{

    m_returnCode = returnCode;
}

- (IBAction)clickCalibrate:(id)sender {
//    [self FanInitialization];
//    [FansOperationQueue waitUntilAllOperationsAreFinished];
    [panelToShow orderOut:nil];
    [[NSApplication sharedApplication] stopModal];
}
@end
