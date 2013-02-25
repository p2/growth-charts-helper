//
//  CHOutlineLayer.m
//  growth-charts-helper
//
//  Created by Pascal Pfiffner on 2/25/13.
//  Copyright (c) 2013 CHIP. All rights reserved.
//

#import "CHOutlineView.h"


@implementation CHOutlineView



#pragma mark - Drawing
- (void)drawRect:(NSRect)dirtyRect
{
	if (_outline) {
		[NSGraphicsContext saveGraphicsState];
		
		// we need to fit entirely into our bounds
		NSRect bnds = self.bounds;
		NSRect rect = [_outline bounds];
		
		// transform to current size
		NSAffineTransform *transform = [NSAffineTransform transform];
		[transform scaleXBy:(bnds.size.width / rect.size.width) yBy:(bnds.size.height / rect.size.height)];
		[transform translateXBy:-rect.origin.x yBy:-rect.origin.y];
		NSBezierPath *outlinePath = [_outline copy];
		[outlinePath transformUsingAffineTransform:transform];
		
		// fill
		[[[NSColor orangeColor] colorWithAlphaComponent:0.5f] setFill];
		[outlinePath fill];
		
		[NSGraphicsContext restoreGraphicsState];
	}
}


@end
