//
//  CHClickableView.h
//  growth-charts-helper
//
//  Created by Pascal Pfiffner on 12/22/12.
//  Copyright (c) 2012 CHIP. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/**
 *  A view that can be clicked to become first responder.
 */
@interface CHClickableView : NSView

@property (nonatomic, assign) BOOL active;

- (BOOL)makeFirstResponder;
- (void)didBecomeFirstResponder;
- (void)didResignFirstResponder;


@end
