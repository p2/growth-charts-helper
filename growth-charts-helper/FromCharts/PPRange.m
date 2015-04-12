//
//  PPRange.m
//  RenalApp
//
//  Created by Pascal Pfiffner on 13.10.09.
//  Copyright 2009 Pascal Pfiffner. All rights reserved.
//

#import "PPRange.h"


@implementation PPRange

@synthesize stringValue = _stringValue;


- (instancetype)init
{
	if ((self = [super init])) {
		_includingFrom = YES;
		_includingTo = YES;
	}
	return self;
}

+ (PPRange *)rangeWithString:(NSString *)string
{
	if ([string length] > 0) {
		return [[self alloc] initWithString:string];
	}
	return nil;
}

+ (PPRange *)rangeFrom:(NSDecimalNumber *)min to:(NSDecimalNumber *)max
{
	if (min || max) {
		PPRange *r = [self new];
		r.from = min;
		r.to = max;
		return r;
	}
	return nil;
}

/**
 *  Creates NSDecimalNumber instances from min and max string and creates a range with these limits
 */
+ (PPRange *)rangeFromString:(NSString *)min toString:(NSString *)max
{
	return [PPRange rangeFrom:(min ? [NSDecimalNumber decimalNumberWithString:min] : nil)
						   to:(max ? [NSDecimalNumber decimalNumberWithString:max] : nil)];
}

/**
 *  Initialize the range from limits given in the string
 */
- (instancetype)initWithString:(NSString *)string
{
	if ((self = [super init])) {
		self.stringValue = string;
	}
	return self;
}



#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
	PPRange *newRange = [[[self class] allocWithZone:zone] init];
	newRange->_from = [_from copyWithZone:zone];
	newRange->_to = [_to copyWithZone:zone];
	newRange->_includingFrom = _includingFrom;
	newRange->_includingTo = _includingTo;
	
	return newRange;
}

- (PPRange *)copyWithCustomFrom:(NSDecimalNumber *)min to:(NSDecimalNumber *)max
{
	PPRange *newRange = [[self class] new];
	newRange->_from = min ? [min copy] : [_from copy];
	newRange->_to = max ? [max copy] : [_to copy];
	newRange->_includingFrom = _includingFrom;
	newRange->_includingTo = _includingTo;
	
	return newRange;
}



#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:_from forKey:@"from"];
	[encoder encodeObject:_to forKey:@"to"];
	[encoder encodeBool:_includingFrom forKey:@"includingFrom"];
	[encoder encodeBool:_includingTo forKey:@"includingTo"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super init])) {
		self.from = [decoder decodeObjectForKey:@"from"];
		self.to = [decoder decodeObjectForKey:@"to"];
		self.includingFrom = [decoder decodeBoolForKey:@"includingFrom"];
		self.includingTo = [decoder decodeBoolForKey:@"includingTo"];
	}
	return self;
}



#pragma mark - Tests
/**
 *  Checks whether a given number falls into our range
 */
- (BOOL)contains:(NSNumber *)test
{
	return (PPRangeResultOK == [self test:test]);
}

/**
 *  Tests whether a ginen number falls into our range
 */
- (PPRangeResult)test:(NSNumber *)test
{
	if (!test) {
		return PPRangeResultUndefined;
	}
	
	// check lower bounds
	if (_from) {
		NSComparisonResult lowerTest = [_from compare:test];
		if ((NSOrderedDescending == lowerTest) || (NSOrderedSame == lowerTest && !_includingFrom)) {
			return PPRangeResultTooLow;
		}
	}
	
	// check upper bounds
	if (_to) {
		NSComparisonResult upperTest = [_to compare:test];
		if ((NSOrderedAscending == upperTest) || (NSOrderedSame == upperTest && !_includingTo)) {
			return PPRangeResultTooHigh;
		}
	}
	
	return PPRangeResultOK;
}



