//
//  HWMonitorGraphsView.m
//  HWSensors
//
//  Created by kozlek on 07.07.12.
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


#import "GraphsView.h"
#import "HWMonitorDefinitions.h"
#import "Localizer.h"

static NSMutableDictionary *graphs_history = nil;

@implementation GraphsView

#define LeftViewMargin      1
#define TopViewMargin       1
#define RightViewMargin     1
#define BottomViewMargin    1

-(NSMutableDictionary *)graphs
{
    if (!graphs_history) {
        graphs_history = [[NSMutableDictionary alloc] init];
    }

    return graphs_history;
}

-(id)init
{
    self = [super init];
    
    if (self) {
        NSShadow *shadow = [[NSShadow alloc] init];
        
        [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.55]];
        [shadow setShadowOffset:CGSizeMake(0, -1.0)];
        [shadow setShadowBlurRadius:1.0];
        
        _legendAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSFont systemFontOfSize:9.0], NSFontAttributeName,
                             [NSColor yellowColor], NSForegroundColorAttributeName,
                             shadow, NSShadowAttributeName,
                             nil];
        
        _legendFormat = @"%1.0f";
        
        _graphScale = 5.0;
    }
    
    return self;
}

- (NSArray*)addItemsFromList:(NSArray*)itemsList forSensorGroup:(HWSensorGroup)sensorsGroup;
{
    if (sensorsGroup & (kHWSensorGroupTemperature | kSMARTGroupTemperature)) {
        _legendFormat = @"%1.0f°";
    }
    else if (sensorsGroup & kHWSensorGroupFrequency) {
        _legendFormat = GetLocalizedString(@"%1.0f MHz");
    }
    else if (sensorsGroup & kHWSensorGroupTachometer) {
        _legendFormat = GetLocalizedString(@"%1.0f rpm");
    }
    else if (sensorsGroup & kHWSensorGroupVoltage) {
        _legendFormat = GetLocalizedString(@"%1.3f V");
    }
    else if (sensorsGroup & kHWSensorGroupCurrent) {
        _legendFormat = GetLocalizedString(@"%1.3f A");
    }
    else if (sensorsGroup & kHWSensorGroupPower) {
        _legendFormat = GetLocalizedString(@"%1.3f W");
    }
    else if (sensorsGroup & kBluetoothGroupBattery) {
        _legendFormat = @"%1.0f%";
    }
    
    if (!_items) {
        _items = [[NSMutableArray alloc] init];
    }
    else {
        [_items removeAllObjects];
    }
 
    for (HWMonitorItem *item in itemsList) {
        [_items addObject:item];
        if (![self.graphs objectForKey:item.sensor.name]) {
            [self.graphs setObject:[[NSMutableArray alloc] init] forKey:[[item sensor] name]];
        }
    }
    
    [self calculateGraphBoundsFindExtremes:YES];
    
    return _items;
}

- (void)captureDataToHistoryNow;
{
    for (HWMonitorItem *item in _items) {
        HWMonitorSensor *sensor = [item sensor];
        NSMutableArray *history = [self.graphs objectForKey:[sensor name]];

        if ([sensor rawValue]) {
            [history addObject:[sensor rawValue]];
            
            if ([history count] > _maxPoints) {
                //[history removeObjectAtIndex:0];
                [history removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [history count] - _maxPoints - 1)]];
            }
        }
    }
    
    [self calculateGraphBoundsFindExtremes:YES];
    
    [self setNeedsDisplay:YES];
}

