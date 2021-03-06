/*
 CHChartPDFView.h
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

#import <Quartz/Quartz.h>

@class CHChart;
@class CHChartArea;
@class CHChartAreaView;


/**
 *	Top level object to display a PDF chart.
 */
@interface CHChartPDFView : PDFView

@property (nonatomic, strong) CHChart *chart;
@property (nonatomic, strong) CHChartAreaView *activeArea;

- (void)layoutSubviews;
- (void)didBecomeFirstResponder:(CHChartAreaView *)areaView;

- (CHChartAreaView *)didAddArea:(CHChartArea *)area;
- (void)didRemoveArea:(CHChartArea *)area;


@end
