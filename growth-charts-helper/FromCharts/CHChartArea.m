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

@property (nonatomic, strong) NSMapTable *knownViews;

@end


@implementation CHChartArea


#pragma mark - JSON Handling
+ (id)newFromJSONObject:(id)object
{
	CHChartArea *area = [CHChartArea new];
	if ([area setFromJSONObject:object]) {
		return area;
	}
	
	return nil;
}


/**
 *  Fill from a dictionary passed in from decoding JSON.
 */
- (BOOL)setFromJSONObject:(id)object
{
	if (![object isKindOfClass:[NSDictionary class]]) {
		DLog(@"I need a dictionary, but got a %@: %@", NSStringFromClass([object class]), object);
		return NO;
	}
	
	NSDictionary *dict = (NSDictionary *)object;
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
		DLog(@"\"rect\" must be a string, but I got a %@, discarding", NSStringFromClass([rectString class]));
	}
	
	// outline
	NSString *outlineString = [dict objectForKey:@"outline"];
	if ([outlineString isKindOfClass:[NSString class]]) {
		NSArray *points = [outlineString componentsSeparatedByCharactersInSet:[[self class] outlinePathSplitSet]];
		if ([points count] > 0) {
			NSMutableArray *outPoints = [NSMutableArray arrayWithCapacity:[points count]];
			for (NSString *pointStr in points) {
				NSPoint point = NSPointFromString(pointStr);
				[outPoints addObject:[NSValue valueWithPoint:point]];
			}
			self.outlinePoints = outPoints;
		}
	}
	else if (outlineString) {
		DLog(@"\"outline\" must be a string, but I got a %@, discarding", NSStringFromClass([outlineString class]));
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
		self.xAxisDataType = [xAxisDict objectForKey:@"dataType"];
		self.xAxisFrom = [NSDecimalNumber decimalNumberWithString:[[xAxisDict objectForKey:@"from"] description]];
		self.xAxisTo = [NSDecimalNumber decimalNumberWithString:[[xAxisDict objectForKey:@"to"] description]];
		
		// y
		NSDictionary *yAxisDict = [axesDict objectForKey:@"y"];
		self.yAxisUnitName = [yAxisDict objectForKey:@"unit"];
		self.yAxisDataType = [yAxisDict objectForKey:@"dataType"];
		self.yAxisFrom = [NSDecimalNumber decimalNumberWithString:[[yAxisDict objectForKey:@"from"] description]];
		self.yAxisTo = [NSDecimalNumber decimalNumberWithString:[[yAxisDict objectForKey:@"to"] description]];
		
		// stats source
		NSString *statsSource = [dict objectForKey:@"statsSource"];
		if ([statsSource isKindOfClass:[NSString class]]) {
			self.statsSource = statsSource;
		}
		else if (statsSource) {
			DLog(@"\"statsSource\" should be a string, but got a %@, discarding", NSStringFromClass([statsSource class]));
		}
	}
	else if ([@"plot" isEqualToString:_type]) {
		DLog(@"This plot area does not have axes!  %@", dict);
	}
	
	// ** sub-areas
	NSArray *areas = [dict objectForKey:@"areas"];
	if ([areas isKindOfClass:[NSArray class]]) {
		if ([areas count] > 0) {
			NSMutableArray *myAreas = [NSMutableArray arrayWithCapacity:[areas count]];
			
			// loop sub-areas
			for (NSDictionary *areaDict in areas) {
				CHChartArea *area = [CHChartArea newFromJSONObject:areaDict];
				if (area) {
					area.chart = _chart;
					area.topmost = NO;
					area.page = self.page;
					[myAreas addObject:area];
				}
			}
			
			self.areas = myAreas;
		}
	}
	else if (areas) {
		DLog(@"\"areas\" must be an array, but I got a %@, discarding", NSStringFromClass([areas class]));
	}
	[muteDict removeObjectForKey:@"areas"];
	
	// remember all the other properties
	self.dictionary = muteDict;
	return YES;
}

