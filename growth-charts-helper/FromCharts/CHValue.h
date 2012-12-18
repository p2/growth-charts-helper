//
//  CHValue.h
//  Charts
//
//  Created by Pascal Pfiffner on 4/13/12.
//  Copyright (c) 2012 Children's Hospital Boston. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHTypes.h"
#import "CHJSONHandling.h"

@class CHUnit;


/**
 *	A value has a numerical value and a unit
 */
@interface CHValue : NSObject <NSCopying, CHJSONHandling>

@property (nonatomic, strong) NSDecimalNumber *number;				///< The numeric value
@property (nonatomic, strong) CHUnit *unit;							///< The unit

+ (id)newWithNumber:(NSDecimalNumber *)number inUnit:(CHUnit *)unit;

- (BOOL)convertToUnit:(CHUnit *)aUnit;

- (NSDecimalNumber *)numberInUnit:(CHUnit *)aUnit;
- (NSDecimalNumber *)numberInUnitWithName:(NSString *)unitName;

- (NSString *)stringValue;
- (NSString *)stringValueWithSize:(CHValueStringSize)size;

- (BOOL)isNull;


@end
