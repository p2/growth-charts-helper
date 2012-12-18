/*
 CHChartArea.h
 Charts
 
 Created by Pascal Pfiffner on 9/9/12.
 Copyright (c) 2012 Children's Hospital Boston. All rights reserved.
 
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

#import <Foundation/Foundation.h>
#import "CHChart.h"

@class CHChartAreaView;


/**
 *	Describes a rectangular area on a chart.
 */
@interface CHChartArea : NSObject

@property (nonatomic, weak) CHChart *chart;					///< The chart to which we belong
@property (nonatomic, copy) NSString *type;					///< The type of the area
@property (nonatomic, copy) NSDictionary *dictionary;		///< The dictionary representation defining the receiver, kept around to spawn the view objects
@property (nonatomic, assign) NSUInteger page;				///< 1 by default. The page number of the PDF this area resides on

@property (nonatomic, copy) NSArray *areas;					///< An area can have any number of subareas

+ (id)newAreaOnChart:(CHChart *)chart withDictionary:(NSDictionary *)dict;
- (void)setFromDictionary:(NSDictionary *)dict;

- (CHChartAreaView *)view;


@end
