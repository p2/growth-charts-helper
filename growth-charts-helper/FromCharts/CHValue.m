//
//  CHValue.m
//  Charts
//
//  Created by Pascal Pfiffner on 4/13/12.
//  Copyright (c) 2012 Children's Hospital Boston. All rights reserved.
//

#import "CHValue.h"
#import "CHUnit.h"


@implementation CHValue


+ (id)newWithNumber:(NSDecimalNumber *)number inUnit:(CHUnit *)unit
{
	CHValue *value = [self new];
	value.number = number;
	value.unit = unit;
	
	return value;
}



#pragma mark - Properties
/**
 *  Checks whether the measurement seems physiologically plausible; 0 is plausible, -1 too low and 1 too high.
 */
- (NSInteger)checkPlausibility
{
	if (!_number || !_unit) {
		return 0;
	}
	
	return [_unit checkPlausibilityOfNumber:_number];
}

/**
 *  Returns YES if we don't have a number assigned, but *not* if we are zero (!).
 */
- (BOOL)isNull
{
	return (nil == _number);
}



#pragma mark - Conversion
- (BOOL)convertToUnit:(CHUnit *)aUnit
{
	NSDecimalNumber *newNumber = (_unit && aUnit) ? [_unit convertNumber:_number toUnit:aUnit] : _number;
	if (_number && !newNumber) {
		return NO;
	}
	
	self.number = newNumber;
	self.unit = aUnit;
	
	return YES;
}

/**
 *  @return A copy of the receiver, converted to the given unit
 */
- (CHValue *)valueInUnit:(CHUnit *)aUnit
{
	NSDecimalNumber *newNumber = (_unit && aUnit) ? [_unit convertNumber:_number toUnit:aUnit] : _number;
	if (_number && !newNumber) {
		return nil;
	}
	
	return [[self class] newWithNumber:newNumber inUnit:aUnit];
}

- (CHValue *)valueInUnitWithName:(NSString *)unitName
{
	CHUnit *otherUnit = [CHUnit newWithPath:[NSString stringWithFormat:@"%@.%@", _unit.dimension, unitName]];
	return [self valueInUnit:otherUnit];
}

/**
 *  @return A number in the given unit, calculated from the receiver's number and unit
 */
- (NSDecimalNumber *)numberInUnit:(CHUnit *)aUnit
{
	return [_unit convertNumber:_number toUnit:aUnit];
}

- (NSDecimalNumber *)numberInUnitWithName:(NSString *)unitName
{
	CHUnit *otherUnit = [CHUnit newWithPath:[NSString stringWithFormat:@"%@.%@", _unit.dimension, unitName]];
	return [_unit convertNumber:_number toUnit:otherUnit];
}



#pragma mark - Stringify
/**
 *  Return the value as a formatted string value.
 *
 *  This method assumes the CHValueStringSizeSmall size
 */
- (NSString *)stringValue
{
	return [self stringValueWithSize:CHValueStringSizeSmall];
}

/**
 *  Return the value as a formatted string value.
 */
- (NSString *)stringValueWithSize:(CHValueStringSize)size
{
	if (_unit) {
		return [_unit stringValueForNumber:_number withSize:size];
	}
	return _number ? [_number stringValue] : @"";
}



#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
	return [[self class] newWithNumber:_number inUnit:_unit];
}



#pragma mark - JSON
+ (id)newFromJSONObject:(id)object
{
	CHValue *val = [self new];
	if ([val setFromJSONObject:object]) {
		return val;
	}
	return nil;
}

- (BOOL)setFromJSONObject:(id)obj
{
	if ([obj isKindOfClass:[NSDictionary class]]) {
		NSString *number = [obj objectForKey:@"number"];
		if ([number isKindOfClass:[NSString class]]) {
			self.number = [NSDecimalNumber decimalNumberWithString:number];
		}
		else if ([number respondsToSelector:@selector(description)]) {
			self.number = [NSDecimalNumber decimalNumberWithString:[number description]];
		}
		
		NSString *unit = [obj objectForKey:@"unit"];
		if ([unit isKindOfClass:[NSString class]]) {
			self.unit = [CHUnit newWithPath:unit];
		}
		return YES;
	}
	return NO;
}

- (id)jsonObject
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	if (_number) {
		[dict setObject:[_number description] forKey:@"number"];		// yes, we want the number as string
	}
	if (_unit) {
		[dict setObject:[_unit jsonObject] forKey:@"unit"];
	}
	
	return dict;
}



#pragma mark - Utilities
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <%p> %@ %@", NSStringFromClass([self class]), self, _number, _unit.name];
}


@end
