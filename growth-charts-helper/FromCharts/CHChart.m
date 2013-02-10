//
//  CHChart.m
//  Charts
//
//  Created by Pascal Pfiffner on 4/12/12.
//  Copyright (c) 2012 Children's Hospital Boston. All rights reserved.
//

#import "CHChart.h"
#import "CHChartArea.h"
#import "CHValue.h"
#import "CHUnit.h"
#import "PPRange.h"
#import "NSDecimalNumber+Extension.h"


@interface CHChart ()

@end


@implementation CHChart


#pragma mark - Retrieving Charts
/**
 *  Instantiates from a dictionary with our defined charts data model.
 *
 *  See the separate project for the data model.
 *  @param object The dictionary describing a growth chart
 */
+ (id)newFromJSONObject:(id)object
{
	CHChart *chart = [CHChart new];
	if ([chart setFromJSONObject:object]) {
		return chart;
	}
	
	return nil;
}

/**
 *  Finds all JSON files in the bundle, checks if they start with a given prefix, and assumes that those are charts if they do.
 */
+ (NSArray *)bundledCharts
{
	NSArray *bundled = [[NSBundle mainBundle] pathsForResourcesOfType:@"json" inDirectory:nil];
	if ([bundled count] > 0) {
		NSArray *prefixes = @[@"WHO.2006", @"CDC.2000"];
		NSError *error = nil;
		NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[bundled count]];
		for (NSString *path in bundled) {
			
			// check if they have one of our prefixes
			NSString *file = [path lastPathComponent];
			BOOL hasPrefix = NO;
			for (NSString *prefix in prefixes) {
				if ([prefix isEqualToString:[file substringToIndex:MIN([file length], [prefix length])]]) {
					hasPrefix = YES;
					break;
				}
			}
			
			if (!hasPrefix) {
				continue;
			}
			
			// ok, this should be a growth-chart-describing JSON file
			NSData *json = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:&error];
			if (json) {
				NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:json options:0 error:&error];
				if ([dict isKindOfClass:[NSDictionary class]]) {
					CHChart *chart = [self newFromJSONObject:dict];
					if (chart) {
						chart.resourceName = [[[path lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
						[arr addObject:chart];
					}
				}
				else {
					DLog(@"Error decoding %@: %@", path, [error localizedDescription]);
				}
			}
			else {
				DLog(@"Error reading %@: %@", path, [error localizedDescription]);
			}
		}
		
		// sort by age, WHO first then by age range
		[arr sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			CHChart *chart1 = (CHChart *)obj1;
			CHChart *chart2 = (CHChart *)obj2;
			
			NSComparisonResult acro = [chart2.sourceAcronym caseInsensitiveCompare:chart1.sourceAcronym];
			if (NSOrderedSame != acro) {
				return acro;
			}
			
			// same source, order by age range
			PPRange *range1 = chart1.ageRangeMonths;
			PPRange *range2 = chart2.ageRangeMonths;
			
			NSComparisonResult lower = [range1.from compare:range2.from];
			if (NSOrderedSame == lower) {
				return [range1.to compare:range2.to];
			}
			return lower;
		}];
		
		return arr;
	}
	
	DLog(@"No bundled resources found");
	return nil;
}



#pragma mark - JSON Handling
- (BOOL)setFromJSONObject:(id)dict
{
	if (![dict isKindOfClass:[NSDictionary class]]) {
		DLog(@"I need a dictionary, but got: %@", dict);
		return NO;
	}
	
	self.name = [dict objectForKey:@"name"];
	self.source = [dict objectForKey:@"source"];
	self.sourceName = [dict objectForKey:@"sourceName"];
	self.sourceAcronym = [dict objectForKey:@"sourceAcronym"];
	self.shortDescription = [dict objectForKey:@"description"];
	self.gender = [[dict objectForKey:@"gender"] intValue];
	if (_gender != CHGenderFemale && _gender != CHGenderMale) {
		_gender = CHGenderUnknown;
	}
	
	// find areas
	NSArray *areas = [dict objectForKey:@"areas"];
	if ([areas isKindOfClass:[NSArray class]]) {
		if ([areas count] > 0) {
			NSMutableSet *chartSet = [NSMutableSet setWithCapacity:[areas count]];
			
			// instantiate areas
			for (NSDictionary *areaDict in areas) {
				CHChartArea *area = [CHChartArea newFromJSONObject:areaDict];
				if (area) {
					area.chart = self;
					area.topmost = YES;
					[chartSet addObject:area];
				}
			}
			self.chartAreas = chartSet;
		}
	}
	else if (areas) {
		DLog(@"\"areas\" must be an array, but I got a %@, discarding", NSStringFromClass([areas class]));
	}
	
	return YES;
}

/**
 *  Will create a dictionary representing this chart.
 */
- (id)jsonObject
{
	NSMutableDictionary *dict = [NSMutableDictionary new];
	
	// fill our properties
	if ([_name length] > 0) {
		[dict setObject:_name forKey:@"name"];
	}
	if ([_source length] > 0) {
		[dict setObject:_source forKey:@"source"];
	}
	if ([_sourceName length] > 0) {
		[dict setObject:_sourceName forKey:@"sourceName"];
	}
	if ([_sourceAcronym length] > 0) {
		[dict setObject:_sourceAcronym forKey:@"sourceAcronym"];
	}
	if ([_shortDescription length] > 0) {
		[dict setObject:_shortDescription forKey:@"description"];
	}
	[dict setObject:[NSNumber numberWithInt:_gender] forKey:@"gender"];
	
	// add our areas
	if ([_chartAreas count] > 0) {
		NSMutableArray *areas = [NSMutableArray arrayWithCapacity:[_chartAreas count]];
		
		// we sort the area set so that versioned JSON files look the same as much as possible
		NSSortDescriptor *rectSorter = [NSSortDescriptor sortDescriptorWithKey:@"frameString" ascending:NO];
		for (CHChartArea *area in [_chartAreas sortedArrayUsingDescriptors:@[rectSorter]]) {
			id obj = [area jsonObject];
			if (obj) {
				[areas addObject:obj];
			}
		}
		
		[dict setObject:areas forKey:@"areas"];
	}
	
	return dict;
}



