/*
 CHResizableChartAreaView.m
 growth-charts-helper
 
 Created by Pascal Pfiffner on 12/19/12.
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

#import "CHResizableChartAreaView.h"


@interface CHResizableChartAreaView () {
	NSPoint dragStartPoint;
	NSInteger mouseActionEffect;				// 0 = drag, 1 and -1 = resize width, 2 and -2 = resize height
}

@property (nonatomic, strong) NSTrackingArea *tracker;

@end


@implementation CHResizableChartAreaView

/**
 *  We add tracking areas upon setup.
 */
- (void)setup
{
	[super setup];
	[self updateTrackingAreas];
}



#pragma mark - Tracking Areas
- (void)updateTrackingAreas
{
	// full size tracker
	if (_tracker) {
		[self removeTrackingArea:_tracker];
	}
	self.tracker = [[NSTrackingArea alloc] initWithRect:self.bounds
												options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow)		// NSTrackingCursorUpdate
												  owner:self
											   userInfo:nil];
	[self addTrackingArea:_tracker];
}

- (void)cursorUpdateDOESNOTWORKLIKEIWANTITTOWORK:(NSEvent *)theEvent
{
	if (self.active) {
		NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		NSSize mySize = self.bounds.size;
		
		if (location.x < 3.f) {								// resize left
			[[NSCursor resizeLeftRightCursor] set];
		}
		else if (location.x > mySize.width - 3.f) {			// resize right
			[[NSCursor resizeLeftRightCursor] set];
		}
		else if (location.y < 3.f) {						// resize bottom
			[[NSCursor resizeUpDownCursor] set];
		}
		else if (location.y > mySize.height - 3.f) {		// resize right
			[[NSCursor resizeUpDownCursor] set];
		}
		else {												// drag
			[[NSCursor openHandCursor] set];
		}
	}
	else {
		[[NSCursor pointingHandCursor] set];
	}
}



#pragma mark - Mouse Handling
- (void)mouseEntered:(NSEvent *)theEvent
{
	[super mouseEntered:theEvent];
	
	if (self.active) {
		[[NSCursor openHandCursor] push];
	}
	else {
		[[NSCursor pointingHandCursor] push];
	}
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	[super mouseMoved:theEvent];
	
	// mouse moves but does NOT drag
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if (self.active && NSPointInRect(location, self.bounds)) {
		NSSize mySize = self.bounds.size;
		
		if (location.x < 3.f) {								// resize left
			mouseActionEffect = -1;
			[[NSCursor resizeLeftRightCursor] set];
		}
		else if (location.x > mySize.width - 3.f) {			// resize right
			mouseActionEffect = 1;
			[[NSCursor resizeLeftRightCursor] set];
		}
		else if (location.y < 3.f) {						// resize bottom
			mouseActionEffect = -2;
			[[NSCursor resizeUpDownCursor] set];
		}
		else if (location.y > mySize.height - 3.f) {		// resize right
			mouseActionEffect = 2;
			[[NSCursor resizeUpDownCursor] set];
		}
		else {												// drag
			mouseActionEffect = 0;
			[[NSCursor openHandCursor] set];
		}
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[super mouseDown:theEvent];
	
	if (self.active) {
		dragStartPoint = [theEvent locationInWindow];
		[[NSCursor closedHandCursor] push];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	[super mouseDragged:theEvent];
	
	// mouse drags
	if (self.active) {
		NSPoint currentPoint = [theEvent locationInWindow];
		NSRect myFrame = self.frame;
		
		// move it
		if (0 == mouseActionEffect) {
			myFrame.origin.x -= dragStartPoint.x - currentPoint.x;
			myFrame.origin.y -= dragStartPoint.y - currentPoint.y;
		}
		
		// resize width
		else if (1 == ABS(mouseActionEffect)) {
			CGFloat diff = currentPoint.x - dragStartPoint.x;
			myFrame.size.width += diff * mouseActionEffect;
			if (mouseActionEffect < 0) {
				myFrame.origin.x -= -1 * diff;
			}
		}
		
		// resize height
		else if (2 == ABS(mouseActionEffect)) {
			CGFloat diff = currentPoint.y - dragStartPoint.y;
			myFrame.size.height += diff * (mouseActionEffect / 2);
			if (mouseActionEffect < 0) {
				myFrame.origin.y -= -1* diff;
			}
		}
		
		self.frame = myFrame;
		dragStartPoint = currentPoint;
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[super mouseUp:theEvent];
	
	if (self.active) {
		dragStartPoint = NSZeroPoint;
		[NSCursor pop];
	}
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[super mouseExited:theEvent];
	[NSCursor pop];
}



#pragma mark - First Responder
- (void)didBecomeFirstResponder
{
	[super didBecomeFirstResponder];
}


@end
