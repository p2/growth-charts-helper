//
//  CHJSONHandling.h
//  Charts
//
//  Created by Pascal Pfiffner on 10/30/12.
//  Copyright (c) 2012 Boston Children's Hospital. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Used for our JSON reading and writing.
 */
@protocol CHJSONHandling <NSObject>

/**
 *  Should instantiate a new object from the given JSON value.
 */
+ (id)newFromJSONObject:(id)object;

/**
 *  Sets the receiver's properties to the values found in the JSON object.
 */
- (BOOL)setFromJSONObject:(id)object;

/**
 *  @return An object like a dictionary or string that represents the receiver in JSON
 */
- (id)jsonObject;


@end
