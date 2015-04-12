/*
 CHChartAreaView.m
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

#import "CHChartAreaView.h"
#import "CHChartArea.h"
#import "CHChartPDFView.h"
#import "CHResizableChartAreaView.h"		// our subclass
#import "CHOutlineView.h"


@interface CHChartAreaView () {
	CGRect inParentRect;
}

@property (nonatomic, weak) CHOutlineView *outlineView;

@end


@implementation CHChartAreaView


- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self setup];
	}
	return self;
}

- (void)setup
{
}


#pragma mark - Data Types
/**
 *  This method searches all areas and returns a set of all data types that are used on the receiver
 */
- (NSSet *)allDataTypes
{
	NSMutableSet *used = [NSMutableSet set];
	
	for (CHChartAreaView *subarea in _areas) {
		[used unionSet:[subarea allDataTypes]];
	}
	return used;
}

/**
 *  This method searches all areas and returns a set of all data types that are used on the receiver for plotting areas
 */
- (NSSet *)plotDataTypes
{
	NSMutableSet *used = [NSMutableSet set];
	
	for (CHChartAreaView *subarea in _areas) {
		[used unionSet:[subarea plotDataTypes]];
	}
	return used;
}



#pragma mark - Content Handling
/**
 *  Redraw elements that have been changed (e.g. highlighted).
 *
 *  Default implementation calls "resetHighlight" on all sub-areas.
 */
- (void)resetHighlight
{
	for (CHChartAreaView *area in _areas) {
		[area resetHighlight];
	}
}

/**
 *  Resets cached values of the receiver and its subareas.
 *
 *  @attention If you override this method, call super implementation unless you really know what you're doing!
 */
- (void)reset
{
	for (CHChartAreaView *area in _areas) {
		[area reset];
	}
}

/**
 *  Call this to update the area.
 *
 *  The default implementation updates all its sub-areas; the call should be forwarded to all sub-areas even if data source is nil.
 */
- (void)updateWithDataSource:(id<CHChartDataSource>)dataSource
{
	for (CHChartAreaView *area in _areas) {
		[area updateWithDataSource:dataSource];
	}
}



#pragma mark - Adding to Views
/**
 *  This translates our relative position information into an actual frame within the given view.
 *
 *  This method is automatically called when the receiver is added as a subview, but you can call it manually if you don't add the area to a view but draw it
 *  by hand into a given context.
 */
- (void)positionInFrame:(CGRect)targetRect onView:(NSView *)aView pageSize:(CGSize)pageSize
{
	if (!CGRectIsEmpty(targetRect)) {
		self.pageSize = pageSize;
		inParentRect = targetRect;
		[self reposition];
		
		[aView addSubview:self];
	}
	
	// position subareas
	for (CHChartAreaView *area in _areas) {
		area.pageView = _pageView;
		[area positionInFrame:self.bounds onView:self pageSize:pageSize];
	}
}

/**
 *  This is usually called if the area's frame has changed
 */
- (void)reposition
{
	if (!CGRectIsEmpty(inParentRect)) {
		CGRect appliedRect = inParentRect;
		
		CGRect relFrame = _area.frame;
		appliedRect.origin.x += relFrame.origin.x * appliedRect.size.width;
		appliedRect.origin.y += relFrame.origin.y * appliedRect.size.height;
		appliedRect.size.width *= relFrame.size.width;
		appliedRect.size.height *= relFrame.size.height;
		
		self.frame = appliedRect;						// will cause setNeedsDisplay to be set if the size changed
	}
}

- (CHChartAreaView *)didAddArea:(CHChartArea *)area
{
	if (!area) {
		return nil;
	}
	
	// already have it
	for (CHChartAreaView *subarea in _areas) {
		if ([subarea.area isEqual:area]) {
			return subarea;
		}
	}
	
	// don't have it, make a view and add it to our array
	CHChartAreaView *areaView = [area viewForParent:self];
	areaView.pageView = _pageView;
	if (!_areas) {
		self.areas = @[areaView];
	}
	else {
		self.areas = [_areas arrayByAddingObject:areaView];
	}
	
	[areaView positionInFrame:self.bounds onView:self pageSize:_pageSize];
	return areaView;
}

- (void)didRemoveArea:(CHChartArea *)area
{
	if ([_areas count] > 0) {
		NSMutableArray *newAreas = [NSMutableArray arrayWithCapacity:[_areas count] - 1];
		for (CHChartAreaView *sibling in _areas) {
			if (sibling.area != area) {
				[newAreas addObject:sibling];
			}
			else {
				[sibling removeFromSuperview];
			}
		}
		self.areas = ([newAreas count] > 0) ? newAreas : nil;
	}
}



#pragma mark - First Responder
- (void)didBecomeFirstResponder
{
	[_pageView didBecomeFirstResponder:self];
	[self addOutline];
}

- (void)didResignFirstResponder
{
	if (_outlineView) {
		[_outlineView removeFromSuperview];
		[_outlineView.superview setNeedsDisplayInRect:_outlineView.frame];
		self.outlineView = nil;
	}
}



#pragma mark - Sizing
/**
 *  We override setFrame to update the relative frame when moving the box.
 */
- (void)setFrame:(NSRect)frameRect
{
	if (!NSEqualRects(self.frame, frameRect)) {
		[super setFrame:frameRect];
		
		// make sure we have a parent rect
		if (CGRectIsEmpty(inParentRect)) {
			inParentRect = CGRectMake(0.f, 0.f, 1.f, 1.f);
		}
		
		// update relative frame
		CGRect relFrame = CGRectZero;
		relFrame.origin.x = frameRect.origin.x / inParentRect.size.width;
		relFrame.origin.y = frameRect.origin.y / inParentRect.size.height;
		relFrame.size.width = frameRect.size.width / inParentRect.size.width;
		relFrame.size.height = frameRect.size.height / inParentRect.size.height;
		
		self.area.frame = relFrame;
	}
}

