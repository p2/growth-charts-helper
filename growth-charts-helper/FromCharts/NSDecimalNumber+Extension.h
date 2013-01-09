//
//  NSDecimalNumber+Extension.h
//  Charts
//
//  Created by Pascal Pfiffner on 11/19/12.
//  Copyright (c) 2012 Children's Hospital Boston. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Category to extend NSDecimalNumber's methods.
 */
@interface NSDecimalNumber (Extension)

- (NSDecimalNumber *)moduloFor:(NSDecimalNumber *)divisor;
- (NSDecimalNumber *)moduloForDouble:(double)divisor;
- (NSDecimalNumber *)decimalPlaces;
- (NSDecimalNumber *)absoluteNumber;

- (NSDecimalNumber *)greaterNumber:(NSDecimalNumber *)number;
- (NSDecimalNumber *)smallerNumber:(NSDecimalNumber *)number;

@end
