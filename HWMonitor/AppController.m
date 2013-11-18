//
//  AppDelegate.m
//  HWMonitor
//
//  Created by kozlek on 23.02.13.
//  Copyright (c) 2013 kozlek. All rights reserved.
//

/*
 *  Copyright (c) 2013 Natan Zalkin <natan.zalkin@me.com>. All rights reserved.
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 2
 *  of the License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 *  02111-1307, USA.
 *
 */

#import "AppController.h"
#import "HWMonitorDefinitions.h"
#import "HWMonitorEngine.h"
#import "HWMonitorGroup.h"

#import "GroupCell.h"
#import "PrefsSensorCell.h"

#import "Localizer.h"

@interface AppController (Private)

@property (readonly) BOOL shouldUpdateOnlyFavoritesSensors;

@end

@implementation AppController

#pragma mark
#pragma mark Properties:

- (BOOL)shouldUpdateOnlyFavoritesSensors
{
    return !([self.window isVisible] || [_popupController.window isVisible] || [_graphsController.window isVisible] || [_graphsController backgroundMonitoring]);
}

#pragma mark
#pragma mark Methods:

- (void)loadIconNamed:(NSString*)name
{
    if (!_icons)
        _icons = [[NSMutableDictionary alloc] init];
    
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"png"]];
    
    [image setTemplate:YES];
    
    NSImage *altImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[name stringByAppendingString:@"_template"] ofType:@"png"]];

    [altImage setTemplate:YES];
    
    [_icons setObject:[HWMonitorIcon iconWithName:name image:image alternateImage:altImage] forKey:name];
}

- (HWMonitorIcon*)getIconByName:(NSString*)name
{
    return [_icons objectForKey:name];
}

- (HWMonitorIcon*)getIconByGroup:(NSUInteger)group
{
    if ((group & kHWSensorGroupTemperature) || (group & kSMARTGroupTemperature)) {
        return [self getIconByName:kHWMonitorIconTemperatures];
    }
    else if ((group & kSMARTGroupRemainingLife) || (group & kSMARTGroupRemainingBlocks)) {
        return [self getIconByName:kHWMonitorIconSsdLife];
    }
    else if (group & kHWSensorGroupFrequency) {
        return [self getIconByName:kHWMonitorIconFrequencies];
    }
    else if (group & kHWSensorGroupMultiplier) {
        return [self getIconByName:kHWMonitorIconMultipliers];
    }
    else if ((group & kHWSensorGroupPWM) || (group & kHWSensorGroupTachometer)) {
        return [self getIconByName:kHWMonitorIconTachometers];
    }
    else if (group & (kHWSensorGroupVoltage | kHWSensorGroupCurrent | kHWSensorGroupPower)) {
        return [self getIconByName:kHWMonitorIconVoltages];
    }
    else if (group & kBluetoothGroupBattery) {
        return [self getIconByName:kHWMonitorIconBattery];
    }
    
    return nil;
}

- (void)addItem:(id)item forKey:(NSString*)key
{
    if (![_items objectForKey:key]) {
        [_items setObject:item forKey:key];
        [_ordering addObject:key];
    }
}

- (id)getItemAtIndex:(NSUInteger)index
{
    return [_items objectForKey:[_ordering objectAtIndex:index]];
}

- (NSUInteger)getIndexOfItem:(NSString*)key
{
    return [_ordering indexOfObject:key];
}

