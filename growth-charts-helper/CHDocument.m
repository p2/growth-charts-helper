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


- (id)init
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
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	// Add any code here that needs to be executed once the windowController has loaded the document's window.
}

+ (BOOL)autosavesInPlace
{
    return YES;
}



#pragma mark - Chart Handling
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



#pragma mark - File Reading and Writing
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	if (![@"DocumentType" isEqualToString:typeName]) {
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
	if (![@"DocumentType" isEqualToString:typeName]) {
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
