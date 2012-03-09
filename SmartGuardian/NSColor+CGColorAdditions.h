//
//  NSColor+CGColorAdditions.h
//  HWSensors
//
//  Created by Navi on 28.02.12.
//  Copyright (c) 2012 Navi. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

/**
 NSColor category for converting NSColor<-->CGColor
 */

@interface NSColor (CGColorAdditions)

/**
 Return CGColor representation of the NSColor in the RGB color space
 */
@property (readonly) CGColorRef CGColor;
/**
 Create new NSColor from a CGColorRef
 */
+ (NSColor*)colorWithCGColor:(CGColorRef)aColor;
@end
