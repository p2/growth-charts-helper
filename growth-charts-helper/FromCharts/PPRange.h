//
//  PPRange.h
//  RenalApp
//
//  Created by Pascal Pfiffner on 13.10.09.
//  Copyright 2009 Pascal Pfiffner. All rights reserved.
//
//	An object to define a numeric range
//	Ranges can be parsed from strings, e.g.:
//		0 - 1
//		>= 2.5
//		≥ 2.5
//		< 100
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(unsigned int, PPRangeDisplayStyle) {
	PPRangeDisplayStyleDash = 0,				///< a - b
	PPRangeDisplayStyleSquareBrackets			///< [a,b]
};

typedef NS_ENUM(unsigned int, PPRangeResult) {
	PPRangeResultUndefined = 0,
	PPRangeResultTooLow,						///< The value is too low
	PPRangeResultJustTooLow,					///< This is not used by PPRange itself, but provided here for use by others
	PPRangeResultOK,							///< The value is in the range
	PPRangeResultJustTooHigh,					///< Same as just too low, not used by PPRange directly
	PPRangeResultTooHigh						///< The value is too high
};


/**
 *  This class represents a range and can determine whether a NSNumber falls within the range it represents
 *  or not. The lower as well as the upper limit are OPTIONAL.
 *
 *  Supported string formats are (whitespace is ignored)
 *  - 1   -   2
 *  - 1   -<  2
 *  -     <   2
 *  -      >  1
 *  -      >= 1
 *  - >1  -   2
 *  - 1   -
 *  -     <=  2
 *  -     ≤   2
 */
@interface PPRange : NSObject <NSCopying, NSCoding>

@property (nonatomic, copy) NSString *stringValue;		///< The string representation; changing the string changes the bounds!

@property (nonatomic, copy) NSDecimalNumber *from;		///< The lower limit
@property (nonatomic, assign) BOOL includingFrom;		///< YES by default, changed automatically when parsing from string
@property (nonatomic, copy) NSDecimalNumber *to;		///< The upper limit
@property (nonatomic, assign) BOOL includingTo;			///< YES by default, changed automatically when parsing from string

+ (PPRange *)rangeWithString:(NSString *)string;
+ (PPRange *)rangeFrom:(NSDecimalNumber *)min to:(NSDecimalNumber *)max;
+ (PPRange *)rangeFromString:(NSString *)min toString:(NSString *)max;
- (instancetype)initWithString:(NSString *)string;

- (BOOL)contains:(NSNumber *)test;
- (PPRangeResult)test:(NSNumber *)test;

- (PPRange *)copyWithCustomFrom:(NSDecimalNumber *)min to:(NSDecimalNumber *)max;
- (BOOL)isDefined;
- (void)multiplyBy:(NSDecimalNumber *)factor;
- (void)divideBy:(NSDecimalNumber *)divisor;
- (PPRange *)roundedToPrecision:(short)precision;
- (void)roundToPrecision:(short)precision;
- (void)ceil;
- (void)floor;

- (NSString *)stringValue;
- (NSString *)stringValueWithStyle:(PPRangeDisplayStyle)style;

@end
