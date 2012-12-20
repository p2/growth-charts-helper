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
#import "CHJSONHandling.h"

@class CHChartAreaView;


/**
 *	Describes a rectangular area on a chart.
 */
@interface CHChartArea : NSObject <CHJSONHandling>

@property (nonatomic, weak) CHChart *chart;					///< The chart to which we belong
@property (nonatomic, copy) NSString *type;					///< The type of the area
@property (nonatomic, copy) NSArray *outlinePoints;			///< An array of CGPoints (in NSValues) that define the path for our outline
@property (nonatomic, copy) NSDictionary *dictionary;		///< The dictionary representation defining the receiver, kept around to spawn the view objects

@property (nonatomic, assign) NSUInteger page;				///< 1 by default. The page number of the PDF this area resides on
@property (nonatomic, assign) CGRect frame;					///< The frame as specified
@property (nonatomic, assign) CGFloat frameOriginX;
@property (nonatomic, assign) CGFloat frameOriginY;
@property (nonatomic, assign) CGFloat frameSizeWidth;
@property (nonatomic, assign) CGFloat frameSizeHeight;

@property (nonatomic, copy) NSString *fontName;				///< Text areas: font name
@property (nonatomic, strong) NSNumber *fontSize;			///< Text areas: font size

@property (nonatomic, copy) NSString *dataType;				///< Value areas: data type

@property (nonatomic, copy) NSString *xAxisUnitName;		///< Plot areas: X axis unit name
@property (nonatomic, copy) NSString *xAxisDataType;		///< Plot areas: X axis data type
@property (nonatomic, strong) NSDecimalNumber *xAxisFrom;	///< Plot areas: X axis starting point
@property (nonatomic, strong) NSDecimalNumber *xAxisTo;		///< Plot areas: X axis ending point
@property (nonatomic, copy) NSString *yAxisUnitName;		///< Plot areas: Y axis unit name
@property (nonatomic, copy) NSString *yAxisDataType;		///< Plot areas: Y axis data type
@property (nonatomic, strong) NSDecimalNumber *yAxisFrom;	///< Plot areas: Y axis starting point
@property (nonatomic, strong) NSDecimalNumber *yAxisTo;		///< Plot areas: Y axis ending point
@property (nonatomic, copy) NSString *statsSource;			///< Plot areas: The source for eventual statistics

@property (nonatomic, assign) BOOL topmost;					///< YES if this area lies directly on the PDF, i.e. not nested in another area
@property (nonatomic, copy) NSArray *areas;					///< An area can have any number of subareas

- (CHChartAreaView *)view;

+ (NSCharacterSet *)outlinePathSplitSet;


@end