- (void)calculateGraphBoundsFindExtremes:(BOOL)findExtremes
{
    if (findExtremes) {
        _maxY = 0, _minY = MAXFLOAT;
        
        for (HWMonitorItem *item in _items) {

            if ([_graphsController checkItemIsHidden:item])
                continue;
            
            HWMonitorSensor *sensor = [item sensor];
            NSArray *points = [self.graphs objectForKey:[sensor name]];
            
            if (points) {
                for (NSNumber *point in points) {
                    if ([point doubleValue] < _minY) {
                        _minY = [point doubleValue];
                    }
                    else if ([point doubleValue] > _maxY)
                    {
                        _maxY = [point doubleValue];
                    }
                }
            }
        }
    }

    _maxPoints = self.window.windowNumber > 0 ? self.bounds.size.width / _graphScale : 100;
    
    if ((_maxY == 0 && _minY == MAXFLOAT)) {
        _graphBounds = NSMakeRect(0, 0, _maxPoints, 100);
    }
    else if (_minY >= _maxY) {
        _graphBounds = NSMakeRect(0, _minY, _maxPoints, _minY + 100);
    }
    else {

        double minY = _minY <= 0 ? _minY : _minY - _minY * 0.2;
        double maxY = _maxY + _maxY * 0.1;
        
        _graphBounds = NSMakeRect(0, minY, _maxPoints, maxY - minY);
    }
}

- (NSPoint)graphPointToView:(NSPoint)point
{
    double graphScaleX = _graphScale; //([self bounds].size.width - LeftViewMargin - RightViewMargin) / _graphBounds.size.width;
    double graphScaleY = ([self bounds].size.height - TopViewMargin - BottomViewMargin) / _graphBounds.size.height;

    double x = LeftViewMargin + (point.x - _graphBounds.origin.x) * graphScaleX;
    double y = BottomViewMargin + (point.y - _graphBounds.origin.y) * graphScaleY;
    
    return NSMakePoint(x, y);
}