- (void)rebuildSensorsTableView
{
    if (!_ordering)
        _ordering = [[NSMutableArray alloc] init];
    else
        [_ordering removeAllObjects];
    
    if (!_items)
        _items = [[NSMutableDictionary alloc] init];
    else
        [_items removeAllObjects];
 
    // Add icons
    [self addItem:@"Icons" forKey:@"Icons"];
    
    HWMonitorIcon *icon = [self getIconByName:kHWMonitorIconDefault]; [self addItem:icon forKey:icon.name];
    icon = [self getIconByName:kHWMonitorIconThermometer]; [self addItem:icon forKey:icon.name];
    icon = [self getIconByName:kHWMonitorIconScale]; [self addItem:icon forKey:icon.name];
    icon = [self getIconByName:kHWMonitorIconDevice]; [self addItem:icon forKey:icon.name];
    icon = [self getIconByName:kHWMonitorIconTemperatures]; [self addItem:icon forKey:icon.name];
    icon = [self getIconByName:kHWMonitorIconHddTemperatures]; [self addItem:icon forKey:icon.name];
    icon = [self getIconByName:kHWMonitorIconSsdLife]; [self addItem:icon forKey:icon.name];
    icon = [self getIconByName:kHWMonitorIconMultipliers]; [self addItem:icon forKey:icon.name];
    icon = [self getIconByName:kHWMonitorIconFrequencies]; [self addItem:icon forKey:icon.name];
    icon = [self getIconByName:kHWMonitorIconTachometers]; [self addItem:icon forKey:icon.name];
    icon = [self getIconByName:kHWMonitorIconVoltages]; [self addItem:icon forKey:icon.name];
    icon = [self getIconByName:kHWMonitorIconBattery]; [self addItem:icon forKey:icon.name];

    // Add sensors
    //[self addItem:@"Sensors" forKey:@"Sensors"];
    
    for (HWMonitorGroup *group in _groups) {
        if ([[group items] count]) {
            [self addItem:[group title] forKey:[group title]];
        }
        
        for (HWMonitorItem *item in [group items]) {
            [self addItem:item forKey:item.sensor.name];
        }
    }
    
    if ([_favorites count] == 0) {
        [_favorites addObject:[self getIconByName:kHWMonitorIconThermometer]];
    }
    
    [_favoritesTableView reloadData];
    [_sensorsTableView reloadData];
}

