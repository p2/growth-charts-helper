//
//  CHChart.h
//  Charts
//
//  Created by Pascal Pfiffner on 4/12/12.
//  Copyright (c) 2012 Children's Hospital Boston. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHTypes.h"
#import "CHJSONHandling.h"

@class CHChart;
@class CHChartArea;
@class CHValue;
@class PPRange;


/**
 *  A chart data source can return data to be shown in a chart.
 */
@protocol CHChartDataSource <NSObject>

@required
/**
 *  Return the string value for the requested dataType.
 *
 *  The data source can interpret the data type however it choses; it is common to make data types the key path of a value for the data source, like
 *  "patient.name" to return the patient's name where the data source holds on to a "patient" property which responds to the "name" getter.
 */
- (NSString *)stringForDataType:(NSString *)dataType;

/**
 *  Returns a set full of CHMeasurementSet objects that contain the desired data types, sorted by date descending.
 */
- (NSArray *)measurementSetsContainingDataTypes:(NSSet *)dataTypes;

/**
 *  Return current age.
 */
- (CHValue *)currentAge;

@end



/**
 *  A class to represent a growth chart
 */
@interface CHChart : NSObject <CHJSONHandling>

@property (nonatomic, strong) id document;							///< The PDF document described by this chart

@property (nonatomic, copy) NSString *name;							///< The display name of this chart
@property (nonatomic, copy) NSString *sourceName;					///< The source name
@property (nonatomic, copy) NSString *sourceAcronym;				///< The acronym for the source
@property (nonatomic, copy) NSString *shortDescription;				///< A description of this chart
@property (nonatomic, copy) NSString *resourceName;					///< The file name in our bundle, if available
@property (nonatomic, copy) NSString *source;						///< Where this chart comes from, usually a URL
@property (nonatomic, assign) CHGender gender;						///< The gender found on this chart
@property (nonatomic, strong) PPRange *ageRange;					///< The age-range in months

@property (nonatomic, strong) NSSet *chartAreas;					///< The areas on the chart that can show data (CHChartArea objects)

+ (NSArray *)bundledCharts;

- (NSURL *)resourceURL;

- (NSUInteger)numAreas;
- (CHChartArea *)newAreaInParentArea:(CHChartArea *)parent;
- (void)addArea:(CHChartArea *)area;
- (void)removeArea:(CHChartArea *)area;


@end
