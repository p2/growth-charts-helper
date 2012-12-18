//
//  CHUnit.m
//  Charts
//
//  Created by Pascal Pfiffner on 4/13/12.
//  Copyright (c) 2012 Children's Hospital Boston. All rights reserved.
//

#import "CHUnit.h"
#import "CHDateUnit.h"


@implementation CHUnit


/**
 *	You really should use this method to create new unit instances!
 *  @param aPath The unit path in the form "dimension.unitname"
 */
+ (id)newWithPath:(NSString *)aPath
{
	NSArray *parts = [aPath componentsSeparatedByString:@"."];
	if (2 == [parts count]) {
		NSString *dimension = [parts objectAtIndex:0];
		NSString *name = [parts objectAtIndex:1];
		
		// instantiate the correct class
		NSDictionary *dimDict = [self dictionaryForDimension:dimension];
		if (dimDict) {
			NSString *baseName = [dimDict objectForKey:@"base"];
			if ([baseName length] > 0) {
				
				// instantiate
				Class class = [self classForDimension:dimension];
				NSDictionary *dict = nil;
				for (NSDictionary *unitDict in [dimDict objectForKey:@"units"]) {
					if ([name isEqualToString:[unitDict objectForKey:@"name"]]) {
						dict = unitDict;
						break;
					}
				}
				
				CHUnit *unit = [class new];
				unit.dimension = dimension;
				unit.name = name;
				unit.label = [dict objectForKey:@"label"];
				unit.baseMultiplier = [dict objectForKey:@"baseMultiplier"] ? [NSDecimalNumber decimalNumberWithString:[dict objectForKey:@"baseMultiplier"]] : nil;
				unit.isBaseUnit = [baseName isEqualToString:name];
				
				return unit;
			}
			else {
				DLog(@"There is no base unit for dimension %@", dimension);
			}
		}
		else {
			DLog(@"There is no definition of the dimension \"%@\" in units.plist", dimension);
		}
	}
	else {
		DLog(@"Failed to instantiate from path \"%@\", which should be in the form \"dimension.unitname\"", aPath);
	}
	
	return nil;
}

/**
 *  This is the designated initializer.
 */
- (id)init
{
	if ((self = [super init])) {
		_precision = 2;
	}
	return self;
}



#pragma mark - JSON
+ (id)newFromJSONObject:(id)object
{
	if ([object isKindOfClass:[NSString class]]) {
		return [self newWithPath:object];
	}
	return nil;
}

- (BOOL)setFromJSONObject:(id)object
{
	if ([object isKindOfClass:[NSString class]]) {
		NSArray *parts = [object componentsSeparatedByString:@"."];
		if (2 == [parts count]) {
			self.dimension = [parts objectAtIndex:0];
			self.name = [parts objectAtIndex:1];
			
			return YES;
		}
	}
	DLog(@"Can only use strings with the format \"dimension.name\", but got \"%@\"", object);
	return NO;
}

- (id)jsonObject
{
	return [NSString stringWithFormat:@"%@.%@", (_dimension ? _dimension : @""), (_name ? _name : @"")];
}



#pragma mark - String Value
/**
 *  Returns the string value for a number in the receiver's unit.
 *
 *  This method calls stringValueForNumber:withSize: with "CHValueStringSizeSmall" as parameter.
 */
- (NSString *)stringValueForNumber:(NSDecimalNumber *)number
{
	return [self stringValueForNumber:number withSize:CHValueStringSizeSmall];
}

/**
 *  Returns the string value for a number in the receiver's unit, with the given size.
 *
 *  Subclasses should override this method.
 */
- (NSString *)stringValueForNumber:(NSDecimalNumber *)number withSize:(CHValueStringSize)size
{
	if (CHValueStringSizeCompact == size) {
		return [NSString stringWithFormat:@"%@%@", [self roundedNumber:number], (_label ? _label : @"")];
	}
	if (CHValueStringSizeLong == size) {
		return [NSString stringWithFormat:@"%@ %@", [self roundedNumber:number], (_name ? _name : (_label ? _label : @""))];
	}
	
	return [NSString stringWithFormat:@"%@ %@", [self roundedNumber:number], (_label ? _label : @"")];
}



#pragma mark - Conversion
/**
 *  Convert the number from the receiver's unit to the unit dimension's base unit.
 *  @param number A number in the receiver's unit
 */
- (NSDecimalNumber *)numberInBaseUnit:(NSDecimalNumber *)number
{
	if (_isBaseUnit) {
		return number;
	}
	if (_baseMultiplier) {
		return [number decimalNumberByMultiplyingBy:_baseMultiplier];
	}
	
	DLog(@"I need the base multiplier in order to convert a number to base unit, but I don't have one. %@", self);
	return number;
}

/**
 *  Convert the number from the base unit to the receiver's unit.
 *  @param number A number in the base unit
 */
- (NSDecimalNumber *)numberFromBaseUnit:(NSDecimalNumber *)number
{
	if (_isBaseUnit) {
		return number;
	}
	if (_baseMultiplier) {
		return [number decimalNumberByDividingBy:_baseMultiplier];
	}
	
	DLog(@"I need the base multiplier in order to convert a number from base unit, but I don't have one. %@", self);
	return number;
}

/**
 *	Assumes that number is in the receivers unit and converts it to the given unit
 *	TODO: Implement
 */
