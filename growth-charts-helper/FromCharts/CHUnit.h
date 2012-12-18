//
//  CHUnit.h
//  Charts
//
//  Created by Pascal Pfiffner on 4/13/12.
//  Copyright (c) 2012 Children's Hospital Boston. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHJSONHandling.h"
#import "CHTypes.h"


/**
 *	Representing a unit such as "meter" or "feet"
 */
@interface CHUnit : NSObject <NSCopying, CHJSONHandling>

@property (nonatomic, copy) NSString *dimension;					///< The dimension of the unit, e.g. "length"
@property (nonatomic, copy) NSString *name;							///< The unique name of the unit within the dimension, e.g. "meter"
@property (nonatomic, copy) NSString *label;						///< The label for the unit, e.g. "cm" for centimeter

@property (nonatomic, assign) short precision;						///< The default precision to round to, 2 by default
@property (nonatomic, strong) NSDecimalNumber *baseMultiplier;		///< How to convert to base unit
@property (nonatomic, assign) BOOL isBaseUnit;

+ (NSArray *)unitsOfDimension:(NSString *)dimension baseUnit:(CHUnit * __autoreleasing *)defaultUnit;

+ (id)newWithPath:(NSString *)aPath;
- (NSString *)path;

- (NSString *)stringValueForNumber:(NSDecimalNumber *)number;
- (NSString *)stringValueForNumber:(NSDecimalNumber *)number withSize:(CHValueStringSize)size;

- (NSDecimalNumber *)numberInBaseUnit:(NSDecimalNumber *)number;
- (NSDecimalNumber *)convertNumber:(NSDecimalNumber *)number toUnit:(CHUnit *)unit;
- (NSDecimalNumber *)roundedNumber:(NSDecimalNumber *)number;

- (BOOL)isSameDimension:(CHUnit *)otherUnit;

+ (NSDictionary *)dictionaryForDimension:(NSString *)dimension;
+ (Class)classForDimension:(NSString *)dimension;

+ (id)defaultUnitForDataType:(NSString *)measurementType;


@end
