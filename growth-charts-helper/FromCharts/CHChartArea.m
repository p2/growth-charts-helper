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

@end


@implementation CHChartArea


+ (id)newAreaOnChart:(CHChart *)chart withDictionary:(NSDictionary *)dict
{
	CHChartArea *this = [self new];
	this.chart = chart;
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
	
	// add sub-areas
	NSArray *areas = [dict objectForKey:@"areas"];
	if ([areas isKindOfClass:[NSArray class]] && [areas count] > 0) {
		NSMutableArray *myAreas = [NSMutableArray arrayWithCapacity:[areas count]];
		
		// loop sub-areas
		for (NSDictionary *areaDict in areas) {
			if ([areaDict isKindOfClass:[NSDictionary class]]) {
				CHChartArea *area = [CHChartArea newAreaOnChart:_chart withDictionary:areaDict];
				if (area) {
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
	
	// all properties
	[view setFromDictionary:_dictionary];
	
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
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <%p> type \"%@\", %d sub-areas", NSStringFromClass([self class]), self, _type, [_areas count]];
}


@end