- (NSDecimalNumber *)convertNumber:(NSDecimalNumber *)number toUnit:(CHUnit *)unit
{
	if (![self isSameDimension:unit]) {
		DLog(@"I can not convert to a unit from another dimension (%@ -> %@)", self.dimension, unit.dimension);
		return nil;
	}
	
	// convert
	return [unit numberFromBaseUnit:[self numberInBaseUnit:number]];
}

/**
 *	Rounds the number according to the unit's information
 */
- (NSDecimalNumber *)roundedNumber:(NSDecimalNumber *)number
{
	if (number) {
		NSDecimalNumberHandler *roundingBehavior = [[NSDecimalNumberHandler alloc] initWithRoundingMode:NSRoundPlain
																								  scale:_precision
																					   raiseOnExactness:NO
																						raiseOnOverflow:NO
																					   raiseOnUnderflow:NO
																					raiseOnDivideByZero:NO];
		return [number decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
	}
	return nil;
}



#pragma mark - Unit Loading
/**
 *  Returns an array of all units for a given dimension.
 *  @param dimension The name of the dimension
 *  @param defaultUnit A pointer that will be filled with the default unit
 */
+ (NSArray *)unitsOfDimension:(NSString *)dimension baseUnit:(CHUnit * __autoreleasing *)defaultUnit
{
	NSDictionary *dimDict = [self dictionaryForDimension:dimension];
	if (dimDict) {
		Class class = [self classForDimension:dimension];
		NSString *baseName = [dimDict objectForKey:@"base"];
		if ([baseName length] > 0) {
			NSArray *units = [dimDict objectForKey:@"units"];
			NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[units count]];
			
			// loop the dimension
			for (NSDictionary *dict in units) {
				CHUnit *unit = [class new];
				unit.dimension = dimension;
				unit.name = [dict objectForKey:@"name"];
				unit.label = [dict objectForKey:@"label"];
				unit.baseMultiplier = [dict objectForKey:@"baseMultiplier"] ? [NSDecimalNumber decimalNumberWithString:[dict objectForKey:@"baseMultiplier"]] : nil;
				unit.isBaseUnit = [baseName isEqualToString:unit.name];
				
				[arr addObject:unit];
				
				// default?
				if (unit.isBaseUnit && NULL != defaultUnit) {
					*defaultUnit = unit;
				}
			}
			
			return arr;
		}
		
		DLog(@"There is no base unit for dimension %@", dimension);
	}
	else {
		DLog(@"There is no definition of the dimension \"%@\" in units.plist", dimension);
	}
	
	return nil;
}


+ (NSDictionary *)dictionaryForDimension:(NSString *)dimension
{
	if ([dimension length] > 0) {
		NSDictionary *all = [self allUnitsDict];
		return [all objectForKey:dimension];
	}
	return nil;
}

+ (NSDictionary *)allUnitsDict
{
	static NSDictionary *allUnitsDict = nil;
	if (!allUnitsDict) {
		NSURL *url = [[NSBundle bundleForClass:self] URLForResource:@"units" withExtension:@"plist"];
		allUnitsDict = [NSDictionary dictionaryWithContentsOfURL:url];
	}
	return allUnitsDict;
}

+ (Class)classForDimension:(NSString *)dimension
{
	if ([@"age" isEqualToString:dimension]) {
		return [CHDateUnit class];
	}
	return self;
}


/**
 *	Assumes default units for some measurement types, e.g. "length.centimeter" for "bodylength"
 */
+ (id)defaultUnitForDataType:(NSString *)measurementType
{
	if ([@"bodylength" isEqualToString:measurementType] || [@"headcircumference" isEqualToString:measurementType]) {
		return [self newWithPath:@"length.centimeter"];
	}
	if ([@"bodyweight" isEqualToString:measurementType]) {
		return [self newWithPath:@"weight.kilogram"];
	}
	if ([@"age" isEqualToString:measurementType]) {
		return [self newWithPath:@"age.second"];
	}
	
	DLog(@"There is no default unit for \"%@\", returning an empty unit", measurementType);
	return [self new];
}



#pragma mark - Comparison
- (NSString *)path
{
	return [NSString stringWithFormat:@"%@.%@", (_dimension ? _dimension : @""), (_name ? _name : @"")];
}

- (BOOL)isEqual:(id)object
{
	if (object == self) {
		return YES;
	}
	
	if ([object isKindOfClass:[self class]]) {
		CHUnit *other = (CHUnit *)object;
		return ([_dimension isEqualToString:other.dimension] && [_name isEqualToString:other.name]);
	}
	return NO;
}

- (NSUInteger)hash
{
	return [[self path] hash];
}



#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
	CHUnit *newUnit = [[self class] new];
	newUnit.dimension = _dimension;
	newUnit.name = _name;
	newUnit.label = _label;
	newUnit.precision = _precision;
	newUnit.baseMultiplier = _baseMultiplier;
	newUnit.isBaseUnit = _isBaseUnit;
	
	return newUnit;
}



#pragma mark - Utilities
- (BOOL)isSameDimension:(CHUnit *)otherUnit
{
	return [_dimension isEqualToString:otherUnit.dimension];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <%p> %@ %@", NSStringFromClass([self class]), self, _dimension, _name];
}


@end