- (void)rebuildSensorsListOnlySmartSensors:(BOOL)onlySmartSensors
{    
    if (!_favorites) {
        _favorites = [[NSMutableArray alloc] init];
    }
    else {
        [_favorites removeAllObjects];
    }
    
    if (!_groups)
        _groups = [[NSMutableArray alloc] init];
    else
        [_groups removeAllObjects];

    if (onlySmartSensors) {
        [_engine rebuildSmartSensorsListOnly];
    }
    else {
        [_engine rebuildSensorsList];
    }
    
    if ([[_engine sensors] count] > 0) {
        
        [_groups addObject:[HWMonitorGroup groupWithEngine:_engine sensorGroup:kHWSensorGroupTemperature title:GetLocalizedString(@"TEMPERATURES") image:[self getIconByName:kHWMonitorIconTemperatures]]];
        [_groups addObject:[HWMonitorGroup groupWithEngine:_engine sensorGroup:kSMARTGroupTemperature title:GetLocalizedString(@"DRIVE TEMPERATURES") image:[self getIconByName:kHWMonitorIconHddTemperatures]]];
        [_groups addObject:[HWMonitorGroup groupWithEngine:_engine sensorGroup:kSMARTGroupRemainingLife title:GetLocalizedString(@"SSD REMAINING LIFE") image:[self getIconByName:kHWMonitorIconSsdLife]]];
        [_groups addObject:[HWMonitorGroup groupWithEngine:_engine sensorGroup:kSMARTGroupRemainingBlocks title:GetLocalizedString(@"SSD REMAINING BLOCKS") image:[self getIconByName:kHWMonitorIconSsdLife]]];
        [_groups addObject:[HWMonitorGroup groupWithEngine:_engine sensorGroup:kHWSensorGroupMultiplier | kHWSensorGroupFrequency title:GetLocalizedString(@"FREQUENCIES") image:[self getIconByName:kHWMonitorIconFrequencies]]];
        [_groups addObject:[HWMonitorGroup groupWithEngine:_engine sensorGroup:kHWSensorGroupPWM |kHWSensorGroupTachometer title:GetLocalizedString(@"FANS & PUMPS") image:[self getIconByName:kHWMonitorIconTachometers]]];
        [_groups addObject:[HWMonitorGroup groupWithEngine:_engine sensorGroup:kHWSensorGroupVoltage title:GetLocalizedString(@"VOLTAGES") image:[self getIconByName:kHWMonitorIconVoltages]]];
        [_groups addObject:[HWMonitorGroup groupWithEngine:_engine sensorGroup:kHWSensorGroupCurrent title:GetLocalizedString(@"CURRENTS") image:[self getIconByName:kHWMonitorIconVoltages]]];
        [_groups addObject:[HWMonitorGroup groupWithEngine:_engine sensorGroup:kHWSensorGroupPower title:GetLocalizedString(@"POWER CONSUMPTION") image:[self getIconByName:kHWMonitorIconVoltages]]];
        [_groups addObject:[HWMonitorGroup groupWithEngine:_engine sensorGroup:kBluetoothGroupBattery title:GetLocalizedString(@"BATTERIES") image:[self getIconByName:kHWMonitorIconBattery]]];
        
        [_favorites removeAllObjects];
        
        NSArray *favoritesList = [[NSUserDefaults standardUserDefaults] objectForKey:kHWMonitorFavoritesList];
        
        if (favoritesList) {
            
            NSUInteger i = 0;
            
            for (i = 0; i < [favoritesList count]; i++) {
                
                NSString *name = [favoritesList objectAtIndex:i];
                
                HWMonitorSensor *sensor = nil;
                HWMonitorIcon *icon = nil;
                
                if ((sensor = [[_engine keys] objectForKey:name])) {
                    [_favorites addObject:sensor];
                }
                else if ((icon = [_icons objectForKey:name])) {
                    [_favorites addObject:icon];
                }
            }
        }
        
        NSArray *hiddenList = [[NSUserDefaults standardUserDefaults] objectForKey:kHWMonitorHiddenList];
        
        for (NSString *key in hiddenList) {
            if ([[[_engine keys] allKeys] containsObject:key]) {
                
                HWMonitorSensor *sensor = [[_engine keys] objectForKey:key];
                
                if (sensor)
                    [[sensor representedObject] setVisible:NO];
            }
        }
    
    }
    
    [_popupController setupWithGroups:_groups];
    [_popupController.statusItemView setFavorites:_favorites];
    
    [_graphsController setupWithGroups:_groups];
    
    [self rebuildSensorsTableView];
}

- (void)captureValuesOfSensorsInArray:(NSArray*)sensors
{
    if ([self.window isVisible]) {
        for (HWMonitorSensor *sensor in sensors) {
            id cell = [_sensorsTableView viewAtColumn:0 row:[self getIndexOfItem:[sensor name]] makeIfNecessary:NO];

            if (cell && [cell isKindOfClass:[PrefsSensorCell class]]) {
                [[cell valueField] performSelectorOnMainThread:@selector(takeStringValueFrom:)
                                                    withObject:sensor
                                                 waitUntilDone:YES];
            }
        }

        [_favorites enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            id cell = [_favoritesTableView viewAtColumn:0 row:idx + 1 makeIfNecessary:NO];

            if (cell && [cell isKindOfClass:[PrefsSensorCell class]]) {
                [[cell valueField] performSelectorOnMainThread:@selector(takeStringValueFrom:)
                                                    withObject:obj
                                                 waitUntilDone:YES];
            }
        }];
    }

    [_popupController captureValuesOfSensorsInArray:sensors];
    [_graphsController captureDataToHistoryNow];
}

- (void)smcSensorsUpdateLoop
{
    if ([_smcSensorsLastUdated timeIntervalSinceNow] < -_smcSensorsLoopTimer.timeInterval * 0.7f) {

        _smcSensorsLastUdated = [NSDate dateWithTimeIntervalSinceNow:0];

        if (!self.shouldUpdateOnlyFavoritesSensors) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSArray *sensors = [_engine updateSmcSensors];
                [self captureValuesOfSensorsInArray:sensors];
            }];
        }
        else if ([_favorites count]) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSArray *sensors = [_engine updateSmcSensorsInArray:_favorites];
                [self captureValuesOfSensorsInArray:sensors];
            }];
        }
    }
}

