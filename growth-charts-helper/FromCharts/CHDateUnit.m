//
//  CHDateUnit.m
//  Charts
//
//  Created by Pascal Pfiffner on 10/31/12.
//  Copyright (c) 2012 Boston Children's Hospital. All rights reserved.
//

#import "CHDateUnit.h"
#import "NSDecimalNumber+Extension.h"


@implementation CHDateUnit


- (NSString *)stringValueForNumber:(NSDecimalNumber *)number withSize:(CHValueStringSize)size
{
	// convert to NSDate and get components
	NSDate *ageDate = [self dateValueFor:number fromDate:self.referenceDate];
	NSDateComponents *comp = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:self.referenceDate toDate:ageDate options:0];
	
	// compose a string -- year
	NSMutableArray *parts = [NSMutableArray arrayWithCapacity:3];
	if (comp.year > 0) {
		if (1 == comp.year) {
			comp.month += 12;
		}
		else {
			if (CHValueStringSizeLong == size) {
				[parts addObject:[NSString stringWithFormat:@"%d years", comp.year]];
			}
			else if (CHValueStringSizeCompact == size) {
				[parts addObject:[NSString stringWithFormat:@"%dy", comp.year]];
			}
			else {
				[parts addObject:[NSString stringWithFormat:@"%d y", comp.year]];
			}
		}
	}
	
	// months
	if (comp.month > 0) {
		if (CHValueStringSizeLong == size) {
			[parts addObject:[NSString stringWithFormat:@"%d month%@", comp.month, (1 == comp.month ? @"" : @"s")]];
		}
		else if (CHValueStringSizeCompact == size) {
			[parts addObject:[NSString stringWithFormat:@"%dm", comp.month]];
		}
		else {
			[parts addObject:[NSString stringWithFormat:@"%d mth", comp.month]];
		}
	}
	
	// days
	if (comp.day > 0) {
		if (CHValueStringSizeLong == size) {
			[parts addObject:[NSString stringWithFormat:@"%d day%@", comp.day, (1 == comp.day ? @"" : @"s")]];
		}
		else if (CHValueStringSizeCompact == size) {
			[parts addObject:[NSString stringWithFormat:@"%dd", comp.day]];
		}
		else {
			[parts addObject:[NSString stringWithFormat:@"%d d", comp.day]];
		}
	}
	
	//DLog(@"years: %d, months: %d, days: %d   =>   %@", comp.year, comp.month, comp.day, [parts componentsJoinedByString:@" "]);
	return ([parts count] > 0) ? [parts componentsJoinedByString:@" "] : @"Birth";
}


/**
 *  Convert the given number, assumed to be in the receiver's unit, to the given unit.
 *
 *  This method applies a calendar-based conversion, which is rather CPU intensive (compared to standard math required for other units). Please also consider
 *  the accuracy of conversions - 1.5 years will be interpreted as 1 year and 6 months, not as 182 or 183 days, which is probably better when compared what
 *  humans expect from such a conversion (i.e. keeping the same day of the month), but sacrifices some accuracy.
 *
 *  @param number A number representing time in the receiver's unit
 *  @param unit The target unit the number should be converted to
 *  @return An NSDecimalNumber representing the number in the desired time unit
 */
