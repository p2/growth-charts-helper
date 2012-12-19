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
#import "CHDropView.h"


@interface CHWindowController ()

@property (nonatomic, readwrite, strong) CHChartPDFView *pdf;

- (void)loadPDFAt:(NSURL *)url;
- (void)didDropFiles:(NSNotification *)notification;

@end


@implementation CHWindowController


#pragma mark - View Handling
- (void)awakeFromNib
{
	// setup drop area
	_dropWell.acceptedTypes = [NSSet setWithObject:NSPasteboardTypePDF];
    [_dropWell registerForDraggedTypes:@[NSFilenamesPboardType]];
	
	// does our file have a PDF?
	[self loadPDFAt:[((CHDocument *)self.document) pdfWithSameName]];
	
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
	
	[_pdf removeFromSuperview];
	
	// create the PDF doc view
	self.pdf = [CHChartPDFView new];
	_pdf.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
	[_pdf setAllowsDragging:NO];
	//[_pdf setAutoScales:YES];
	[_pdf setDisplaysPageBreaks:NO];		// if we set this to YES, PDFKit adds a nice border around the page which offsets the actual PDF page and our areas are not correctly aligned
		
	PDFDocument *pdfDoc = [[PDFDocument alloc] initWithURL:url];
    [_pdf setDocument:pdfDoc];
	_pdf.chart = self.chart;
	
	// add as subview
	_pdf.frame = _leftPane.bounds;
	[_dropWell removeFromSuperview];
	[_leftPane addSubview:_pdf];
	[_pdf layoutSubviews];
}



#pragma mark - Properties
- (CHChart *)chart
{
	return ((CHDocument *)self.document).chart;
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
