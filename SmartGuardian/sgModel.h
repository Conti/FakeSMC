//
//  sgModel.h
//  HWSensors
//
//  Created by Navi on 22.02.12.
//  Copyright (c) 2012 . All rights reserved.
//

#import <Foundation/Foundation.h>
#include "FakeSMCDefinitions.h"
#import "sgFan.h"

#define SpinTransactionTime 3.0
#define SpinTime  7.0


@interface sgModel : NSObject 

@property (readwrite,retain) NSMutableDictionary *   fans; 
@property (readwrite,retain) sgFan  * CurrentFan;


+(NSUInteger) whoDiffersFor:(NSArray *) current andPrevious:(NSArray *) previous andMaxDev:(NSUInteger) maxDev;;

-(sgModel *) init;
-(NSDictionary *) initialPrepareFan: (NSUInteger) fanId;

-(BOOL) writeFanDictionatyToFile: (NSString *) filename;
-(BOOL) readFanDictionatyFromFile: (NSString *) filename;
-(BOOL) addFan: (NSDictionary *) desc withName: (NSString *) name;
-(BOOL) calibrateFan:(NSString *) fanId;
-(void) findControllers;
-(BOOL) selectCurrentFan: (NSString *) name; 
@end
