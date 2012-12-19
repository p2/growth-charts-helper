/*
 CHChartArea.m
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

#import "CHChartArea.h"
#import "CHChartAreaView.h"


@interface CHChartArea ()

@property (nonatomic, readwrite, assign) BOOL topmost;

@end


@implementation CHChartArea


+ (id)newAreaOnChart:(CHChart *)chart withDictionary:(NSDictionary *)dict
{
	CHChartArea *this = [self new];
	this.chart = chart;
	this.topmost = YES;
	[this setFromDictionary:dict];
	
	return this;
}



/**
 *	Sets all properties it recognizes from the dict, leaves other properties at their current value.
 *
 *	Call super in subclasses unless you know what you are doing.
 */
- (void)setFromDictionary:(NSDictionary *)dict
{
	NSMutableDictionary *muteDict = [dict mutableCopy];
	
	// type
	self.type = [dict objectForKey:@"type"];
	if (![_type isKindOfClass:[NSString class]]) {
		DLog(@"\"type\" must be a NSString, but I got a %@, using its description", NSStringFromClass([_type class]));
		self.type = [_type description];
	}
	[muteDict removeObjectForKey:@"type"];
	
	// page
	NSNumber *pageNumber = [dict objectForKey:@"page"];
	if (pageNumber) {
		NSInteger pageNum = NSNotFound;
		if (![pageNumber isKindOfClass:[NSNumber class]]) {
			DLog(@"\"page\" must be a NSNumber, but I got a %@, discarding", NSStringFromClass([pageNumber class]));
			pageNumber = nil;
		}
		else {
			pageNum = [pageNumber integerValue];
		}
		self.page = pageNum;
		[muteDict removeObjectForKey:@"page"];
	}
	
	// frame
	NSString *rectString = [dict objectForKey:@"rect"];
	if ([rectString isKindOfClass:[NSString class]]) {
		NSRect rect = NSRectFromString(rectString);
		self.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	}
	else if (rectString) {
		DLog(@"\"rect\" must be a NSString, but I got a %@, discarding", NSStringFromClass([rectString class]));
	}
	
	// fonts
	NSString *aFontName = [dict objectForKey:@"fontName"];
	if ([aFontName isKindOfClass:[NSString class]]) {
		self.fontName = aFontName;
	}
	NSNumber *aFontSize = [dict objectForKey:@"fontSize"];
	if ([aFontSize isKindOfClass:[NSNumber class]]) {
		self.fontSize = aFontSize;
	}
	else if (aFontSize) {
		DLog(@"\"fontSize\" must be a number, but I got a %@, discarding", NSStringFromClass([aFontSize class]));
	}
	
	// data and value areas
	NSString *aDataType = [dict objectForKey:@"dataType"];
	if ([aDataType isKindOfClass:[NSString class]]) {
		self.dataType = aDataType;
	}
	
	// plot areas
	NSDictionary *axesDict = [dict objectForKey:@"axes"];
	if ([axesDict isKindOfClass:[NSDictionary class]]) {
		
		// x
		NSDictionary *xAxisDict = [axesDict objectForKey:@"x"];
		self.xAxisUnitName = [xAxisDict objectForKey:@"unit"];
		self.xAxisDataType = [xAxisDict objectForKey:@"datatype"];
		self.xAxisFrom = [NSDecimalNumber decimalNumberWithString:[xAxisDict objectForKey:@"from"]];
		self.xAxisTo = [NSDecimalNumber decimalNumberWithString:[xAxisDict objectForKey:@"to"]];
		
		// y
		NSDictionary *yAxisDict = [axesDict objectForKey:@"y"];
		self.yAxisUnitName = [yAxisDict objectForKey:@"unit"];
		self.yAxisDataType = [yAxisDict objectForKey:@"datatype"];
		self.yAxisFrom = [NSDecimalNumber decimalNumberWithString:[yAxisDict objectForKey:@"from"]];
		self.yAxisTo = [NSDecimalNumber decimalNumberWithString:[yAxisDict objectForKey:@"to"]];
	}
	else if ([@"plot" isEqualToString:_type]) {
		DLog(@"This plot area does not have axes!  %@", dict);
	}
	
	// ** sub-areas
	NSArray *areas = [dict objectForKey:@"areas"];
	if ([areas isKindOfClass:[NSArray class]] && [areas count] > 0) {
		NSMutableArray *myAreas = [NSMutableArray arrayWithCapacity:[areas count]];
		
		// loop sub-areas
		for (NSDictionary *areaDict in areas) {
			if ([areaDict isKindOfClass:[NSDictionary class]]) {
				CHChartArea *area = [CHChartArea newAreaOnChart:_chart withDictionary:areaDict];
				if (area) {
					area.topmost = NO;
					area.page = self.page;
					[myAreas addObject:area];
				}
			}
		}
		
		self.areas = myAreas;
	}
	[muteDict removeObjectForKey:@"areas"];
	
	// remember all the other properties
	self.dictionary = muteDict;
}



#pragma mark - Returning the View
/**
 *  Returns a new CHChartAreaView instance created from the properties of the receiver (including sub-areas)
 */
- (CHChartAreaView *)view
{
	Class viewClass = [CHChartAreaView registeredClassForType:_type];
	CHChartAreaView *view = [viewClass new];
	if (!view) {
		DLog(@"Failed to create a view for area %@", self);
		return nil;
	}
	
	// update properties
	view.area = self;
	
	// sub-areas
	if ([_areas count] > 0) {
		NSMutableArray *subviews = [NSMutableArray arrayWithCapacity:[_areas count]];
		for (CHChartArea *subarea in _areas) {
			CHChartAreaView *subview = [subarea view];
			[subviews addObject:subview];
		}
		view.areas = subviews;
	}
	
	return view;
}



#pragma mark - Utilities
- (CGFloat)frameOriginX
{
	return _frame.origin.x;
}

- (void)setFrameOriginX:(CGFloat)x
{
	CGRect fr = _frame;
	fr.origin.x = x;
	self.frame = fr;
}

- (CGFloat)frameOriginY
{
	return _frame.origin.y;
}

- (void)setFrameOriginY:(CGFloat)y
{
	CGRect fr = _frame;
	fr.origin.y = y;
	self.frame = fr;
}

- (CGFloat)frameSizeWidth
{
	return _frame.size.width;
}

- (void)setFrameSizeWidth:(CGFloat)w
{
	CGRect fr = _frame;
	fr.size.width = w;
	self.frame = fr;
}

- (CGFloat)frameSizeHeight
{
	return _frame.size.height;
}

- (void)setFrameSizeHeight:(CGFloat)h
{
	CGRect fr = _frame;
	fr.size.height = h;
	self.frame = fr;
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <%p> type \"%@\", %d sub-areas", NSStringFromClass([self class]), self, _type, (int)[_areas count]];
}


@end
