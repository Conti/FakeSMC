//
//  sgAppController.m
//  HWSensors
//
//  Created by Navi on 24.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "sgAppController.h"




@implementation sgAppController

@synthesize currentFan;
@synthesize mainWindow;
@synthesize model;
@synthesize sgTableView;
@synthesize CalibrationGraphView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // Initialization code here.
        model = [[sgModel alloc]init];
        
        for (int i=0; i<[sgModel numberOfFans]; i++) {
            [model addFan:[model initialPrepareFan:i] withName:[NSString stringWithFormat:@"FAN%d",i]];
            
        }
        
        
        [sgTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                    [self methodSignatureForSelector:@selector(updateTitles)]];
        [invocation setTarget:self];
        [invocation setSelector:@selector(updateTitles)];
        [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:2 invocation:invocation repeats:YES] forMode:NSRunLoopCommonModes];
        
        
        FansOperationQueue = [[NSOperationQueue alloc] init];
        [FansOperationQueue setMaxConcurrentOperationCount:4];
        
//        [model readFanDictionatyFromFile:@"/Users/ivan/Development/Fans.plist"];
        
        [FansOperationQueue addOperationWithBlock:^{
            [self FanInitialization];
       }];
        
   
    }
    
    
    return self;
}
         
- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    NSUInteger i = [proposedSelectionIndexes lastIndex];;
        NSDictionary * fan = [[model fans] valueForKey:[NSString stringWithFormat:@"FAN%d",i]];
        currentFan = fan;
        if ([[fan valueForKey:KEY_CONTROLABLE] boolValue] == YES){
            
            NSArray * dataup = [fan valueForKey: KEY_DATA_UPWARD];
            NSArray * datadown = [fan valueForKey: KEY_DATA_DOWNWARD];
            NSMutableDictionary * allPlots = [NSMutableDictionary dictionaryWithCapacity:2];    
            NSMutableDictionary * plotdataUp = [NSMutableDictionary dictionaryWithCapacity:1];
            NSMutableDictionary * plotdataDown = [NSMutableDictionary dictionaryWithCapacity:1];
            NSMutableDictionary * middleLine = [NSMutableDictionary dictionaryWithCapacity:1];

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
    while (nextFan = [enumerator nextObject]) 
        [FansOperationQueue addOperationWithBlock:^{
            
            NSLog(@"Starting thread for %@",nextFan);
            [model calibrateFan: nextFan];
        }];
    


}

-(void) updateTitles
{
    [[model fans] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
   
            NSData * dataptr = [sgModel readValueForKey: [obj valueForKey:KEY_READ_RPM]];
            UInt16 value = [sgModel decode_fpe2:*((UInt16 *)[dataptr bytes])];
            [obj setObject:[NSString stringWithFormat:@"%d RPM", value ] forKey:KEY_CURRENT_RPM]; 
        
    } ];
    

     
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[model fans] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [[model fans] valueForKey:[NSString stringWithFormat:@"FAN%d",rowIndex]];
}

-(void) applicationWillTerminate:(NSNotification *)notification
{
    [model writeFanDictionatyToFile:@"/Users/ivan/Development/Fans.plist"];
}



@end
