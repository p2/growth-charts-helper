/*
 CHChartAreaView.h
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

#import "CHClickableView.h"
#import <QuartzCore/QuartzCore.h>
#import "CHChart.h"

@class CHChartArea;
@class CHChartPDFView;


/**
 *  A chart area represents an area on a PDF file to draw content into.
 */
@interface CHChartAreaView : CHClickableView

@property (nonatomic, weak) CHChartArea *area;				///< The area model that describes the receiver

@property (nonatomic, strong) NSBezierPath *outline;		///< The outline of the area
@property (nonatomic, assign) CGSize pageSize;				///< The size of the page we're currently displayed on, in screen pixels

@property (nonatomic, copy) NSArray *areas;					///< An area can have any number of subareas

@property (nonatomic, weak) CHChartPDFView *pageView;		///< The PDFView we're residing in

- (void)setup;
- (void)reset;
- (void)resetHighlight;

- (void)positionInFrame:(CGRect)targetRect onView:(NSView *)aView pageSize:(CGSize)pageSize;
- (void)reposition;
- (CHChartAreaView *)didAddArea:(CHChartArea *)area;
- (void)didRemoveArea:(CHChartArea *)area;

@property (nonatomic, readonly) CGRect boundingBox;
@property (nonatomic, readonly) CGRect framingBox;
@property (nonatomic, readonly) CGRect outlineBox;
@property (nonatomic, readonly) CGRect contentBox;

- (void)updateWithDataSource:(id<CHChartDataSource>)dataSource;
@property (nonatomic, readonly, copy) NSSet *allDataTypes;
@property (nonatomic, readonly, copy) NSSet *plotDataTypes;

- (BOOL)pointInside:(CGPoint)point withEvent:(NSEvent *)event;
- (NSSet *)areasAtPoint:(CGPoint)point;

+ (Class)registeredClassForType:(NSString *)aType;

@end
