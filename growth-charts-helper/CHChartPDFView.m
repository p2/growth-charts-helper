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

@end


@implementation CHChartPDFView


- (void)dealloc
{
	self.activeArea = nil;
}



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
	NSRect pageFrame = NSMakeRect(0.f, 0.f, pageSize.width, pageSize.height);
	NSSize origSize = [page boundsForBox:[self displayBox]].size;				// kPDFDisplayBoxCropBox is our default display mode, not kPDFDisplayBoxMediaBox
	
	// add/reposition our areas
	NSSet *areas = _chart.chartAreas;
	if ([areas count] > 0) {
		for (CHChartArea *area in areas) {
			if (!area.page || pageNum == area.page) {
				CHChartAreaView *areaView = [area viewForParent:self];
				areaView.pageView = self;
				[areaView positionInFrame:pageFrame onView:docView pageSize:origSize];
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
	NSSize mySize = self.bounds.size;
	
	// realign zoom buttons
	NSRect zoomFrame = _zoomIn.frame;
	zoomFrame.origin.x = mySize.width - zoomFrame.size.width;
	zoomFrame.origin.y = mySize.height - zoomFrame.size.height;
	_zoomIn.frame = zoomFrame;
	
	zoomFrame.origin.x -= zoomFrame.size.width;
	_zoomOut.frame = zoomFrame;
}



#pragma mark - Area Handling
- (void)setActiveArea:(CHChartAreaView *)activeArea
{
	if (activeArea != _activeArea) {
		_activeArea.active = NO;
		[self willChangeValueForKey:@"activeArea"];
		_activeArea = activeArea;
		[self didChangeValueForKey:@"activeArea"];
		_activeArea.active = YES;
	}
}

- (void)didBecomeFirstResponder:(CHChartAreaView *)areaView
{
	self.activeArea = areaView;
	
	// make topmost view
	CHChartAreaView *topmost = areaView;
	while ([[topmost superview] isKindOfClass:[CHChartAreaView class]]) {
		topmost = (CHChartAreaView *)[topmost superview];
	}
	
	NSView *currentTopmost = [[[topmost superview] subviews] lastObject];
	if (currentTopmost != topmost) {
		[topmost removeFromSuperview];
		[[currentTopmost superview] addSubview:topmost positioned:NSWindowAbove relativeTo:currentTopmost];
		[areaView makeFirstResponder];
	}
}

/**
 *  We only handle top-level areas here.
 */
- (CHChartAreaView *)didAddArea:(CHChartArea *)area
{
	if (!area || area.parent) {
		return nil;
	}
	
	// place
	NSView *docView = [self documentView];
	PDFPage *currentPage = [self.document pageAtIndex:0];		// TODO: support multi-page docs
	NSSize pageSize = [self rowSizeForPage:currentPage];
	NSRect pageFrame = NSMakeRect(0.f, 0.f, pageSize.width, pageSize.height);
	NSSize origSize = [currentPage boundsForBox:[self displayBox]].size;
	
	CHChartAreaView *areaView = [area viewForParent:self];
	areaView.pageView = self;
	[areaView positionInFrame:pageFrame onView:docView pageSize:origSize];
	
	// first responder and return
	[areaView makeFirstResponder];
	
	return areaView;
}

/**
 *  Removes the given area.
 */
- (void)didRemoveArea:(CHChartArea *)area
{
	if ([area hasViewForParent:self]) {
		CHChartAreaView *areaView = [area viewForParent:self];
		[areaView removeFromSuperview];
	}
}



#pragma mark - Mouse Handling
- (PDFAreaOfInterest)areaOfInterestForMouse:(NSEvent *)theEvent
{
	return kPDFControlArea;
}

- (void)setCursorForAreaOfInterest:(PDFAreaOfInterest)area
{
//	[[NSCursor openHandCursor] set];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	self.activeArea = nil;
	[[self window] makeFirstResponder:self];
}

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
		//[_zoomIn setAutoresizingMask:NSViewMinXMargin];		// no luck, utilizing layoutSubviews
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
		//[_zoomOut setAutoresizingMask:NSViewMinXMargin];
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
