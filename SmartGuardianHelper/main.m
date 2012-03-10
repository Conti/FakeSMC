//
//  main.m
//  SmartGuardianHelper
//
//  Created by Иван Синицин on 10.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "sgFan.h"

int main(int argc, char *argv[])
{

    @autoreleasepool {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        [defaults addSuiteNamed:@"Navi.SmartGuardian"];
        NSMutableDictionary * temp = [NSMutableDictionary dictionaryWithDictionary: [defaults dictionaryForKey:@"Configuration"] ];
        
        if(temp)
        {
            [temp enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                
                if([key hasPrefix:@"FAN"])
                {
                    obj = [[sgFan alloc] initWithKeys:obj];
                }
                
          
                
            }];
            
        }

        
    }
    
}
