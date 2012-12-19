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

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "CHChart.h"

@class CHChartArea;
@class CHChartPDFView;


/**
 *  A chart area represents an area on a PDF file to draw content into.
 *
 *  Use one of its subclasses, they are more useful than this abstract superclass.
 *
 *  You can use the chart area as a standard view, adding it to a superview and have it draw the items into its context when the area is drawn, or use it
 *  manually by not adding it to a view hierarchy and calling its drawing methods with your own context. We do this with CHChartPlotAreas from CHChartPage so
 *  the area can also display data points that lie outside its borders.
 *
 *  @attention Override "drawLayer:inContext:" in subclasses, not "drawRect:"!
 */
@interface CHChartAreaView : NSView

@property (nonatomic, weak) CHChartArea *area;				///< The area model that describes the receiver

@property (nonatomic, assign) CGPoint origin;				///< Origin between 0 and 1 relative to its parent's grid
@property (nonatomic, assign) CGSize size;					///< Size between 0 and 1 relative to its parent's grid
@property (nonatomic, assign) CGPathRef outline;			///< The outline of the area. We do *not* clip to this area, but you can use it to do so.
@property (nonatomic, assign) CGSize pageSize;				///< The size of the page we're currently displayed on, in screen pixels

@property (nonatomic, copy) NSArray *areas;					///< An area can have any number of subareas

@property (nonatomic, weak) CHChartPDFView *pageView;		///< The PDFView we're residing in
@property (nonatomic, assign) BOOL active;

- (void)setFromDictionary:(NSDictionary *)dict;

- (void)reset;
- (void)resetHighlight;

- (void)positionInFrame:(CGRect)targetRect onView:(NSView *)aView pageSize:(CGSize)pageSize;
- (CGRect)boundingBox;
- (CGRect)framingBox;
- (CGRect)outlineBox;
- (CGRect)contentBox;

- (void)updateWithDataSource:(id<CHChartDataSource>)dataSource;
- (NSSet *)allDataTypes;
- (NSSet *)plotDataTypes;

- (BOOL)pointInside:(CGPoint)point withEvent:(NSEvent *)event;
- (NSSet *)areasAtPoint:(CGPoint)point;

+ (Class)registeredClassForType:(NSString *)aType;

+ (NSCharacterSet *)outlinePathSplitSet;


@end