- (void)smartSensorsUpdateLoop
{
    if ([_smartSensorsLastUdated timeIntervalSinceNow] < -_smartSensorsloopTimer.timeInterval * 0.7f) {

        _smartSensorsLastUdated = [NSDate dateWithTimeIntervalSinceNow:0];

        if (!self.shouldUpdateOnlyFavoritesSensors) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSArray *sensors = [_engine updateSmartSensors];
                [self captureValuesOfSensorsInArray:sensors];
            }];
        }
        else if ([_favorites count]) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSArray *sensors = [_engine updateSmartSensorsInArray:_favorites];
                [self captureValuesOfSensorsInArray:sensors];
            }];
        }
    }
}

-(void)checkForUpdates:(id)sender
{
    if ([sender isKindOfClass:[NSButton class]]) {
        NSButton *button = (NSButton*)sender;

        if ([button state]) {
            _sharedUpdater.automaticallyChecksForUpdates = YES;
            [_sharedUpdater checkForUpdatesInBackground];
        }
    }
    else {
        [_sharedUpdater checkForUpdates:sender];
    }
}

#pragma mark
#pragma mark Overrides:

- (id)init
{
    self = [super initWithWindowNibName:@"AppController"];

    if (self != nil)
    {

    }

    return self;
}

-(void)showWindow:(id)sender
{
    for (HWMonitorSensor *sensor in [_engine sensors]) {
        id cell = [_sensorsTableView viewAtColumn:0 row:[self getIndexOfItem:[sensor name]] makeIfNecessary:NO];

        if (cell && [cell isKindOfClass:[PrefsSensorCell class]]) {
            [[cell valueField] takeStringValueFrom:sensor];
        }
    }

    [NSApp activateIgnoringOtherApps:YES];
    [super showWindow:sender];
}

#pragma mark
#pragma mark Events:

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [Localizer localizeView:self.window];
    [Localizer localizeView:_graphsController.window];

    [self loadIconNamed:kHWMonitorIconDefault];
    [self loadIconNamed:kHWMonitorIconThermometer];
    [self loadIconNamed:kHWMonitorIconScale];
    [self loadIconNamed:kHWMonitorIconDevice];
    [self loadIconNamed:kHWMonitorIconTemperatures];
    [self loadIconNamed:kHWMonitorIconHddTemperatures];
    [self loadIconNamed:kHWMonitorIconSsdLife];
    [self loadIconNamed:kHWMonitorIconMultipliers];
    [self loadIconNamed:kHWMonitorIconFrequencies];
    [self loadIconNamed:kHWMonitorIconTachometers];
    [self loadIconNamed:kHWMonitorIconVoltages];
    [self loadIconNamed:kHWMonitorIconBattery];

    _colorThemes = [ColorTheme createColorThemes];

    _engine = [[HWMonitorEngine alloc] initWithBundle:[NSBundle mainBundle]];

    [_engine setUseFahrenheit:[[NSUserDefaults standardUserDefaults] boolForKey:kHWMonitorUseFahrenheitKey]];
    [_engine setUseBsdNames:[[NSUserDefaults standardUserDefaults] boolForKey:kHWMonitorUseBSDNames]];

    [[_popupController statusItemView] setEngine:_engine];
    //    [[_popupController statusItemView] setUseBigFont:[[NSUserDefaults standardUserDefaults] boolForKey:kHWMonitorUseBigStatusMenuFont]];
    //    [[_popupController statusItemView] setUseShadowEffect:[[NSUserDefaults standardUserDefaults] boolForKey:kHWMonitorUseShadowEffect]];
    //    [_popupController setShowVolumeNames:[[NSUserDefaults standardUserDefaults] integerForKey:kHWMonitorShowVolumeNames]];
    [_popupController setColorTheme:[_colorThemes objectAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kHWMonitorColorThemeIndex]]];

    //    [_graphsController setUseFahrenheit:[_engine useFahrenheit]];
    //    [_graphsController setUseSmoothing:[[NSUserDefaults standardUserDefaults] boolForKey:kHWMonitorGraphsUseDataSmoothing]];
    //    [_graphsController setBackgroundMonitoring:[[NSUserDefaults standardUserDefaults] boolForKey:kHWMonitorGraphsBackgroundMonitor]];
    //    [_graphsController setIsTopmost:[[NSUserDefaults standardUserDefaults] boolForKey:kHWMonitorWindowTopmost]];
    //    [_graphsController setGraphsScale:[[NSUserDefaults standardUserDefaults] boolForKey:kHWMonitorGraphsScale]];

    [_favoritesTableView registerForDraggedTypes:[NSArray arrayWithObject:kHWMonitorTableViewDataType]];
    [_favoritesTableView setDraggingSourceOperationMask:NSDragOperationMove | NSDragOperationDelete forLocal:YES];
    [_sensorsTableView registerForDraggedTypes:[NSArray arrayWithObject:kHWMonitorTableViewDataType]];
    [_sensorsTableView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];


    [self rebuildSensorsListOnlySmartSensors: NO];

    _smcSensorsLastUdated = [NSDate dateWithTimeIntervalSinceNow:0];

    [self updateRateChanged:nil];
    [self graphsScaleChanged:nil];

    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(workspaceDidMountOrUnmount:) name:NSWorkspaceDidMountNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(workspaceDidMountOrUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(workspaceWillSleep:) name:NSWorkspaceWillSleepNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(workspaceDidWake:) name:NSWorkspaceDidWakeNotification object:nil];
}

