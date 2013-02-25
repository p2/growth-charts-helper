//
//  CHClickableView.m
//  growth-charts-helper
//
//  Created by Pascal Pfiffner on 12/22/12.
//  Copyright (c) 2012 CHIP. All rights reserved.
//

#import "CHClickableView.h"


@interface CHClickableView () {
	BOOL clickStartedInside;
	BOOL clickDidMove;
}

@end


@implementation CHClickableView


#pragma mark - Active and First Responder
- (void)setActive:(BOOL)active
{
	if (active != _active) {
		_active = active;
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)acceptsFirstResponder
{
    return (clickStartedInside && !clickDidMove);
}

/**
 *  Disregards mouse movements to make the object first responder anyway.
 */
- (BOOL)makeFirstResponder
{
	clickStartedInside = YES;
	clickDidMove = NO;
	return [[self window] makeFirstResponder:self];
}

- (BOOL)becomeFirstResponder
{
	if ([self acceptsFirstResponder]) {
		if ([super becomeFirstResponder]) {
			[self didBecomeFirstResponder];
			return YES;
		}
	}
	return NO;
}

- (void)didBecomeFirstResponder
{
}

- (BOOL)resignFirstResponder
{
	BOOL didResign = [super resignFirstResponder];
	if (didResign) {
		[self didResignFirstResponder];
	}
	return didResign;
}

- (void)didResignFirstResponder
{
}



#pragma mark - Mouse Handling
- (void)mouseDown:(NSEvent *)theEvent
{
	clickStartedInside = YES;
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	if (clickStartedInside) {
		clickDidMove = YES;
	}
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	if (clickStartedInside) {
		clickDidMove = YES;
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if ([self acceptsFirstResponder]) {
		[[self window] makeFirstResponder:self];
	}
	clickStartedInside = NO;
	clickDidMove = NO;
}


@end