/**
 *  The rect in our own coordinate system describing the area needed to cover all our subviews.
 *
 *  Subclasses may override this to return the all-encompassing rectangle, default implementation returns the bounds extended to contain all sub-areas.
 *  @return The bounds covering all our subitems (which may be drawn outside of our frame)
 */
- (CGRect)boundingBox
{
	CGRect bounds = self.bounds;
	
	// our areas may lie outside our bounds, include them
	for (CHChartAreaView *subArea in _areas) {
		bounds = CGRectUnion(bounds, [subArea framingBox]);
	}
	
	return bounds;
}

/**
 *  The returned frame contains all our sub-areas; it utilizes the "boundingBox" method but applies the area's frame to have the correct origin.
 *  @return The bounding frame containing all our sub-areas.
 */
- (CGRect)framingBox
{
	CGRect frame = self.frame;
	CGRect bounding = [self boundingBox];
	bounding.origin.x += frame.origin.x;
	bounding.origin.y += frame.origin.y;
	
	return bounding;
}

/**
 *  The rect in our own coordinate system that describes our content rect.
 *
 *  By default just returns the bounds, but subclasses can override this to return a different rectangle (e.g. text boxes).
 *  @return The frame that defines the content area in our own coordinate systew
 */
- (CGRect)contentBox
{
	return self.bounds;
}



#pragma mark - Hit Detection
/**
 *  Collect all areas that are hit by the given point, which is in the coordinate system of our parent (!!)
 *
 *  @param point A CGPoint to test for a hit, in the coordinate system of our parent
 */
- (NSSet *)areasAtPoint:(CGPoint)point
{
	NSMutableSet *set = [NSMutableSet new];
	
	// translate the point into our coordinate system
	CGRect hit = self.frame;
	CGPoint relPoint = point;
	relPoint.x -= hit.origin.x;
	relPoint.y -= hit.origin.y;
	
	// loop the top level areas; if the subarea is hit, ask it to return the specific hit area, otherwise add the area itself
	for (CHChartAreaView *area in _areas) {
		NSSet *subSet = [area areasAtPoint:relPoint];
		if (subSet) {
			[set unionSet:subSet];
		}
	}
	
	// no sub-area hit, are we hit at all?
	if ([set count] < 1 && [self pointInside:relPoint withEvent:nil]) {
		[set addObject:self];
	}
	
	return set;
}


/**
 *  The point must be in the receiver's coordinate system (i.e. relative to its bounds).
 *
 *  If we have an outline, we use the outline as the boundaries.
 */
- (BOOL)pointInside:(CGPoint)point withEvent:(NSEvent *)event
{
	CGSize mySize = [self bounds].size;
	NSPoint location = NSMakePoint(point.x/mySize.width, point.y/mySize.height);
	
	if (_outline) {
		// TODO: implement?
	}
	
	return NSPointInRect(location, [self bounds]);
}



#pragma mark - Outline
- (NSBezierPath *)outline
{
	if (!_outline) {
		if ([self.area.outlinePoints count] > 0) {
			NSBezierPath *path = nil;
			
			// create the path
			for (NSValue *pointValue in self.area.outlinePoints) {
				if (!path) {
					path = [NSBezierPath new];
					[path moveToPoint:[pointValue pointValue]];
				}
				else {
					[path lineToPoint:[pointValue pointValue]];
				}
			}
			
			[path closePath];
			
			// flip it (it's upside down now)
			NSAffineTransform *transform = [NSAffineTransform transform];
			[transform scaleXBy:1.f yBy:-1.f];
			[transform translateXBy:0.f yBy:-1.f];
			
			self.outline = [transform transformBezierPath:path];
		}
	}
	return _outline;
}

- (void)addOutline
{
	return;
	if (!_outlineView) {
		CGRect outline = [self outlineBox];
		if (!CGRectIsEmpty(outline)) {
			CHOutlineView *slayer = [[CHOutlineView alloc] initWithFrame:outline];
			slayer.outline = _outline;
			slayer.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
			
			[self addSubview:slayer];
			self.outlineView = slayer;
		}
	}
}

/**
 *  A rect in our own coordinate system containing our outline, our bounds if we don't have one.
 *  @return The rect covering our outline, an empty rect if we don't have an outline
 */
- (CGRect)outlineBox
{
	if (self.outline) {
		CGSize mySize = [self bounds].size;
		CGRect scaledOutline = [_outline bounds];
		scaledOutline.origin.x *= mySize.width;
		scaledOutline.origin.y *= mySize.height;
		scaledOutline.size.width *= mySize.width;
		scaledOutline.size.height *= mySize.height;
		
		return scaledOutline;
	}
	
	return CGRectZero;
}



#pragma mark - Drawing
//- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
- (void)drawRect:(NSRect)dirtyRect
{
	[NSGraphicsContext saveGraphicsState];
	
	if (self.active) {
		[[NSColor colorWithDeviceRed:0.f green:1.f blue:0.f alpha:0.5f] setFill];
	}
	else {
		[[NSColor colorWithDeviceRed:0.f green:0.f blue:1.f alpha:0.25f] setFill];
	}
	
	[NSBezierPath fillRect:self.bounds];
	[NSGraphicsContext restoreGraphicsState];
}



#pragma mark - Class Registration
+ (Class)registeredClassForType:(NSString *)aType
{
	return [CHResizableChartAreaView class];
}



#pragma mark - Utilities
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <%p> %@, %d sub-areas", NSStringFromClass([self class]), self, NSStringFromCGRect(_area.frame), (int)[_areas count]];
}


@end
