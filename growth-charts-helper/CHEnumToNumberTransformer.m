/*
 CHGenderToNumberTransformer.m
 growth-charts-helper
 
 Created by Pascal Pfiffner on 12/18/12.
 Copyright (c) 2012 CHIP. All rights reserved.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#import "CHEnumToNumberTransformer.h"


@interface CHEnumToNumberTransformer ()

@end


@implementation CHEnumToNumberTransformer


+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

/**
 *  Since the transformer can't be fed an enum, aka an int, it feeds us an NSNumber instead -- which is exactly what we want anyway, d'oh!
 */
- (id)transformedValue:(id)value
{
	return value;
}

/**
 *  Same here, we need to encapsulate the enum (aka int) in an NSNumber, and since we transformed to an NSNumber we just feed it back again.
 */
- (id)reverseTransformedValue:(id)value
{
    return value;
}


@end
