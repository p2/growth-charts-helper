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
 *  Returns the string value for a number and the unit label in the receiver's unit.
 *
 *  This method calls stringValueForNumber:withSize: with "CHValueStringSizeSmall" as parameter.
 */
- (NSString *)stringValueForNumber:(NSDecimalNumber *)number
{
	return [self stringValueForNumber:number withSize:CHValueStringSizeSmall];
}

/**
 *  Returns the string value for a number and the unit label in the receiver's unit, with the given size.
 *
 *  Subclasses should override this method.
 */
- (NSString *)stringValueForNumber:(NSDecimalNumber *)number withSize:(CHValueStringSize)size
{
	if (!number) {
		return nil;
	}
	
	if (CHValueStringSizeCompact == size) {
		return [NSString stringWithFormat:@"%@%@", [self roundedNumber:number], (_label ? _label : @"")];
	}
	if (CHValueStringSizeLong == size) {
		return [NSString stringWithFormat:@"%@ %@", [self roundedNumber:number], (_name ? _name : (_label ? _label : @""))];
	}
	
	return [NSString stringWithFormat:@"%@ %@", [self roundedNumber:number], (_label ? _label : @"")];
}

/**
 *  Returns the string value for a number in the receiver's unit, but the number only.
 */
- (NSString *)stringValueForNumberOnly:(NSDecimalNumber *)number
{
	return [[self roundedNumber:number] description];
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
 *  Assumes that number is in the receivers unit and converts it to the given unit.
 */
- (NSDecimalNumber *)convertNumber:(NSDecimalNumber *)number toUnit:(CHUnit *)unit
{
	// no unit or same unit anyway?
	if (!unit || [self isEqual:unit]) {
		return number;
	}
	
	// must be same dimension
	if (![self isSameDimension:unit]) {
		DLog(@"I can not convert to a unit from another dimension (%@ -> %@)", self.dimension, unit.dimension);
		return nil;
	}
	
	// convert
	return [unit numberFromBaseUnit:[self numberInBaseUnit:number]];
}

/**
 *  Rounds the number according to the unit's information.
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



#pragma mark - Plausibility Testing
/**
 *  Checks whether a number in the receiver's unit physiologically makes sense.
 */
- (NSInteger)checkPlausibilityOfNumber:(NSDecimalNumber *)number
{
	if (!number || [number isEqual:[NSDecimalNumber notANumber]]) {
		return 0;
	}
	
	if (_plausibleMin && NSOrderedAscending == [number compare:_plausibleMin]) {
		return -1;
	}
	if (_plausibleMax && NSOrderedDescending == [number compare:_plausibleMax]) {
		return 1;
	}
	return 0;
}

- (void)setMinPlausibleFromBaseUnit:(NSString *)numString
{
	if ([numString length] < 1) {
		return;
	}
	if (!_isBaseUnit && !_baseMultiplier) {
		DLog(@"I need to know the base unit first");
		return;
	}
	
	NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:numString];
	self.plausibleMin = [self numberFromBaseUnit:number];
}

- (void)setMaxPlausibleFromBaseUnit:(NSString *)numString
{
	if ([numString length] < 1) {
		return;
	}
	if (!_isBaseUnit && !_baseMultiplier) {
		DLog(@"I need to know the base unit first");
		return;
	}
	
	NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:numString];
	self.plausibleMax = [self numberFromBaseUnit:number];
}



