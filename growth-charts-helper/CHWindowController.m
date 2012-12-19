/*
 CHDocumentController.m
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

#import "CHWindowController.h"
#import "CHDocument.h"
#import "CHChartPDFView.h"
#import "CHChartAreaView.h"
#import "CHChartArea.h"
#import "CHDropView.h"


@interface CHWindowController () {
	NSUInteger currentAreaIndex;
}

@property (nonatomic, readwrite, weak) CHChartArea *activeArea;
@property (nonatomic, readwrite, strong) CHChartPDFView *pdf;

@property (nonatomic, strong) NSMutableArray *currentAreaStack;

- (CHDocument *)pdfDocument;
- (void)didDropFiles:(NSNotification *)notification;
- (void)updateFoundPDFStatus;

@end


@implementation CHWindowController


#pragma mark - View Handling
- (void)awakeFromNib
{
	// setup drop area
	_dropWell.acceptedTypes = [NSSet setWithObject:NSPasteboardTypePDF];
    [_dropWell registerForDraggedTypes:@[NSFilenamesPboardType]];
	
	// does our file have a PDF?
	NSURL *url = [[self pdfDocument] pdfWithSameName];
	[self loadPDFAt:url];
	[self updateFoundPDFStatus];
	
	// register for notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDropFiles:) name:CHDropViewDroppedItemsNotificationName object:nil];
}

- (void)didDropFiles:(NSNotification *)notification
{
	NSArray *items = [[notification userInfo] objectForKey:CHDropViewDroppedItemsKey];
	if (1 == [items count]) {
		NSPasteboardItem *item = [items lastObject];
		NSString *urlString = [item stringForType:(NSString *)kUTTypeFileURL];
		NSURL *url = [NSURL URLWithString:urlString];
		
		[self loadPDFAt:url];
	}
	else {
		DLog(@"We can only accept one item");
	}
}



#pragma mark - PDF Handling
- (void)loadPDFAt:(NSURL *)url
{
	DLog(@"--> %@", url);
	if (!url) {
		return;
	}
	if ([_pdf.document.documentURL isEqual:url]) {
		DLog(@"Already loaded");
		return;
	}
	
	// get rid of the old view
	[self unloadPDF:nil];
	
	// create the PDF doc view
	self.pdf = [CHChartPDFView new];
	_pdf.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
	_pdf.allowsDragging = NO;
	_pdf.autoScales = NO;
	_pdf.displaysPageBreaks = NO;		// if we set this to YES, PDFKit adds a nice border around the page which offsets the actual PDF page and our areas are not correctly aligned
		
	PDFDocument *pdfDoc = [[PDFDocument alloc] initWithURL:url];
	_pdf.document = pdfDoc;
	_pdf.chart = self.chart;
	
	// add as subview
	_pdf.frame = _leftPane.bounds;
	[_dropWell removeFromSuperview];
	[_leftPane addSubview:_pdf];
	[_pdf layoutSubviews];
	
	// we need to observe the active area
	[_pdf addObserver:self forKeyPath:@"activeArea" options:0 context:NULL];
	
	// update button
	_pdfFoundButton.title = @"Unload PDF";
	[_pdfFoundButton setEnabled:YES];
}

- (IBAction)handleFoundPDF:(id)sender
{
	// got it loaded already, unload
	if (_pdf) {
		[self unloadPDF:sender];
		return;
	}
	
	// none yet, load
	NSURL *url = [[self pdfDocument] pdfWithSameName];
	if (!url) {
		_pdfFoundLabel.stringValue = @"Drop the respective PDF to the left";
		[_pdfFoundButton setEnabled:NO];
		return;
	}
	
	[self loadPDFAt:url];
}

- (void)unloadPDF:(id)sender
{
	// remove PDF
	if (_pdf) {
		[_pdf removeObserver:self forKeyPath:@"activeArea"];
		[_pdf removeFromSuperview];
		self.pdf = nil;
	}
	
	// update button and add drop well
	[self updateFoundPDFStatus];
	
	NSSize targetSize = _leftPane.bounds.size;
	NSRect dropFrame = _dropWell.frame;
	dropFrame.origin.x = roundf((targetSize.width - dropFrame.size.width) / 2);
	dropFrame.origin.y = roundf((targetSize.height - dropFrame.size.height) / 2);
	_dropWell.frame = dropFrame;
	[_leftPane addSubview:_dropWell];
}

- (void)updateFoundPDFStatus
{
	NSURL *url = [[self pdfDocument] pdfWithSameName];
	if (!url) {
		_pdfFoundLabel.stringValue = @"Drop the respective PDF to the left";
		_pdfFoundButton.title = @"Load PDF";
		[_pdfFoundButton setEnabled:NO];
	}
	else {
		_pdfFoundLabel.stringValue = @"A PDF with the same name has been found";
		_pdfFoundButton.title = _pdf ? @"Unload PDF" : @"Load PDF";
		[_pdfFoundButton setEnabled:YES];
	}
}



#pragma mark - Chart Handling
- (CHDocument *)pdfDocument
{
	return (CHDocument *)self.document;
}

- (CHChart *)chart
{
	return [self pdfDocument].chart;
}

- (void)setActiveArea:(CHChartArea *)activeArea
{
	if (activeArea != _activeArea) {
		[self willChangeValueForKey:@"activeArea"];
		_activeArea = activeArea;
		[self didChangeValueForKey:@"activeArea"];
	}
}

- (void)changeActiveArea:(NSButton *)sender
{
	if ([_currentAreaStack count] > sender.tag) {
		currentAreaIndex = sender.tag;
		_pdf.activeArea = ((CHChartAreaView *)[_currentAreaStack objectAtIndex:currentAreaIndex]);
	}
}



#pragma mark - Key-Value Observing
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	self.activeArea = _pdf.activeArea.area;
	
	// do we need to change our stack?
	NSView *boxContent = [_hierarchyBox contentView];
	if (!_pdf.activeArea || ![_currentAreaStack containsObject:_pdf.activeArea]) {
		[_currentAreaStack removeAllObjects];
		[[boxContent subviews] makeObjectsPerformSelector:@selector(removeFromSuperviewWithoutNeedingDisplay)];
		
		if (_pdf.activeArea) {
			if (!_currentAreaStack) {
				self.currentAreaStack = [NSMutableArray array];
			}
			CGSize boxSize = _hierarchyBox.bounds.size;
			CGFloat y = 10.f;
			NSUInteger tag = 0;
			currentAreaIndex = 0;
			
			// loop area and parent areas
			CHChartAreaView *areaView = _pdf.activeArea;
			while ([areaView isKindOfClass:[CHChartAreaView class]]) {
				NSRect buttonFrame = NSMakeRect(10.f, y, boxSize.width - 20.f, 22.f);
				NSButton *button = [[NSButton alloc] initWithFrame:buttonFrame];
				[button setButtonType:NSPushOnPushOffButton];
				[button setBezelStyle:NSTexturedRoundedBezelStyle];
				button.title = areaView.area.type;
				button.tag = tag;
				[button setState:(_pdf.activeArea == areaView) ? NSOnState : NSOffState];
				
				[button setTarget:self];
				[button setAction:@selector(changeActiveArea:)];
				
				[boxContent addSubview:button];
				[_currentAreaStack addObject:areaView];
				
				y += buttonFrame.size.height + 5.f;
				tag++;
				areaView = (CHChartAreaView *)[areaView superview];
			}
			
			// adjust size
			NSRect optFrame = _optionsBox.frame;
			NSRect hierFrame = _hierarchyBox.frame;
			hierFrame.size.height = y + 19.f;
			hierFrame.origin.y = optFrame.origin.y - 8.f - hierFrame.size.height;
			_hierarchyBox.frame = hierFrame;
		}
	}
	
	// no, just update button status
	else {
		for (NSButton *button in [boxContent subviews]) {
			[button setState:(button.tag == currentAreaIndex) ? NSOnState : NSOffState];
		}
	}
}



#pragma mark - Split View Delegate
- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{
	return (_rightPane != subview);
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex
{
	return ([splitView bounds].size.width - 400.f);
}


@end
