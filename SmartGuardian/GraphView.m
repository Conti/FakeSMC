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
#define kOffsetY 20


@implementation GraphView

@synthesize VerticalMarks;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(NSDictionary *) PlotData
{
    return _PlotData;
}

-(void) setPlotData:(NSDictionary *)PlotData
{
    _PlotData = PlotData;

    [self setNeedsDisplay:YES];
}


-(void) drawVerticalMarksWithContext:(CGContextRef)ctx
{
    if([VerticalMarks count]>0)
    {
        [VerticalMarks enumerateKeysAndObjectsUsingBlock:^(id key,id obj, BOOL *stop) {
            
            NSColor * DrawColor = [obj objectForKey:@"Color"];
            NSNumber * data = [obj objectForKey:@"Data"];
            NSString * legend = [obj objectForKey:@"Legend"];

            CGContextSetLineWidth(ctx, 2.0);
            
            CGContextSetStrokeColorWithColor(ctx, [DrawColor CGColor]);
            int maxGraphHeight = self.bounds.size.height - kOffsetY;
            CGContextBeginPath(ctx);
            CGContextMoveToPoint(ctx, kOffsetX + var*[data intValue],  kOffsetY);
            
            CGContextAddLineToPoint(ctx, kOffsetX + var*[data intValue] , kOffsetY+ maxGraphHeight);
            CGFloat dash[] = {3.0, 2.0};
            CGContextSetLineDash(ctx, 0.0, dash, 2);
            //        CGContextAddLineToPoint(ctx, self.bounds.size.width,  0);
            //        CGContextClosePath(ctx);
            CGContextDrawPath(ctx, kCGPathStroke);
            CGContextSetLineDash(ctx, 0, NULL, 0); // Remove the dash
            
            
        }];
    }

    
}


- (void)drawLineGraphWithContext:(CGContextRef)ctx
{
    if([_PlotData count]>0)
        
    {
       [_PlotData enumerateKeysAndObjectsUsingBlock:^(id key,id obj, BOOL *stop) {
           
        __block float denominator=1.0;
           NSColor * DrawColor = [obj objectForKey:@"Color"];
           NSArray * data = [obj objectForKey:@"Data"];
           NSNumber * scale = [obj objectForKey:@"Scale"];
           NSString * legend = [obj objectForKey:@"Legend"];
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
         CGContextMoveToPoint(ctx, kOffsetX,  kOffsetY+maxGraphHeight * [[data objectAtIndex:0] floatValue]/denominator);
       
       
//        float var = self.bounds.size.width / ([data count] - 1); 
        for (int i = 1; i < [data count]; i++)
        {
            CGContextAddLineToPoint(ctx, kOffsetX + i * var , kOffsetY+ maxGraphHeight * [[data objectAtIndex:i] floatValue]/denominator);
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
    var = 0;
    [_PlotData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSArray * data = [obj objectForKey:@"Data"];
        if([data count]>1)
            var = self.bounds.size.width / ([data count] - 1);
    }];
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    

    
    CGContextSetLineWidth(context, 0.6);
    CGContextSetStrokeColorWithColor(context, [[NSColor lightGrayColor] CGColor]);
   
  
    
    // How many lines?
    int howMany = (self.bounds.size.width - kOffsetX) / kStepX;
    // Here the lines go
    for (int i = 0; i <= howMany; i++)
    {
        CGContextMoveToPoint(context, kOffsetX + i * kStepX, kOffsetY);
        CGContextAddLineToPoint(context, kOffsetX + i * kStepX, self.bounds.size.height);
    }
    
    int howManyHorizontal = (self.bounds.size.height - kOffsetY) / kStepY;
    for (int i = 0; i <= howManyHorizontal; i++)
    {
        CGContextMoveToPoint(context, kOffsetX, kOffsetY + i * kStepY);
        CGContextAddLineToPoint(context, self.bounds.size.width, kOffsetY + i * kStepY);
    }
    CGFloat dash[] = {2.0, 2.0};
    CGContextSetLineDash(context, 0.0, dash, 2);
    CGContextStrokePath(context);

     CGContextSetLineDash(context, 0, NULL, 0); // Remove the dash
    

    [self drawVerticalMarksWithContext:context];

    [self  drawLineGraphWithContext: context];
    
    CGContextSetStrokeColorWithColor(context, [[NSColor blackColor] CGColor]);
    CGContextSetLineWidth(context, 2.0);
    CGContextMoveToPoint(context, kOffsetX, kOffsetY);
    CGContextAddLineToPoint(context, kOffsetX, self.bounds.size.height);
    CGContextMoveToPoint(context, kOffsetX, kOffsetY);
    CGContextAddLineToPoint(context, self.bounds.size.width, kOffsetY);
    CGContextStrokePath(context);
}

@end