- (id)jsonObject
{
	if ([_type length] < 1) {
		DLog(@"This area does not have a type, not returning a JSON object");
		return nil;
	}
	
	// basic properties
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:_type forKey:@"type"];
	if (_topmost && _page > 0) {
		[dict setObject:[NSNumber numberWithUnsignedInteger:_page] forKey:@"page"];
	}
	[dict setObject:NSStringFromCGRect(_frame) forKey:@"rect"];
	
	// the outline
	if ([_outlinePoints count] > 2) {
		NSMutableArray *points = [NSMutableArray arrayWithCapacity:[_outlinePoints count]];
		for (NSValue *point in _outlinePoints) {
			[points addObject:NSStringFromCGPoint([point pointValue])];
		}
		NSString *pointString = [points componentsJoinedByString:@";"];
		if ([pointString length] > 0) {
			[dict setObject:pointString forKey:@"outline"];
		}
	}
	else if ([_outlinePoints count] > 0) {
		DLog(@"We need at least 3 outline points, %d are worthless", (int)[_outlinePoints count]);
	}
	
	// plot areas
	if ([@"plot" isEqualToString:_type]) {
		NSDictionary *x = @{
			@"dataType": _xAxisDataType ? _xAxisDataType : @"",
			@"unit": _xAxisUnitName ? _xAxisUnitName : @"",
			@"from": _xAxisFrom ? _xAxisFrom : @0,
			@"to": _xAxisTo ? _xAxisTo : @0
		};
		NSDictionary *y = @{
			@"dataType": _yAxisDataType ? _yAxisDataType : @"",
			@"unit": _yAxisUnitName ? _yAxisUnitName : @"",
			@"from": _yAxisFrom ? _yAxisFrom : @0,
			@"to": _yAxisTo ? _yAxisTo : @0
		};
		
		[dict setObject:@{@"x": x, @"y": y} forKey:@"axes"];
		if ([_statsSource length] > 0) {
			[dict setObject:_statsSource forKey:@"statsSource"];
		}
	}
	
	// areas with another type
	else {
		if ([_fontName length] > 0) {
			[dict setObject:_fontName forKey:@"fontName"];
		}
		if (_fontSize) {
			[dict setObject:_fontSize forKey:@"fontSize"];
		}
		if ([_dataType length] > 0) {
			[dict setObject:_dataType forKey:@"dataType"];
		}
	}
	
	// subareas
	if ([_areas count] > 0) {
		NSMutableArray *subareas = [NSMutableArray arrayWithCapacity:[_areas count]];
		for (CHChartArea *area in _areas) {
			id json = [area jsonObject];
			if (json) {
				[subareas addObject:json];
			}
		}
		[dict setObject:subareas forKey:@"areas"];
	}
	
	return dict;
}



#pragma mark - KVC
- (void)setChart:(CHChart *)chart
{
	if (chart != _chart) {
		_chart = chart;
		
		// update sub-areas
		for (CHChartArea *subarea in _areas) {
			subarea.chart = _chart;
		}
	}
}




#pragma mark - Returning the View
/**
 *  Returns a CHChartAreaView instance, newly created if not previously done for the parentView, from the properties of the receiver (including sub-areas).
 */
- (CHChartAreaView *)viewForParent:(id)parentView
{
	// do we already have one?
	CHChartAreaView *view = [_knownViews objectForKey:parentView];
	if (view) {
		return view;
	}
	
	// nope, don't have one!
	Class viewClass = [CHChartAreaView registeredClassForType:_type];
	view = [viewClass new];
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
			CHChartAreaView *subview = [subarea viewForParent:self];
			[subviews addObject:subview];
		}
		view.areas = subviews;
	}
	
	// store and return
	if (!_knownViews) {
		self.knownViews = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableWeakMemory];
	}
	[_knownViews setObject:view forKey:parentView];
	
	return view;
}
						   
						   
						   
#pragma mark - Class Static Methods
/**
 *  Where to split the points in the "outline" property.
 *
 *  This usually is just the semi-colon, but we also add whitespace in case the spec is not 100% accurate.
 *  @return A character set at which to split the points in the "outline" property.
 */
+ (NSCharacterSet *)outlinePathSplitSet
{
	static NSCharacterSet *outlinePathSplitSet = nil;
	if (!outlinePathSplitSet) {
		NSMutableCharacterSet *set = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
		[set addCharactersInString:@";"];
		outlinePathSplitSet = [set copy];
	}
	
	return outlinePathSplitSet;
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
