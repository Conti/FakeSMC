//
//  GraphView.h
//  HWSensors
//
//  Created by Navi on 28.02.12.
//  Copyright (c) 2012 Navi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GraphView : NSView {
    
    NSDictionary * _PlotData;
    NSDictionary * _VerticalMarks;
    float var;
}

@property (retain,readwrite)  NSDictionary * PlotData;
@property (retain,readwrite)  NSDictionary * VerticalMarks;

- (void)drawLineGraphWithContext:(CGContextRef)ctx;
@end
