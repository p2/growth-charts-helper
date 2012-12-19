/*
 CHDocumentController.h
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

#import <Cocoa/Cocoa.h>

@class CHChart;
@class CHChartArea;
@class CHChartPDFView;
@class CHDropView;


/**
 *	The window controller for our document.
 */
@interface CHWindowController : NSWindowController <NSSplitViewDelegate>

@property (nonatomic, readonly, strong) CHChart *chart;
@property (nonatomic, readonly, weak) CHChartArea *activeArea;
@property (nonatomic, readonly, strong) CHChartPDFView *pdf;

@property (nonatomic, weak) IBOutlet NSView *leftPane;
@property (nonatomic, weak) IBOutlet NSView *rightPane;
@property (nonatomic, strong) IBOutlet CHDropView *dropWell;
@property (nonatomic, weak) IBOutlet NSTextField *pdfFoundLabel;
@property (nonatomic, weak) IBOutlet NSButton *pdfFoundButton;
@property (nonatomic, weak) IBOutlet NSTabView *optionsBox;
@property (nonatomic, weak) IBOutlet NSBox *hierarchyBox;

- (void)loadPDFAt:(NSURL *)url;
- (IBAction)handleFoundPDF:(id)sender;
- (void)unloadPDF:(id)sender;


@end
