//
//  Encounter.h
//  Infected
//
//  Created by Matt Schulte on 4/22/15.
//
//

#import <Foundation/Foundation.h>

@interface Encounter : NSObject

@property NSDate *time;
@property NSNumber *rssi;
@property NSNumber *uuid;

@end