#pragma mark - Unit Loading
/**
 *  You really should use this method to create new unit instances!
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
				NSString *plausMin = [dimDict objectForKey:@"plausible-min"];
				NSString *plausMax = [dimDict objectForKey:@"plausible-max"];
				
				// find the respective dictionary in the dimension's dictionary
				Class class = [self classForDimension:dimension];
				NSDictionary *dict = nil;
				for (NSDictionary *unitDict in [dimDict objectForKey:@"units"]) {
					if ([name isEqualToString:[unitDict objectForKey:@"name"]]) {
						dict = unitDict;
						break;
					}
				}
				
				// instantiate
				CHUnit *unit = [class newFromDictionary:dict withName:name inDimension:dimension];
				if (!unit) {
					DLog(@"Could not instantiate a unit for \"%@\"", aPath);
				}
				
				// set dimension properties
				unit.isBaseUnit = [baseName isEqualToString:name];
				[unit setMinPlausibleFromBaseUnit:plausMin];
				[unit setMaxPlausibleFromBaseUnit:plausMax];
				
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
	else if (aPath) {
		DLog(@"Failed to instantiate from path \"%@\", which should be in the form \"dimension.unitname\"", aPath);
	}
	
	return nil;
}

/**
 *  Creates a new instance with the properties found in the dictionary.
 */
+ (id)newFromDictionary:(NSDictionary *)dict withName:(NSString *)name inDimension:(NSString *)dimension
{
	if (!dimension && (!dict || !name)) {
		return nil;
	}
	
	CHUnit *unit = [self new];
	unit.dimension = dimension;
	unit.name = ([name length] > 0) ? name : [dict objectForKey:@"name"];
	unit.label = [dict objectForKey:@"label"];
	unit.baseMultiplier = [dict objectForKey:@"baseMultiplier"] ? [NSDecimalNumber decimalNumberWithString:[dict objectForKey:@"baseMultiplier"]] : nil;
	NSNumber *precision = [dict objectForKey:@"precision"];
	if (precision) {
		unit.precision = [precision shortValue];
	}
	
	return unit;
}


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
			NSString *plausMin = [dimDict objectForKey:@"plausible-min"];
			NSString *plausMax = [dimDict objectForKey:@"plausible-max"];
			NSArray *units = [dimDict objectForKey:@"units"];
			NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[units count]];
			
			// loop the dimension
			for (NSDictionary *dict in units) {
				CHUnit *unit = [class newFromDictionary:dict withName:nil inDimension:dimension];
				if (unit) {
					[arr addObject:unit];
					
					// default?
					unit.isBaseUnit = [baseName isEqualToString:unit.name];
					if (unit.isBaseUnit && NULL != defaultUnit) {
						*defaultUnit = unit;
					}
					
					[unit setMinPlausibleFromBaseUnit:plausMin];
					[unit setMaxPlausibleFromBaseUnit:plausMax];
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

/**
 *  Returns the appropriate units from the appropriate dimension for a given data type.
 *  @todo Hardcoded, should move to plist
 */
+ (NSArray *)unitsForDataType:(NSString *)dataType
{
	if ([@"bodyweight" isEqualToString:dataType]) {
		return [self unitsOfDimension:@"weight" baseUnit:nil];
	}
	if ([@"bodylength" isEqualToString:dataType]) {
		return [self unitsOfDimension:@"length" baseUnit:nil];
	}
	if ([@"headcircumference" isEqualToString:dataType]) {
		NSMutableArray *lengthUnits = [[self unitsOfDimension:@"length" baseUnit:nil] mutableCopy];
		CHUnit *meterUnit = nil;
		for (CHUnit *unit in lengthUnits) {
			if ([@"meter" isEqualToString:unit.name]) {
				meterUnit = unit;
				break;
			}
		}
		[lengthUnits removeObject:meterUnit];
		return lengthUnits;
	}
	if ([@"age" isEqualToString:dataType]) {
		return [self unitsOfDimension:@"age" baseUnit:nil];
	}
	if ([@"bmi" isEqualToString:dataType]) {
		return [self unitsOfDimension:@"bmi" baseUnit:nil];
	}
	
	DLog(@"No data type or none that we understand: %@", dataType);
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
 *  Assumes default units for some measurement types, e.g. "length.centimeter" for "bodylength"
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
	if ([@"bmi" isEqualToString:measurementType]) {
		return [self newWithPath:@"bmi.kilogram-per-square-meter"];
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
