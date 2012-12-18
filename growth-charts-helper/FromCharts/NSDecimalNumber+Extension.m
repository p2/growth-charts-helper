//
//  NSDecimalNumber+Modulo.m
//  Charts
//
//  Created by Pascal Pfiffner on 11/19/12.
//  Copyright (c) 2012 Children's Hospital Boston. All rights reserved.
//

#import "NSDecimalNumber+Extension.h"

@implementation NSDecimalNumber (Extension)

#pragma mark - Modulo
/**
 *  @return A NSDecimalNumber representing the modulo of the divisor
 */
- (NSDecimalNumber *)moduloFor:(NSDecimalNumber *)divisor
{
	NSRoundingMode roundingMode = (([self intValue] < 0) ^ ([self intValue] < 0)) ? NSRoundUp : NSRoundDown;
	NSDecimalNumberHandler *rounding = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:roundingMode
																							  scale:0
																				   raiseOnExactness:NO
																					raiseOnOverflow:NO
																				   raiseOnUnderflow:NO
																				raiseOnDivideByZero:NO];
	
	// divide and get the remainder
	NSDecimalNumber *quotient = [self decimalNumberByDividingBy:divisor withBehavior:rounding];
	NSDecimalNumber *subtract = [quotient decimalNumberByMultiplyingBy:divisor];
	return [self decimalNumberBySubtracting:subtract];
}


/**
 *  @return A NSDecimalNumber representing the modulo of the divisor
 */
- (NSDecimalNumber *)moduloForDouble:(double)divisor
{
	NSDecimalNumber *div = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%f", divisor]];
	return [self moduloFor:div];
}



#pragma mark - Handling Decimal Places
/**
 *  @return A NSDecimalNumber with only the decimal places of the receiver, i.e. number % 1
 */
- (NSDecimalNumber *)decimalPlaces
{
	return [self moduloFor:[NSDecimalNumber one]];
}



#pragma mark - Negativity
/**
 *  Multiplies by minus one if the receiver is negative.
 */
- (NSDecimalNumber *)absoluteNumber
{
	if (NSOrderedDescending == [[NSDecimalNumber zero] compare:self]) {
		NSDecimalNumber *negOne = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:0 isNegative:YES];
		return [self decimalNumberByMultiplyingBy:negOne];
	}
	return self;
}


@end
