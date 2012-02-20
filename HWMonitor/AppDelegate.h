//
//  AppDelegate.h
//  HWMonitor
//
//  Created by mozo on 20.10.11.
//  Copyright (c) 2011 mozodojo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISPSmartController.h"
#include "HWMonitorSensor.h"


@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSStatusItem *          statusItem;
    NSFont *                statusItemFont;
    NSDictionary*           statusItemAttributes;
    
    NSMutableArray *        sensorsList;
    NSMutableDictionary *        DisksList;
    
    ISPSmartController *    smartController;
    
    BOOL                    isMenuVisible;
    BOOL                    smart;
    int                     menusCount;
    int                     lastMenusCount;
    
    NSDate          *       lastcall;
    
    IBOutlet NSMenu *       statusMenu;
    NSFont *                statusMenuFont;
    NSDictionary*           statusMenuAttributes;
}

- (void)updateTitles;
- (HWMonitorSensor *)addSensorWithKey:(NSString *)key andType:(NSString *)aType andCaption:(NSString *)caption intoGroup:(SensorGroup)group;
- (void)insertFooterAndTitle:(NSString *)title;

- (void)menuItemClicked:(id)sender;

@end
