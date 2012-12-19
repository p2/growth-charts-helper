/*
 CHDropView.h
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

#import <Cocoa/Cocoa.h>

extern NSString *const CHDropViewDroppedItemsNotificationName;
extern NSString *const CHDropViewDroppedItemsKey;

/**
 *	View accepting a drop action.
 */
@interface CHDropView : NSBox

@property (nonatomic, copy) NSSet *acceptedTypes;			///< Accepted drop UTIs
@property (nonatomic, assign) BOOL acceptMultiple;
@property (nonatomic, assign) BOOL highlighted;


@end
