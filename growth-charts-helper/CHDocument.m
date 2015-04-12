//
//  CHDocument.m
//  growth-charts-helper
//
//  Created by Pascal Pfiffner on 12/18/12.
//  Copyright (c) 2012 CHIP. All rights reserved.
//

#import "CHDocument.h"
#import "CHWindowController.h"
#import "CHChart.h"


@implementation CHDocument


- (instancetype)init
{
    if ((self = [super init])) {
		self.hasUndoManager = YES;
    }
    return self;
}

- (void)makeWindowControllers
{
	CHWindowController *controller = [[CHWindowController alloc] initWithWindowNibName:@"CHDocument"];
	[self addWindowController:controller];
	
	// if we created a new document, we don't yet have a chart, create one
	if (!_chart) {
		self.chart = [CHChart new];
	}
}

+ (BOOL)autosavesInPlace
{
    return YES;
}



#pragma mark - Chart Handling
- (void)setChart:(CHChart *)chart
{
	if (chart != _chart) {
		[self willChangeValueForKey:@"chart"];
		_chart = chart;
		[self didChangeValueForKey:@"chart"];
	}
}

/**
 *  When loading a JSON, looks if there is a PDF with the same name in that directory, and returns the URL.
 */
- (NSURL *)pdfWithSameName
{
	if (!_chart) {
		return nil;
	}
	
	NSString *fileName = [[self.fileURL lastPathComponent] stringByDeletingPathExtension];
	NSString *pdfName = [fileName stringByAppendingString:@".pdf"];
	NSString *pdfPath = [[[self.fileURL path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:pdfName];
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:pdfPath]) {
		return [NSURL fileURLWithPath:pdfPath];
	}
	return nil;
}

/**
 *  We call this when we load a PDF; if the document does not yet have a name, we use the PDF name.
 */
- (void)didLoadPDFAtURL:(NSURL *)pdfURL
{
	if (!pdfURL || [self fileURL]) {
		return;
	}
	
	// set the document URL
	NSString *fileName = [[pdfURL lastPathComponent] stringByDeletingPathExtension];
	NSString *jsonName = [fileName stringByAppendingString:@".json"];
	NSString *jsonPath = [[[pdfURL path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:jsonName];
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:jsonPath]) {
		DLog(@"There already exists a JSON with the same name as this PDF at %@", jsonPath);
	}
	else {
		self.fileURL = [NSURL fileURLWithPath:jsonPath];
	}
}



#pragma mark - File Reading and Writing
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	if (![@"Growth Chart JSON" isEqualToString:typeName]) {
		if (NULL != outError) {
			NSString *errorMessage = [NSString stringWithFormat:@"I don't know how to write data of type \"%@\"", typeName];
			NSDictionary *info = @{NSLocalizedDescriptionKey: errorMessage};
			*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:info];
		}
		return nil;
	}
	
	// grab json object
	id json = [_chart jsonObject];
	if (!json) {
		if (NULL != outError) {
			NSString *errorMessage = [NSString stringWithFormat:@"The chart did not produce a JSON object, but this: %@", json];
			NSDictionary *info = @{NSLocalizedDescriptionKey: errorMessage};
			*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:info];
		}
		return nil;
	}
	
	// serialize
	return [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:outError];
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	if (![@"Growth Chart JSON" isEqualToString:typeName]) {
		if (NULL != outError) {
			NSString *errorMessage = [NSString stringWithFormat:@"I don't know how to read data of type \"%@\"", typeName];
			NSDictionary *info = @{NSLocalizedDescriptionKey: errorMessage};
			*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:info];
		}
		return NO;
	}
	
	self.chart = nil;
	NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:outError];
	if ([dict isKindOfClass:[NSDictionary class]]) {
		self.chart = [CHChart newFromJSONObject:dict];
	}
	else if (NULL != outError) {
		NSDictionary *info = @{NSLocalizedDescriptionKey: @"JSON parsing did not produce a dictionary, cannot read"};
		*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:info];
	}
	
	return (nil != _chart);
}


@end
