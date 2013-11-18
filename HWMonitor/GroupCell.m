//
//  HWMonitorGroupCell.m
//  HWSensors
//
//  Created by kozlek on 22.02.13.
//
//

#import "GroupCell.h"

@implementation GroupCell

-(void)setColorTheme:(ColorTheme *)colorTheme
{
    _colorTheme = colorTheme;
    
    _gradient = [[NSGradient alloc] initWithStartingColor:_colorTheme.groupStartColor
                                              endingColor:_colorTheme.groupEndColor];
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (!_gradient) {
        _gradient = [[NSGradient alloc] initWithStartingColor:_colorTheme.groupStartColor
                                                  endingColor:_colorTheme.groupEndColor];
    }
    
    NSRect contentRect = [self bounds];
    
    [_gradient drawInRect:NSMakeRect(contentRect.origin.x + 1.0, contentRect.origin.y, contentRect.size.width - 2.0, contentRect.size.height) angle:270];
}

@end
