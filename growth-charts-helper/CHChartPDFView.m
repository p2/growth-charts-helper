/*
 CHChartPDFView.m
 growth-charts-helper
 
 Created by Pascal Pfiffner on 12/18/12.
 Copyright (c) 2012 CHIP. All rights reserved.
 
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

#import "CHChartPDFView.h"
#import "CHChart.h"
#import "CHChartArea.h"
#import "CHChartAreaView.h"


@interface CHChartPDFView (){
	CGSize lastSizeWhenPositioningAreas;
}

@property (nonatomic, strong) NSButton *zoomIn;
@property (nonatomic, strong) NSButton *zoomOut;

@property (nonatomic, strong) NSMutableSet *addedAreas;

@end


@implementation CHChartPDFView


#pragma mark - PDF Drawing
/**
 *  Called after the page has been drawn
 */
- (void)drawPagePost:(PDFPage *)page
{
	NSView *docView = [self documentView];
	if (CGSizeEqualToSize(lastSizeWhenPositioningAreas, docView.bounds.size)) {
		return;
	}
	
	NSUInteger pageNum = [self.document indexForPage:page] + 1;
	NSSize pageSize = [self rowSizeForPage:page];
	//NSRect pageBounds = [page boundsForBox:[self displayBox]];			// kPDFDisplayBoxCropBox is our default display mode, not kPDFDisplayBoxMediaBox
	NSRect pageFrame = NSMakeRect(0.f, 0.f, pageSize.width, pageSize.height);
	
	// remove old areas
	if ([_addedAreas count] > 0) {
		// TODO: Do NOT remove areas on other pages
		[_addedAreas makeObjectsPerformSelector:@selector(removeFromSuperviewWithoutNeedingDisplay)];
		[_addedAreas removeAllObjects];
	}
	if (!_addedAreas) {
		self.addedAreas = [NSMutableSet set];
	}
	
	// add our areas
	NSSet *areas = _chart.chartAreas;
	if ([areas count] > 0) {
		for (CHChartArea *area in areas) {
			if (pageNum == area.page) {
				CHChartAreaView *areaView = [area view];
				[areaView positionInFrame:pageFrame onView:docView pageSize:docView.bounds.size];
				
				[_addedAreas addObject:areaView];
			}
			else {
				DLog(@"Skipping area %@, not on page %lu", area, pageNum);
			}
		}
	}
	
	lastSizeWhenPositioningAreas = docView.bounds.size;
}



#pragma mark - View Tasks
- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	if (newSuperview) {
		[self addSubview:self.zoomIn];
		[self addSubview:self.zoomOut];
	}
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize
{
	[super resizeWithOldSuperviewSize:oldBoundsSize];
	[self layoutSubviews];
}

- (void)layoutSubviews
{
	// realign zoom buttons
	NSSize mySize = self.bounds.size;
	
	NSRect zoomFrame = _zoomIn.frame;
	zoomFrame.origin.x = mySize.width - zoomFrame.size.width;
	zoomFrame.origin.y = mySize.height - zoomFrame.size.height;
	_zoomIn.frame = zoomFrame;
	
	zoomFrame.origin.x -= zoomFrame.size.width;
	_zoomOut.frame = zoomFrame;
}


/**
 *  We need this to override PDFView subviews intercepting our mouse events.
 */
- (NSView *)hitTest:(NSPoint)aPoint
{
	/*/
	for (NSView *view in [self subviews]) {
		DLog(@"->  %@", view);
		for (NSView *view2 in [view subviews]) {
			DLog(@"-->  %@", view2);
			for (NSView *view3 in [view2 subviews]) {
				DLog(@"--->  %@", view3);
				for (NSView *view4 in [view3 subviews]) {
					DLog(@"---->  %@", view4);
					if ([view4 isKindOfClass:NSClassFromString(@"PDFDisplayView")]) {
						CGPoint inPoint = [view4 convertPoint:aPoint fromView:self];
						if (NSPointInRect(inPoint, view4.bounds)) {
							return self;
						}
					}
				}
			}
		}
	}	//*/
	return [super hitTest:aPoint];
}



#pragma mark - Mouse Clicks and Drags
- (void)mouseDown:(NSEvent *)theEvent
{
    // mouseInCloseBox and trackingCloseBoxHit are instance variables
    if (NSPointInRect([self convertPoint:[theEvent locationInWindow] fromView:nil], NSZeroRect)) {
    }
    else if ([theEvent clickCount] > 1) {
        [[self window] miniaturize:self];
        return;
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	//NSPoint windowOrigin;
	//NSWindow *window = [self window];
	
	//[self convertPoint:[theEvent locationInWindow] fromView:nil]
}

- (void)mouseUp:(NSEvent *)theEvent
{
    
}



#pragma mark - Mouse Wheel
- (void)scrollWheel:(NSEvent *)event
{
	if (event.deltaY < 0.f) {
		[self zoomOut:event];
	}
	else if (event.deltaY > 0.f) {
		[self zoomIn:event];
	}
	//DLog(@"%f %f %f", event.deltaX, event.deltaY, event.deltaZ);
}



#pragma mark - KVC
- (NSButton *)zoomIn
{
	if (!_zoomIn) {
		self.zoomIn = [[NSButton alloc] initWithFrame:NSMakeRect(0.f, 0.f, 39.f, 38.f)];
		//[_zoomIn setAutoresizingMask:NSViewMinXMargin];		// no luck, overriding setFrame:
		[_zoomIn setButtonType:NSMomentaryPushInButton];
		[_zoomIn setBezelStyle:NSCircularBezelStyle];
		[_zoomIn setTitle:@"+"];
		[_zoomIn setFont:[NSFont boldSystemFontOfSize:19.f]];
		[_zoomIn setAction:@selector(zoomIn:)];
		[_zoomIn setTarget:self];
	}
	return _zoomIn;
}

- (NSButton *)zoomOut
{
	if (!_zoomOut) {
		self.zoomOut = [[NSButton alloc] initWithFrame:NSMakeRect(0.f, 0.f, 39.f, 38.f)];
		//[_zoomIn setAutoresizingMask:NSViewMinXMargin];		// no luck, overriding setFrame:
		[_zoomOut setButtonType:NSMomentaryPushInButton];
		[_zoomOut setBezelStyle:NSCircularBezelStyle];
		[_zoomOut setTitle:@"-"];
		[_zoomOut setFont:[NSFont boldSystemFontOfSize:19.f]];
		[_zoomOut setAction:@selector(zoomOut:)];
		[_zoomOut setTarget:self];
	}
	return _zoomOut;
}


@end
