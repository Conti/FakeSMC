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


@interface sgModel : NSObject {
    
    sgFan * _currentFan;
    
}

@property (readwrite,retain) NSMutableDictionary *   fans; 
@property (readwrite,assign) sgFan  * currentFan;


+(NSUInteger) whoDiffersFor:(NSArray *) current andPrevious:(NSArray *) previous andMaxDev:(NSUInteger) maxDev;;

-(sgModel *) init;
-(sgFan *) initialPrepareFan: (NSUInteger) fanId;

-(void) setCurrentFan:(sgFan *)CurrentFan;
-(sgFan *)  currentFan;

-(void) saveSettings;
-(BOOL) readSettings;
-(BOOL) addFan: (sgFan *) desc withName: (NSString *) name;
-(BOOL) calibrateFan:(NSString *) fanId;
-(void) findControllers;
-(BOOL) selectCurrentFan: (NSString *) name; 
@end
