//
//  GraphView.h
//  HWSensors
//
//  Created by Navi on 28.02.12.
//  Copyright (c) 2012 Navi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GraphView : NSView

@property (retain,readwrite)  NSDictionary * PlotData;

- (void)drawLineGraphWithContext:(CGContextRef)ctx;
@end
