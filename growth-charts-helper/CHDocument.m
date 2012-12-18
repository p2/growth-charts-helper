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
		// Add your subclass-specific initialization here.
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



#pragma mark - File Reading and Writing
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	// Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
	// You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
	NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
	@throw exception;
	return nil;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	DLog(@"type: %@", typeName);
	NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:outError];
	if ([dict isKindOfClass:[NSDictionary class]]) {
		self.chart = [CHChart newFromJSONObject:dict];
	}
	return (nil != _chart);
}


@end
