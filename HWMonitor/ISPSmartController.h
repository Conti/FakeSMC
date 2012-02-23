//
//  ISPSmartController.h
//  iStatPro
//
//  Created by Buffy on 11/06/07.
//  Copyright 2007 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <sys/param.h>
#include <sys/mount.h>


#define kATADefaultSectorSize 512
#define kWindowSMARTsDriveTempAttribute 0xC2
#define kWindowSMARTsDriveTempAttribute2    0xE7
#define kSMARTAttributeCount 30

@interface ISPSmartController : NSObject {
	NSMutableArray *diskData;
	NSMutableArray *latestData;
	NSArray *temps;
	NSArray *disksStatus;
	NSMutableDictionary *partitionData;
}
-(void)getPartitions;
- (void)update;
- (NSDictionary *)getDataSet:(int)degrees;
@end
