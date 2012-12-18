//
//  CHDateUnit.h
//  Charts
//
//  Created by Pascal Pfiffner on 10/31/12.
//  Copyright (c) 2012 Boston Children's Hospital. All rights reserved.
//

#import "CHUnit.h"


/**
 *  An object representing a unit for dates.
 */
@interface CHDateUnit : CHUnit

@property (nonatomic, strong) NSDate *referenceDate;			///< Will be used when converting between units, meaning numbers are relative to this date (Jan 1, 2001 by default)

- (NSDate *)dateValueFor:(NSDecimalNumber *)number fromDate:(NSDate *)refDate;

@end