#pragma mark - Conversions
- (void)multiplyBy:(NSDecimalNumber *)factor
{
	self.from = [_from decimalNumberByMultiplyingBy:factor];
	self.to = [_to decimalNumberByMultiplyingBy:factor];
}

- (void)divideBy:(NSDecimalNumber *)divisor
{
	self.from = [_from decimalNumberByDividingBy:divisor];
	self.to = [_to decimalNumberByDividingBy:divisor];
}

/**
 *  Returns a copy with limits rounded to given precision
 *  @return An autoreleased copy of the receiver
 */
- (PPRange *)roundedToPrecision:(short)precision
{
	PPRange *copy = [self copy];
	[copy roundToPrecision:precision];
	return copy;
}

/**
 *  Rounds our limits to the given precision
 */
- (void)roundToPrecision:(short)precision
{
	NSDecimalNumberHandler *roundingBehavior = [[NSDecimalNumberHandler alloc] initWithRoundingMode:NSRoundPlain
																							  scale:precision
																				   raiseOnExactness:NO
																					raiseOnOverflow:NO
																				   raiseOnUnderflow:NO
																				raiseOnDivideByZero:NO];
	self.from = [_from decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
	self.to = [_to decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
	
}

- (void)ceil
{
	NSDecimalNumberHandler *roundingBehavior = [[NSDecimalNumberHandler alloc] initWithRoundingMode:NSRoundUp
																							  scale:0
																				   raiseOnExactness:NO
																					raiseOnOverflow:NO
																				   raiseOnUnderflow:NO
																				raiseOnDivideByZero:NO];
	self.from = [_from decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
	self.to = [_to decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
	
}

- (void)floor
{
	NSDecimalNumberHandler *roundingBehavior = [[NSDecimalNumberHandler alloc] initWithRoundingMode:NSRoundDown
																							  scale:0
																				   raiseOnExactness:NO
																					raiseOnOverflow:NO
																				   raiseOnUnderflow:NO
																				raiseOnDivideByZero:NO];
	self.from = [_from decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
	self.to = [_to decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
	
}



#pragma mark - Ranges and String
/**
 *  Sets the lower and upper limits of the range by parsing the limits from a string
 */
- (void)setStringValue:(NSString *)string
{
	if (string != _stringValue) {
		_stringValue = [string copy];
		
		if ([string length] > 0) {
			NSScanner *scanner = [[NSScanner alloc] initWithString:string];
			NSCharacterSet *numberSet = [NSCharacterSet decimalDigitCharacterSet];
			
			BOOL foundSigns = NO;
			BOOL firstDecimalIsLowerLimit = YES;
			NSString *leadString = nil;
			NSDecimal firstDecimal;
			NSString *middleString = nil;
			NSDecimal secondDecimal;
			
			// by default the margin values are included
			_includingFrom = YES;
			_includingTo = YES;
			
			// string does not start with a number - take a closer look, it's probably < or > or similar
			if ([scanner scanUpToCharactersFromSet:numberSet intoString:&leadString]) {
				foundSigns = YES;
				NSCharacterSet *ltSet = [NSCharacterSet characterSetWithCharactersInString:@"<"];
				NSCharacterSet *eqSet = [NSCharacterSet characterSetWithCharactersInString:@"="];
				NSCharacterSet *lteSet = [NSCharacterSet characterSetWithCharactersInString:@"≤"];
				NSRange ltRange = [leadString rangeOfCharacterFromSet:ltSet];
				NSRange eqRange = [leadString rangeOfCharacterFromSet:eqSet];
				NSRange lteRange = [leadString rangeOfCharacterFromSet:lteSet];
				
				// less than or equal to
				if ((ltRange.length > 0 && eqRange.length > 0) || lteRange.length > 0) {
					firstDecimalIsLowerLimit = NO;
					self.from = [NSDecimalNumber minimumDecimalNumber];
				}
				
				// less than
				else if (ltRange.length > 0) {
					firstDecimalIsLowerLimit = NO;
					self.from = [NSDecimalNumber minimumDecimalNumber];
					_includingTo = NO;
				}
				
				// not lower than, try greater than
				else {
					NSCharacterSet *gtSet = [NSCharacterSet characterSetWithCharactersInString:@">"];
					NSCharacterSet *gteSet = [NSCharacterSet characterSetWithCharactersInString:@"≥"];
					NSRange gtRange = [leadString rangeOfCharacterFromSet:gtSet];
					NSRange gteRange = [leadString rangeOfCharacterFromSet:gteSet];
					
					// greater than or equal to
					if ((gtRange.length > 0 && eqRange.length > 0) || gteRange.length > 0) {
						self.to = [NSDecimalNumber maximumDecimalNumber];
					}
					
					// greater than
					else if (gtRange.length > 0) {
						self.to = [NSDecimalNumber maximumDecimalNumber];
						_includingFrom = NO;
					}
				}
			}
			
			// first number
			if ([scanner scanDecimal:&firstDecimal]) {
				if (firstDecimalIsLowerLimit) {
					self.from = [NSDecimalNumber decimalNumberWithDecimal:firstDecimal];
				}
				else {
					self.to = [NSDecimalNumber decimalNumberWithDecimal:firstDecimal];
				}
			}
			
			// still some chars to go
			if (![scanner isAtEnd]) {
				
				// middle string
				if ([scanner scanUpToCharactersFromSet:numberSet intoString:&middleString]) {
					// assume " - " (= "to") for now
				}
				
				// second number
				if ([scanner scanDecimal:&secondDecimal]) {
					self.to = [NSDecimalNumber decimalNumberWithDecimal:secondDecimal];
				}
			}
			
			// only one number found, means the range is to match the exact number
			else if (!foundSigns) {
				self.to = self.from;
			}
			
			// ignore the rest in the string
		}
	}
}

/**
 *  Return the range as a human readable string (in PPRangeDisplayStyleDash)
 */
- (NSString *)stringValue
{
	return [self stringValueWithStyle:PPRangeDisplayStyleDash];
}

/**
 *  Return the range as a human readable string
 *  @arg style The style as PPRangeDisplayStyle on how the string should be formatted
 */
- (NSString *)stringValueWithStyle:(PPRangeDisplayStyle)style
{
	if (_from && ![_from isEqualToNumber:[NSDecimalNumber minimumDecimalNumber]]) {
		if (_to && ![_to isEqualToNumber:[NSDecimalNumber maximumDecimalNumber]]) {
			if ([_to isEqualToNumber:_from]) {
				NSString *formatString = (PPRangeDisplayStyleSquareBrackets == style) ? @"[%@]" : @"%@";
				return [NSString stringWithFormat:formatString, [_from stringValue]];
			}
			NSString *formatString = (PPRangeDisplayStyleSquareBrackets == style) ? @"[%@,%@]" : @"%@ - %@";
			return [NSString stringWithFormat:formatString, [_from stringValue], [_to stringValue]];
		}
		
		// to is +∞
		NSString *formatString;
		if (PPRangeDisplayStyleSquareBrackets == style) {
			formatString = @"[%@,∞]";
		}
		else {
			formatString = _includingTo ? @"≥ %@" : @"> %@";
		}
		return [NSString stringWithFormat:formatString, [_from stringValue]];
	}
	
	// from is -∞
	NSString *formatString;
	if (PPRangeDisplayStyleSquareBrackets == style) {
		formatString = @"[-∞,%@]";
	}
	else {
		formatString = _includingTo ? @"≤ %@" : @"< %@";
	}
	return [NSString stringWithFormat:formatString, _to ? [_to stringValue] : @"∞"];
}



#pragma mark - Utilities
- (BOOL)isDefined
{
	return (_from != nil || _to != nil);
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <%p> %@", NSStringFromClass([self class]), self, [self stringValue]];
}


@end