-(void)applicationWillTerminate:(NSNotification *)notification
{
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self name: NSWorkspaceDidMountNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self name: NSWorkspaceDidUnmountNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self name: NSWorkspaceWillSleepNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self name: NSWorkspaceDidWakeNotification object:nil];
}

-(void)workspaceDidMountOrUnmount:(id)sender
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self rebuildSensorsListOnlySmartSensors:YES];
    }];
}

-(void)workspaceWillSleep:(id)sender
{
    if (_smcSensorsLoopTimer) [_smcSensorsLoopTimer invalidate];
    if (_smartSensorsloopTimer) [_smartSensorsloopTimer invalidate];
}

-(void)workspaceDidWake:(id)sender
{
    [self updateRateChanged:sender];
}

- (IBAction)toggleSensorVisibility:(id)sender
{
    id item = [self getItemAtIndex:[sender tag]];
    
    [item setVisible:[sender state]];
    
    [_popupController setupWithGroups:_groups];
    
    NSMutableArray *hiddenList = [[NSMutableArray alloc] init];
    
    for (id item in [_items allValues]) {
        if ([item isKindOfClass:[HWMonitorItem class]] && ![item isVisible]) {
            [hiddenList addObject:[[item sensor] name]];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:hiddenList forKey:kHWMonitorHiddenList];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)favoritesChanged:(id)sender
{
    [_favoritesTableView reloadData];
    
    [_popupController.statusItemView setFavorites:_favorites];
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    
    for (id item in _favorites) {
        NSString *name = nil;
        
        if ([item isKindOfClass:[HWMonitorIcon class]] || [item isKindOfClass:[HWMonitorSensor class]]) {
            name = [item name];
        }
        else continue;
        
        if ([[_engine keys] objectForKey:name] || [_icons objectForKey:name]) {
            [list addObject:name];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:list forKey:kHWMonitorFavoritesList];
}

-(IBAction)useFahrenheitChanged:(id)sender
{
    BOOL useFahrenheit = [sender selectedRow] == 1;
    
    [_engine setUseFahrenheit:useFahrenheit];
    
    [_sensorsTableView reloadData];
    [_popupController reloadData];
    [_graphsController setUseFahrenheit:useFahrenheit];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)colorThemeChanged:(id)sender
{
    [_popupController setColorTheme:[_colorThemes objectAtIndex:[sender selectedRow]]];
}

-(IBAction)useBigFontChanged:(id)sender
{
    [_popupController.statusItemView setUseBigFont:[sender state]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)useShadowEffectChanged:(id)sender
{
    [_popupController.statusItemView setUseShadowEffect:[sender state]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)useBSDNamesChanged:(id)sender
{
    [_engine setUseBsdNames:[sender state]];
    [_popupController.tableView reloadData];
    [self rebuildSensorsTableView];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)showVolumeNamesChanged:(id)sender
{
    [_popupController setShowVolumeNames:[sender state]];
    [_popupController reloadData];
    [self rebuildSensorsTableView];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(float)getSmcSensorsUpdateRate
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    float value = [[NSUserDefaults standardUserDefaults] floatForKey:kHWMonitorSmcSensorsUpdateRate];
    float validatedValue = value > 10 ? 10 : value < 1 ? 1 : value;
    
    if (value != validatedValue) {
        value = validatedValue;
        [[NSUserDefaults standardUserDefaults] setFloat:value forKey:kHWMonitorSmcSensorsUpdateRate];
    }
    
    [_smcUpdateRateTextField setStringValue:[NSString stringWithFormat:@"%1.1f %@", value, GetLocalizedString(@"sec")]];
    
    return value;
}

-(float)getSmartSensorsUpdateRate
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    float value = [[NSUserDefaults standardUserDefaults] floatForKey:kHWMonitorSmartSensorsUpdateRate];
    float validatedValue = value > 30 ? 30 : value < 5 ? 5 : value;
    
    if (value != validatedValue) {
        value = validatedValue;
        [[NSUserDefaults standardUserDefaults] setFloat:value forKey:kHWMonitorSmartSensorsUpdateRate];
    }
    
    [_smartUpdateRateTextField setStringValue:[NSString stringWithFormat:@"%1.0f %@", value, GetLocalizedString(@"min")]];
    
    return value;
}

-(void)updateRateChanged:(NSNotification *)aNotification
{
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(smcSensorsUpdateLoop)]];
    [invocation setTarget:self];
    [invocation setSelector:@selector(smcSensorsUpdateLoop)];

    if (_smcSensorsLoopTimer) {
        [_smcSensorsLoopTimer invalidate];
    }

    _smcSensorsLoopTimer = [NSTimer timerWithTimeInterval:[self getSmcSensorsUpdateRate] invocation:invocation repeats:YES];

    [[NSRunLoop mainRunLoop] addTimer:_smcSensorsLoopTimer forMode:NSRunLoopCommonModes];

    invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(smartSensorsUpdateLoop)]];
    [invocation setTarget:self];
    [invocation setSelector:@selector(smartSensorsUpdateLoop)];

    if (_smartSensorsloopTimer) {
        [_smartSensorsloopTimer invalidate];
    }

    _smartSensorsloopTimer = [NSTimer timerWithTimeInterval:[self getSmartSensorsUpdateRate] * 60 invocation:invocation repeats:YES];

    [[NSRunLoop mainRunLoop] addTimer:_smartSensorsloopTimer forMode:NSRunLoopCommonModes];
}

