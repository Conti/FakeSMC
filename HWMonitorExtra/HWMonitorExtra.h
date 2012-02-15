//
//  HWMonitorExtra.h
//  HWSensors
//
//  Created by mozo on 03/02/12.
//  Copyright (c) 2012 mozodojo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SystemUIPlugin.h"
#import "HWMonitorSensor.h"
#import "HWMonitorView.h"

@interface HWMonitorExtra : NSMenuExtra

{
    HWMonitorView *    view;
    IBOutlet NSMenu *       menu;
    
    NSMutableArray *        sensorsList;
    
    int                     menusCount;
    int                     lastMenusCount;
    
    NSFont *                statusBarFont;
    NSFont *                statusMenuFont;
    NSDictionary*           statusMenuAttributes;
}

- (void)updateTitles:(BOOL)forced;
- (void)updateTitlesForced;
- (void)updateTitlesDefault;
- (HWMonitorSensor *)addSensorWithKey:(NSString *)key andCaption:(NSString *)caption intoGroup:(SensorGroup)group;
- (void)insertFooterAndTitle:(NSString *)title;

- (void)menuItemClicked:(id)sender;

@end
