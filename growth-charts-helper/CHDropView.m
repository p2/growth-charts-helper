/*
 CHDropView.m
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

#import "CHDropView.h"

NSString *const CHDropViewDroppedItemsNotificationName = @"CHDropViewDroppedItemsNotification";
NSString *const CHDropViewDroppedItemsKey = @"CHDropViewDroppedItems";


@interface CHDropView ()

@end


@implementation CHDropView


#pragma mark - Dragging and Dropping
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
	
	// too many?
	NSArray *items = [pboard pasteboardItems];
	if (!_acceptMultiple && [items count] > 1) {
		return NSDragOperationNone;
	}
	
	// the right kind?
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	for (NSPasteboardItem *item in items) {
		NSString *urlString = [item stringForType:(NSString *)kUTTypeFileURL];
		NSURL *url = [NSURL URLWithString:urlString];
		
		// determine file type
		NSString *utiType = [ws typeOfFile:[url path] error:nil];
		for (NSString *accType in _acceptedTypes) {
			if (![ws type:utiType conformsToType:accType]) {
				self.highlighted = NO;
				return NSDragOperationNone;
			}
		}
	}
	
	self.highlighted = YES;
    return NSDragOperationEvery;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	self.highlighted = NO;
}

/**
 *  Sent when the item is being dropped.
 */
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

/**
 *  Sent when "prepareForDragOperation:" returns YES.
 */
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	// notify of dropped items
	NSPasteboard *pboard = [sender draggingPasteboard];
	NSArray *dropped = [pboard pasteboardItems];
	[[NSNotificationCenter defaultCenter] postNotificationName:CHDropViewDroppedItemsNotificationName object:self userInfo:@{CHDropViewDroppedItemsKey: dropped}];
	
	return YES;
}

/**
 *  Sent when "performDragOperation:" returned YES.
 */
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	self.highlighted = NO;
}



#pragma mark - KVC
- (void)setHighlighted:(BOOL)flag
{
	if (flag != _highlighted) {
		_highlighted = flag;
		
		// highlight
		if (_highlighted) {
			[self setBoxType:NSBoxCustom];
			[self setBorderColor:[NSColor keyboardFocusIndicatorColor]];
			[self setCornerRadius:5.f];
			[self setBorderWidth:5.f];
			[self setFillColor:[NSColor colorWithDeviceWhite:0.f alpha:0.1f]];
			[self setContentViewMargins:CGSizeMake(-4.f, -4.f)];
		}
		
		// not
		else {
			[self setBoxType:NSBoxPrimary];
			[self setContentViewMargins:CGSizeZero];
		}
		
		[self setNeedsDisplay:YES];
	}
}


@end