- (void)toggleGraphSmoothing:(id)sender
{
    [_graphsController setUseSmoothing:[sender state] == NSOnState];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)graphsBackgroundMonitorChanged:(id)sender
{
    [_graphsController setBackgroundMonitoring:[sender state]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)graphsWindowTopmostChanged:(id)sender
{
    [_graphsController setIsTopmost:[sender state]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)graphsScaleChanged:(id)sender
{
    [_graphsController setGraphsScale:[sender floatValue]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark
#pragma mark PopupControllerDelegate:

- (void) popupWillOpen:(id)sender
{
    [self smcSensorsUpdateLoop];
    [self smartSensorsUpdateLoop];
}

#pragma mark
#pragma mark  NSTableViewDelegate:

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == _favoritesTableView) {
        return [_favorites count] + 1;
    }

    return [_items count];
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 19;
}

-(BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
    if (tableView == _favoritesTableView) {
        return row == 0 ? YES : NO;
    }
    else if (tableView == _sensorsTableView) {
        return [[self getItemAtIndex:row] isKindOfClass:[NSString class]];
    }
    
    return NO;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == _favoritesTableView) {
        if (row == 0) {
            GroupCell *groupCell = [tableView makeViewWithIdentifier:@"Group" owner:self];
            
            [[groupCell textField] setStringValue:GetLocalizedString(@"Menubar items")];
            
            //[groupCell setColorTheme:[_colorThemes objectAtIndex:0]];
            
            return groupCell;
        }
        else {
            id item = [_favorites objectAtIndex:row - 1];
            
            if ([item isKindOfClass:[HWMonitorSensor class]]) {
                HWMonitorSensor *sensor = (HWMonitorSensor*)item;
                
                PrefsSensorCell *itemCell = [tableView makeViewWithIdentifier:@"Sensor" owner:self];;
                
                [itemCell.imageView setImage:[[self getIconByGroup:[sensor group]] image]];
                [itemCell.textField setStringValue:[sensor title]];
                [itemCell.valueField setStringValue:[sensor stringValue]];
                
                return itemCell;
            }
            else if ([item isKindOfClass:[HWMonitorIcon class]]) {
                PrefsSensorCell *iconCell = [tableView makeViewWithIdentifier:@"Icon" owner:self];
                
                [[iconCell imageView] setObjectValue:[item image]];
                [[iconCell textField] setStringValue:GetLocalizedString([item name])];
                
                return iconCell;
            }
        }
    }
    else if (tableView == _sensorsTableView) {
        id item = [self getItemAtIndex:row];
        
        if ([item isKindOfClass:[HWMonitorItem class]]) {
            HWMonitorSensor *sensor = [item sensor];
            
            PrefsSensorCell *itemCell = [tableView makeViewWithIdentifier:@"Sensor" owner:self];
            
            [itemCell.checkBox setState:[item isVisible]];
            //[itemCell.checkBox setToolTip:GetLocalizedString(@"Show sensor in HWMonitor menu")];
            [itemCell.checkBox setTag:[_ordering indexOfObject:[sensor name]]];
            [itemCell.imageView setImage:[[self getIconByGroup:[sensor group]] image]];
            [itemCell.textField setStringValue:[sensor title]];
            [itemCell.valueField setStringValue:[sensor stringValue]];
            
            return itemCell;
        }
        else if ([item isKindOfClass:[HWMonitorIcon class]]) {
            PrefsSensorCell *iconCell = [tableView makeViewWithIdentifier:@"Icon" owner:self];
            
            [[iconCell imageView] setObjectValue:[item image]];
            [[iconCell textField] setStringValue:GetLocalizedString([item name])];
            
            return iconCell;
        }
        else if ([item isKindOfClass:[NSString class]]) {
            GroupCell *groupCell = [tableView makeViewWithIdentifier:@"Group" owner:self];
            
            [[groupCell textField] setStringValue:GetLocalizedString(item)];
            //[groupCell setColorTheme:[_colorThemes objectAtIndex:0]];
            
            return groupCell;
        }
    }

    return nil;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard;
{
    if (tableView == _favoritesTableView) {
        if ([rowIndexes firstIndex] == 0) {
            return NO;
        }
        
        NSData *indexData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
        
        [pboard declareTypes:[NSArray arrayWithObjects:kHWMonitorTableViewDataType, nil] owner:self];
        [pboard setData:indexData forType:kHWMonitorTableViewDataType];
        
        _hasDraggedFavoriteItem = YES;
    }
    else if (tableView == _sensorsTableView) {
        id item = [self getItemAtIndex:[rowIndexes firstIndex]];
        
        if ([item isKindOfClass:[NSString class]]) {
            return NO;
        }
//        else if ([item isKindOfClass:[HWMonitorItem class]] && [_favorites containsObject:[item sensor]]) {
//            //return NO;
//            _currentItemDragOperation = NSDragOperationPrivate;
//        }
        
        NSData *indexData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
        
        [pboard declareTypes:[NSArray arrayWithObjects:kHWMonitorTableViewDataType, NSStringPboardType, nil] owner:self];
        
        [pboard setData:indexData forType:kHWMonitorTableViewDataType];
        [pboard setString:[_ordering objectAtIndex:[rowIndexes firstIndex]] forType:NSStringPboardType];
        
        _hasDraggedFavoriteItem = NO;
    }
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)toRow proposedDropOperation:(NSTableViewDropOperation)dropOperation;
{
    //_currentItemDragOperation = NSDragOperationNone;
    
    if (tableView == _favoritesTableView) {
        [tableView setDropRow:toRow dropOperation:NSTableViewDropAbove];
        
        NSPasteboard* pboard = [info draggingPasteboard];
        NSData* rowData = [pboard dataForType:kHWMonitorTableViewDataType];
        NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
        NSInteger fromRow = [rowIndexes firstIndex];
        
        if ([info draggingSource] == _favoritesTableView) {
            _currentItemDragOperation = toRow < 1 || toRow == fromRow || toRow == fromRow + 1 ? NSDragOperationNone : NSDragOperationMove;
        }
        else if ([info draggingSource] == _sensorsTableView) {
            id item = [self getItemAtIndex:fromRow];
            
            if ([item isKindOfClass:[HWMonitorItem class]]) {
                _currentItemDragOperation = [_favorites containsObject:[item sensor]] ? NSDragOperationPrivate : toRow > 0  ? NSDragOperationCopy : NSDragOperationNone;
            }
            else _currentItemDragOperation = toRow > 0 ? NSDragOperationCopy : NSDragOperationNone;
        }
    }
    else if (tableView == _sensorsTableView) {
        _currentItemDragOperation = NSDragOperationNone;
    }
    
    return _currentItemDragOperation;
}

-(void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    if (tableView == _favoritesTableView && (operation == NSDragOperationDelete || _currentItemDragOperation == NSDragOperationDelete))
    {
        NSPasteboard* pboard = [session draggingPasteboard];
        NSData* rowData = [pboard dataForType:kHWMonitorTableViewDataType];
        NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];

        [_favorites removeObjectAtIndex:[rowIndexes firstIndex] - 1];
        
        [self favoritesChanged:tableView];
        
        NSShowAnimationEffect(NSAnimationEffectPoof, screenPoint, NSZeroSize, nil, nil, nil);
    }
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)toRow dropOperation:(NSTableViewDropOperation)dropOperation;
{
    if (tableView == _favoritesTableView) {
        
        NSPasteboard* pboard = [info draggingPasteboard];
        NSData* rowData = [pboard dataForType:kHWMonitorTableViewDataType];
        NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
        NSInteger fromRow = [rowIndexes firstIndex];
        
        if ([info draggingSource] == _sensorsTableView) {
            id item = [self getItemAtIndex:fromRow];
            
            if ([item isKindOfClass:[HWMonitorItem class]]) {
                if (![_favorites containsObject:[item sensor]]) {
                    [_favorites insertObject:[item sensor] atIndex:toRow > 0 ? toRow - 1 : 0];
                }
            }
            else if ([item isKindOfClass:[HWMonitorIcon class]]) {
                [_favorites insertObject:item  atIndex:toRow > 0 ? toRow - 1 : 0];
            }
        }
        else if ([info draggingSource] == _favoritesTableView) {
            id item = [_favorites objectAtIndex:fromRow - 1];
            
            [_favorites insertObject:item atIndex:toRow > 0 ? toRow - 1 : 0];
            [_favorites removeObjectAtIndex:fromRow > toRow ? fromRow : fromRow - 1];
        }
    
        [self favoritesChanged:tableView];
    }
    
    return YES;
}

@end
