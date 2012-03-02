//
//  GraphView.m
//  HWSensors
//
//  Created by Navi on 28.02.12.
//  Copyright (c) 2012 Navi. All rights reserved.
//

#import "GraphView.h"
#import "NSColor+CGColorAdditions.h"


#define kOffsetX 10
#define kStepX 20
#define kGraphTop 0
#define kStepY 20
#define kOffsetY 10


@implementation GraphView

@synthesize PlotData;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}



- (void)drawLineGraphWithContext:(CGContextRef)ctx
{
    if([PlotData count]>0)
        
    {
       [PlotData enumerateKeysAndObjectsUsingBlock:^(id key,id obj, BOOL *stop) {
           
        __block float denominator=1.0;
           NSColor * DrawColor = [obj objectForKey:@"Color"];
           NSArray * data = [obj objectForKey:@"Data"];
           NSNumber * scale = [obj objectForKey:@"Scale"];
           if (scale) {
               denominator = [scale floatValue];
           } else
        [data  enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if([obj floatValue]> denominator) denominator = [obj floatValue];
        }];
        CGContextSetLineWidth(ctx, 2.0);
//        CGContextSetFillColorWithColor(ctx, [[NSColor redColor] CGColor]);

        CGContextSetStrokeColorWithColor(ctx, [DrawColor CGColor]);
        int maxGraphHeight = self.bounds.size.height - kOffsetY;
        CGContextBeginPath(ctx);
         CGContextMoveToPoint(ctx, kOffsetX,  maxGraphHeight * [[data objectAtIndex:0] floatValue]/denominator);
       
       
        float var = self.bounds.size.width / ([data count] - 1); 
        for (int i = 1; i < [data count]; i++)
        {
            CGContextAddLineToPoint(ctx, kOffsetX + i * var ,  maxGraphHeight * [[data objectAtIndex:i] floatValue]/denominator);
        }
//        CGContextAddLineToPoint(ctx, self.bounds.size.width,  0);
//        CGContextClosePath(ctx);
        CGContextDrawPath(ctx, kCGPathStroke);
        
         
       }];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetLineWidth(context, 0.6);
    CGContextSetStrokeColorWithColor(context, [[NSColor blueColor] CGColor]);
   
  
    
    // How many lines?
    int howMany = (self.bounds.size.width - kOffsetX) / kStepX;
    // Here the lines go
    for (int i = 0; i <= howMany; i++)
    {
        CGContextMoveToPoint(context, kOffsetX + i * kStepX, 0);
        CGContextAddLineToPoint(context, kOffsetX + i * kStepX, self.bounds.size.height);
    }
    
    int howManyHorizontal = (self.bounds.size.height - kOffsetY) / kStepY;
    for (int i = 0; i <= howManyHorizontal; i++)
    {
        CGContextMoveToPoint(context, kOffsetX, self.bounds.size.height - kOffsetY - i * kStepY);
        CGContextAddLineToPoint(context, self.bounds.size.width, self.bounds.size.height - kOffsetY - i * kStepY);
    }
    CGFloat dash[] = {2.0, 2.0};
    CGContextSetLineDash(context, 0.0, dash, 2);
    CGContextStrokePath(context);

     CGContextSetLineDash(context, 0, NULL, 0); // Remove the dash
    
    [self  drawLineGraphWithContext: context];
}

@end
