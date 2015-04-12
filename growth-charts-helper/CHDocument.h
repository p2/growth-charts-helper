//
//  CHDocument.h
//  growth-charts-helper
//
//  Created by Pascal Pfiffner on 12/18/12.
//  Copyright (c) 2012 CHIP. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CHChart;


/**
 *  Holds our JSON description of one chart.
 */
@interface CHDocument : NSDocument

@property (nonatomic, strong) CHChart *chart;

- (NSURL *)pdfWithSameName;
- (void)didLoadPDFAtURL:(NSURL *)pdfURL;

@end