#pragma mark - Chart Handling
- (NSURL *)resourceURL
{
	if (!_resourceURL) {
		// split the filename into name and extension
		NSString *fileType = [_resourceName pathExtension];
		NSString *fileName = [_resourceName stringByDeletingPathExtension];
		
		// grab the bundle resource
		NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:fileName withExtension:fileType];
		if (!url) {
			DLog(@"There is no bundled resource named \"%@\" of type \"%@\"", fileName, fileType);
		}
		self.resourceURL = url;
	}
	return _resourceURL;
}



#pragma mark - Areas
- (NSUInteger)numAreas
{
	return [_chartAreas count];
}

- (CHChartArea *)newAreaInParentArea:(CHChartArea *)parent
{
	CHChartArea *newArea = [CHChartArea new];
	newArea.chart = self;
	newArea.parent = parent;
	newArea.frame = CGRectMake(0.25f, 0.25f, 0.5f, 0.5f);
	newArea.type = @"text";
	
	[self addArea:newArea];
	return newArea;
}

- (void)addArea:(CHChartArea *)area
{
	// it's a subarea
	if (area.parent) {
		[area.parent addArea:area];
	}
	
	// root area
	else {
		area.topmost = YES;
		if (_chartAreas) {
			self.chartAreas = [_chartAreas setByAddingObject:area];
		}
		else {
			self.chartAreas = [NSSet setWithObject:area];
		}
	}
}

- (void)removeArea:(CHChartArea *)area
{
	BOOL hadParent = (nil != area.parent);

	[area remove];
	
	// root area, update area set
	if (!hadParent) {
		NSMutableSet *newAreas = [NSMutableSet setWithCapacity:[_chartAreas count] - 1];
		for (CHChartArea *subarea in _chartAreas) {
			if (area != subarea) {
				[newAreas addObject:subarea];
			}
		}
		self.chartAreas = newAreas;
	}
}



#pragma mark - Data Types
/**
 *  Returns a set with all data types that this chart can plot
 */
- (NSSet *)plotDataTypes
{
	NSMutableSet *used = [NSMutableSet setWithCapacity:2];
	
	for (CHChartArea *area in _chartAreas) {
		[used unionSet:[area plotDataTypes]];
	}
	
	return used;
}

/**
 *  @return YES if the chart has at least one area with the given data type
 */
- (BOOL)hasAreaWithDataType:(NSString *)dataType
{
	for (CHChartArea *area in _chartAreas) {
		if ([area hasDataType:dataType recursive:YES]) {
			return YES;
		}
	}
	
	return NO;
}

/**
 *  @return YES if at least one plot area plots the given data type;
 */
- (BOOL)plotsAreaWithDataType:(NSString *)dataType
{
	for (CHChartArea *area in _chartAreas) {
		if ([area plotsDataType:dataType recursive:YES]) {
			return YES;
		}
	}
	
	return NO;
}


/**
 *  Creates a range from the minimum and maximum values for "age" plots that it finds in top-level (!) areas.
 */
- (PPRange *)ageRangeMonths
{
	if (!_ageRangeMonths) {
		NSDecimalNumber *min = nil;
		NSDecimalNumber *max = nil;
		CHUnit *month = [CHUnit newWithPath:@"age.month"];
		
		// find plot areas
		for (CHChartArea *area in _chartAreas) {
			if ([@"plot" isEqualToString:area.type]) {
				
				// x axis
				if ([@"age" isEqualToString:area.xAxisDataType]) {
					CHUnit *xUnit = [CHUnit newWithPath:area.xAxisUnitName];
					NSDecimalNumber *xMin = [xUnit convertNumber:[area.xAxisFrom smallerNumber:area.xAxisTo] toUnit:month];
					NSDecimalNumber *xMax = [xUnit convertNumber:[area.xAxisFrom greaterNumber:area.xAxisTo] toUnit:month];
					
					if (!min || NSOrderedAscending == [xMin compare:min]) {
						min = xMin;
					}
					
					if (!max || NSOrderedDescending == [xMax compare:max]) {
						max = xMax;
					}
				}
				
				// y axis
				if ([@"age" isEqualToString:area.yAxisDataType]) {
					CHUnit *yUnit = [CHUnit newWithPath:area.yAxisUnitName];
					NSDecimalNumber *yMin = [yUnit convertNumber:[area.yAxisFrom smallerNumber:area.yAxisTo] toUnit:month];
					NSDecimalNumber *yMax = [yUnit convertNumber:[area.yAxisFrom greaterNumber:area.yAxisTo] toUnit:month];
					
					if (!min || NSOrderedAscending == [yMin compare:min]) {
						min = yMin;
					}
					
					if (!max || NSOrderedDescending == [yMax compare:max]) {
						max = yMax;
					}
				}
			}
		}
		
		self.ageRangeMonths = [PPRange rangeFrom:min to:max];
	}
	return _ageRangeMonths;
}



#pragma mark - Utilities
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <%p> \"%@\" at %@, %d areas", NSStringFromClass([self class]), self, _name, _resourceName, (int)[_chartAreas count]];
}


@end
