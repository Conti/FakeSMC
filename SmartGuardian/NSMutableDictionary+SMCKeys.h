//
//  NSMutableDictionary+SMCKeys.h
//  HWSensors
//
//  Created by Иван Синицин on 01.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sgModel.h"

@interface NSMutableDictionary (SMCKeys)

- (id)valueForKey:(NSString *)key;

@end