- (void)drawRect:(NSRect)rect
{
    [self calculateGraphBoundsFindExtremes:NO];
    
    NSGraphicsContext* context = [NSGraphicsContext currentContext];
    
    [context saveGraphicsState];
    
    // Clipping rect
    [NSBezierPath clipRect:NSMakeRect(LeftViewMargin, TopViewMargin, self.bounds.size.width - LeftViewMargin - RightViewMargin, self.bounds.size.height - TopViewMargin - BottomViewMargin)];
    
    [[[NSGradient alloc]
      initWithStartingColor:[NSColor colorWithCalibratedWhite:0.15 alpha:0.85]
                endingColor:[NSColor colorWithCalibratedWhite:0.25 alpha:0.85]]
        drawInRect:self.bounds angle:270];
    
    // Draw marks
    [context setShouldAntialias:NO];
    
    NSBezierPath *path = [[NSBezierPath alloc] init];
    
    if (_minY < _maxY) {
        // Draw extremums
        [context setShouldAntialias:NO];
        
        [path removeAllPoints];
        [path moveToPoint:[self graphPointToView:NSMakePoint(_graphBounds.origin.x,_maxY)]];
        [path lineToPoint:[self graphPointToView:NSMakePoint(_graphBounds.origin.x + _graphBounds.size.width,_maxY)]];
        [path moveToPoint:[self graphPointToView:NSMakePoint(_graphBounds.origin.x,_minY)]];
        [path lineToPoint:[self graphPointToView:NSMakePoint(_graphBounds.origin.x + _graphBounds.size.width,_minY)]];
        CGFloat pattern[2] = { 4.0, 4.0 };
        [path setLineDash:pattern count:2 phase:1.0];
        [[NSColor lightGrayColor] set];
        [path setLineWidth:0.25];
        [path stroke];
        CGFloat resetPattern[1] = { 0 };
        [path setLineDash:resetPattern count:0 phase:0];
    }
    
    // Draw graphs
    
    [context setShouldAntialias:YES];
    
    for (HWMonitorItem *item in _items) {
        
        if ([_graphsController checkItemIsHidden:item])
            continue;

        HWMonitorSensor *sensor = [item sensor];
        NSArray *values = [self.graphs objectForKey:[sensor name]];
        
        if (!values || [values count] < 2)
            continue;
        
        [path removeAllPoints];
        [path setLineJoinStyle:NSRoundLineJoinStyle];
        
        CGFloat startOffset = /*[values count] > _maxPoints ?*/ _maxPoints - [values count] /*: _graphBounds.size.width - _maxPoints*/;
        
        if (_useSmoothing) {
            NSPoint lastPoint = NSMakePoint(startOffset, [[values objectAtIndex:0] doubleValue]);
            
            [path moveToPoint:[self graphPointToView:lastPoint]];
            
            for (NSUInteger index = 1; index < [values count]; index++) {
                NSPoint nextPoint = NSMakePoint(startOffset + index, [[values objectAtIndex:index] doubleValue]);
                NSPoint controlPoint1 = NSMakePoint(lastPoint.x + (nextPoint.x - lastPoint.x) * 0.7, lastPoint.y + (nextPoint.y - lastPoint.y) * 0.35);
                NSPoint controlPoint2 = NSMakePoint(lastPoint.x + (nextPoint.x - lastPoint.x) * 0.3, lastPoint.y + (nextPoint.y - lastPoint.y) * 0.65);
                
                [path curveToPoint:[self graphPointToView:nextPoint]
                     controlPoint1:[self graphPointToView:controlPoint1]
                     controlPoint2:[self graphPointToView:controlPoint2]];
                
                lastPoint = nextPoint;
            }
        }
        else {
            [path moveToPoint:[self graphPointToView:NSMakePoint(startOffset, [[values objectAtIndex:0] doubleValue])]];
            
            for (NSUInteger index = 1; index < [values count]; index++) {
                NSPoint p1 = NSMakePoint(startOffset + index, [[values objectAtIndex:index] doubleValue]);
                [path lineToPoint:[self graphPointToView:p1]];
            }
        }
        
        if (item == [_graphsController selectedItem]) {
            [[[item color] highlightWithLevel:0.8] set];
            [path setLineWidth:3.0];
        }
        else {
            [[item color] set];
            [path setLineWidth:1.5];
        }
        
        [path stroke];
    }
    
    // Draw extreme values
    if (_minY < _maxY) {
        [context setShouldAntialias:YES];

        NSAttributedString *maxExtremeTitle = [[NSAttributedString alloc]
                                               initWithString:[NSString stringWithFormat:_legendFormat, (_sensorGroup & (kHWSensorGroupTemperature | kSMARTGroupTemperature) && _useFahrenheit ? _maxY * (9.0f / 5.0f) + 32.0f : _maxY )]
                                               attributes:_legendAttributes];

        NSAttributedString *minExtremeTitle = [[NSAttributedString alloc]
                                     initWithString:[NSString stringWithFormat:_legendFormat, (_sensorGroup & (kHWSensorGroupTemperature | kSMARTGroupTemperature) && _useFahrenheit ? _minY * (9.0f / 5.0f) + 32.0f : _minY )]
                                     attributes:_legendAttributes];

        if ([self graphPointToView:NSMakePoint(0, _maxY)].y + 2 + [maxExtremeTitle size].height > [self graphPointToView:NSMakePoint(0, _graphBounds.origin.y + _graphBounds.size.height)].y || [self graphPointToView:NSMakePoint(0, _minY)].y - [minExtremeTitle size].height < [self graphPointToView:_graphBounds.origin].y) {
            [maxExtremeTitle drawAtPoint:NSMakePoint(LeftViewMargin + 2, [self graphPointToView:NSMakePoint(0, _maxY)].y - [maxExtremeTitle size].height)];
            [minExtremeTitle drawAtPoint:NSMakePoint(LeftViewMargin + 2, [self graphPointToView:NSMakePoint(0, _minY)].y + 2)];
        }
        else {
            [maxExtremeTitle drawAtPoint:NSMakePoint(LeftViewMargin + 2, [self graphPointToView:NSMakePoint(0, _maxY)].y + 2)];
            [minExtremeTitle drawAtPoint:NSMakePoint(LeftViewMargin + 2, [self graphPointToView:NSMakePoint(0, _minY)].y - [minExtremeTitle size].height)];
        }
    }
    
    [context restoreGraphicsState];
}

@end
