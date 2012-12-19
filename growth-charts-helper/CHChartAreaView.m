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


@interface CHChartAreaView ()

@end


@implementation CHChartAreaView


- (void)dealloc
{
	CGPathRelease(_outline);
}


- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
//		self.opaque = NO;
//		self.backgroundColor = [UIColor clearColor];
//		self.autoresizingMask = UIViewAutoresizingNone;
//		self.clipsToBounds = NO;
		
//		self.clearsContextBeforeDrawing = NO;
//		self.contentMode = UIViewContentModeRedraw;
//		((CATiledLayer *)self.layer).levelsOfDetail = 4;
//		((CATiledLayer *)self.layer).levelsOfDetailBias = 3;			// we use (levelsOfDetail - 1) because we only need more detail when zoomed in, no less details when zoomed out
	}
	return self;
}


- (void)setArea:(CHChartArea *)area
{
	if (area != _area) {
		_area = area;
		
		// set some properties
		self.origin = area.frame.origin;
		self.size = area.frame.size;
	}
}


/**
 *  The chart area model keeps a dictionary around, subclasses of the view can override this method to receive more properties for its configuration.
 *  Don't forget to call super, the base implementation assigns origin and size!
 */
- (void)setFromDictionary:(NSDictionary *)dict
{
	// outline path
	NSString *outlineString = [dict objectForKey:@"outline"];
	if ([outlineString isKindOfClass:[NSString class]]) {
		NSArray *points = [outlineString componentsSeparatedByCharactersInSet:[[self class] outlinePathSplitSet]];
		
		// at least 3 points are required
		if ([points count] > 2) {
			CGMutablePathRef outlinePath = nil;
			for (NSString *point in points) {
				NSPoint p = NSPointFromString(point);
				if (!outlinePath) {
					outlinePath = CGPathCreateMutable();
					CGPathMoveToPoint(outlinePath, NULL, p.x, p.y);
				}
				else {
					CGPathAddLineToPoint(outlinePath, NULL, p.x, p.y);
				}
			}
			
			// store in ivar and clean up
			CGPathCloseSubpath(outlinePath);
			self.outline = CGPathCreateCopy(outlinePath);
			CGPathRelease(outlinePath);
		}
		else {
			DLog(@"For \"outline\", at least 3 points must be defined, we only got this: %@", points);
		}
	}
	else if (outlineString) {
		DLog(@"\"outline\" must be a NSString, but I got a %@, discarding", NSStringFromClass([outlineString class]));
	}
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



#pragma mark - Sizing
/**
 *  This translates our relative position information into an actual frame within the given view.
 *
 *  This method is automatically called when the receiver is added as a subview, but you can call it manually if you don't add the area to a view but draw it
 *  by hand into a given context.
 */
- (void)positionInFrame:(CGRect)targetRect onView:(NSView *)aView pageSize:(CGSize)pageSize
{
	if (!CGRectIsEmpty(targetRect)) {
		CGRect appliedRect = targetRect;
		
		appliedRect.origin.x += _origin.x * appliedRect.size.width;
		//appliedRect.origin.y += _origin.y * appliedRect.size.height;
		appliedRect.origin.y += (1.f - _origin.y) * appliedRect.size.height - (_size.height * appliedRect.size.height);
		appliedRect.size.width *= _size.width;
		appliedRect.size.height *= _size.height;
		
		self.frame = appliedRect;						// will cause setNeedsDisplay to be set if the size changed
		self.pageSize = pageSize;
		
		[aView addSubview:self];
	}
	
	// position subareas
	for (CHChartAreaView *area in _areas) {
		area.pageView = _pageView;
		[area positionInFrame:self.bounds onView:self pageSize:pageSize];
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
 *  A rect in our own coordinate system containing our outline, our bounds if we don't have one.
 *  @return The rect covering our outline, an empty rect if we don't have an outline
 */
- (CGRect)outlineBox
{
	if (_outline) {
		CGSize mySize = [self bounds].size;
		CGRect scaledOutline = CGPathGetBoundingBox(_outline);
		scaledOutline.origin.x *= mySize.width;
		scaledOutline.origin.y *= mySize.height;
		scaledOutline.size.width *= mySize.width;
		scaledOutline.size.height *= mySize.height;
		
		return scaledOutline;
	}
	return self.bounds;
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



#pragma mark - Drawing
- (void)setActive:(BOOL)flag
{
	if (flag != _active) {
		_active = flag;
		[self setNeedsDisplay:YES];
	}
}


- (void)drawRect:(NSRect)dirtyRect
{
	[NSGraphicsContext saveGraphicsState];
	
	if (_active) {
		[[NSColor colorWithDeviceRed:0.f green:1.f blue:0.f alpha:0.25f] setFill];
	}
	else {
		[[NSColor colorWithDeviceRed:0.f green:0.f blue:1.f alpha:0.25f] setFill];
	}
	
	[NSBezierPath fillRect:self.bounds];
	[NSGraphicsContext restoreGraphicsState];
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


- (void)mouseDown:(NSEvent *)theEvent
{
	//DLog(@"%@ -- %@", self, theEvent);
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	if (_active) {
		
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[_pageView didGetClicked:self];
}



#pragma mark - Class Registration
+ (Class)registeredClassForType:(NSString *)aType
{
	return self;
}



#pragma mark - Class Static Methods
/**
 *  Where to split the points in the "outline" property.
 *
 *  This usually is just the semi-colon, but we also add whitespace in case the spec is not 100% accurate.
 *  @return A character set at which to split the points in the "outline" property.
 */
+ (NSCharacterSet *)outlinePathSplitSet
{
	static NSCharacterSet *outlinePathSplitSet = nil;
	if (!outlinePathSplitSet) {
		NSMutableCharacterSet *set = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
		[set addCharactersInString:@";"];
		outlinePathSplitSet = [set copy];
	}
	
	return outlinePathSplitSet;
}



#pragma mark - Utilities
- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ <%p> {%@,%@}, %d sub-areas", NSStringFromClass([self class]), self, NSStringFromCGPoint(_origin), NSStringFromCGSize(_size), (int)[_areas count]];
}


@end
