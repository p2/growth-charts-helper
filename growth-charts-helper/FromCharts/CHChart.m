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
#import "PPRange.h"


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
 *	Reads "Charts.plist" from the main bundle and returns the charts contained therein
 */
+ (NSArray *)bundledCharts
{
	NSArray *bundled = [[NSBundle mainBundle] pathsForResourcesOfType:@"json" inDirectory:nil];
	if ([bundled count] > 0) {
		NSString *prefix = @"grchrt";
		NSError *error = nil;
		NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[bundled count]];
		for (NSString *path in bundled) {
			
			// for now, all our charts start with "grchrt", so let's use this as a filter
			NSString *file = [path lastPathComponent];
			if (![prefix isEqualToString:[file substringToIndex:MIN([file length], [prefix length])]]) {
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
	self.sourceName = [dict objectForKey:@"sourceName"];
	self.sourceAcronym = [dict objectForKey:@"sourceAcronym"];
	self.shortDescription = [dict objectForKey:@"description"];
	self.source = [dict objectForKey:@"source"];
	self.gender = [[dict objectForKey:@"gender"] intValue];
	if (_gender != CHGenderFemale && _gender != CHGenderMale) {
		_gender = CHGenderUnknown;
	}
	self.ageRange = [PPRange rangeWithString:[dict objectForKey:@"ageRange"]];
	
	// find areas
	NSArray *areas = [dict objectForKey:@"areas"];
	if ([areas isKindOfClass:[NSArray class]] && [areas count] > 0) {
		NSMutableSet *chartSet = [NSMutableSet setWithCapacity:[areas count]];
		
		// instantiate areas
		for (NSDictionary *areaDict in areas) {
			if ([areaDict isKindOfClass:[NSDictionary class]]) {
				CHChartArea *area = [CHChartArea newAreaOnChart:self withDictionary:areaDict];
				if (area) {
					[chartSet addObject:area];
				}
			}
		}
		self.chartAreas = chartSet;
	}
	
	return YES;
}

- (id)jsonObject
{
	return nil;
}



#pragma mark - Chart Handling
- (NSURL *)resourceURL
{
	// split the filename into name and extension
	NSString *fileType = [_resourceName pathExtension];
	NSString *fileName = [_resourceName stringByDeletingPathExtension];
	
	// grab the bundle resource
	NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:fileName withExtension:fileType];
	if (!url) {
		DLog(@"There is no bundled resource named \"%@\" of type \"%@\"", fileName, fileType);
	}
	return url;
}



#pragma mark - Areas
- (NSUInteger)numAreas
{
	return [_chartAreas count];
}



#pragma mark - Utilities
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <%p> \"%@\" at %@, %d areas", NSStringFromClass([self class]), self, _name, _resourceName, (int)[_chartAreas count]];
}


@end