- (NSDecimalNumber *)convertNumber:(NSDecimalNumber *)number toUnit:(CHUnit *)unit
{
	if (![self isSameDimension:unit]) {
		DLog(@"I can not convert to a unit from another dimension (%@ -> %@)", self.dimension, unit.dimension);
		return number;
	}
	if ([self.name isEqualToString:unit.name]) {
		return number;
	}
	
	// convert current to date
	NSDate *refDate = self.referenceDate;
	NSDate *date = [self dateValueFor:number fromDate:refDate];
	
	// convert to other unit
	double result = 0.0;
	if ([@"year" isEqualToString:unit.name]) {
		NSDateComponents *comp = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:refDate toDate:date options:0];
		result = (double)comp.year + (comp.month > 0 ? (double)comp.month / 12.0 : 0.0);
	}
	else if ([@"month" isEqualToString:unit.name]) {
		NSDateComponents *comp = [[NSCalendar currentCalendar] components:(NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:refDate toDate:date options:0];
		result = (double)comp.month + (comp.day > 0 ? (double)comp.day / 30.5 : 0.0);
	}
	else if ([@"week" isEqualToString:unit.name]) {
		NSDateComponents *comp = [[NSCalendar currentCalendar] components:(NSWeekCalendarUnit | NSDayCalendarUnit) fromDate:refDate toDate:date options:0];
		result = (double)comp.week + (comp.day > 0 ? (double)comp.day / 7.0 : 0.0);
	}
	else if ([@"day" isEqualToString:unit.name]) {
		NSDateComponents *comp = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit | NSSecondCalendarUnit) fromDate:refDate toDate:date options:0];
		result = (double)comp.day + (comp.second > 0 ? (double)comp.second / 86400.0 : 0.0);
	}
	else if ([@"hour" isEqualToString:unit.name]) {
		NSDateComponents *comp = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit | NSSecondCalendarUnit) fromDate:refDate toDate:date options:0];
		result = (double)comp.hour + (comp.second > 0 ? (double)comp.second / 3600.0 : 0.0);
	}
	else if ([@"second" isEqualToString:unit.name]) {
		NSDateComponents *comp = [[NSCalendar currentCalendar] components:NSSecondCalendarUnit fromDate:refDate toDate:date options:0];
		result = (double)comp.second;
	}
	else {
		DLog(@"I can't convert from \"%@\" to \"%@\" I'm afraid", self.name, unit.name);
		return number;
	}
	
	return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%f", result]];
}


/**
 *  @param number A number representing time in the receiver's unit
 *  @return An NSDecimalNumber representing the given number in seconds
 */
- (NSDecimalNumber *)numberInBaseUnit:(NSDecimalNumber *)number
{
	if ([@"second" isEqualToString:self.name]) {
		return number;
	}
	
	NSDate *date = [self dateValueFor:number fromDate:self.referenceDate];
	
	NSDateComponents *comp = [[NSCalendar currentCalendar] components:NSSecondCalendarUnit fromDate:self.referenceDate toDate:date options:0];
	return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%i", comp.second]];
}



#pragma mark - Date Handling
/**
 *  @return A date that represents the date with the given numerical distance, in our unit system, from our reference date (2001-01-01 by default)
 */
- (NSDate *)dateValueFor:(NSDecimalNumber *)number fromDate:(NSDate *)refDate
{
	NSDateComponents *comp = [NSDateComponents new];
	
	if ([@"year" isEqualToString:self.name]) {
		comp.year = [number integerValue];
		comp.month = (NSInteger)([[number decimalPlaces] doubleValue] * 12.0);
	}
	else if ([@"month" isEqualToString:self.name]) {
		comp.month = [number integerValue];
		comp.day = (NSInteger)([[number decimalPlaces] doubleValue] * 30.5);
	}
	else if ([@"week" isEqualToString:self.name]) {
		comp.week = [number integerValue];
		comp.day = (NSInteger)([[number decimalPlaces] doubleValue] * 7.0);
	}
	else if ([@"day" isEqualToString:self.name]) {
		comp.day = [number integerValue];
		comp.second = (NSInteger)([[number decimalPlaces] doubleValue] * 86400.0);
	}
	else if ([@"hour" isEqualToString:self.name]) {
		comp.hour = [number integerValue];
		comp.second = (NSInteger)([[number decimalPlaces] doubleValue] * 3600.0);
	}
	else if ([@"second" isEqualToString:self.name]) {
		comp.second = [number integerValue];
	}
	else {
		DLog(@"I don't know how to treat \"%@\" units I'm afraid", self.name);
		return nil;
	}
	
	return [[NSCalendar currentCalendar] dateByAddingComponents:comp toDate:refDate options:0];
}



#pragma mark - KVC
- (NSDate *)referenceDate
{
	if (!_referenceDate) {
		self.referenceDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0.0];
	}
	return _referenceDate;
}


@end
