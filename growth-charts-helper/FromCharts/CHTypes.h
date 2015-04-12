//
//  CHTypes.h
//  Charts
//
//  Created by Pascal Pfiffner on 11/19/12.
//  Copyright (c) 2012 Boston Children's Hospital. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Gender.
 */
typedef NS_ENUM(unsigned int, CHGender) {
	CHGenderUnknown = 0,
	CHGenderMale,
	CHGenderFemale				// sorry ladies, but many charts define male = 1 and female = 2, trying not to cause confusion here.
};


/**
 *  String lengths.
 */
typedef NS_ENUM(unsigned int, CHValueStringSize) {
	CHValueStringSizeLong = 0,
	CHValueStringSizeSmall,
	CHValueStringSizeCompact,
};
