//
//  TKViewController.h
//  TKDragViewDemo
//
//  Created by Tomasz Kuźma on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TKDragView.h"

@interface TKViewController : UIViewController <TKDragViewDelegate>

@property (nonatomic, strong) NSMutableArray *dragViews;

@property (nonatomic, strong) NSMutableArray *goodFrames;

@property (nonatomic, strong) NSMutableArray *badFrames;

@property BOOL canDragMultipleViewsAtOnce;

@property BOOL canUseTheSameFrameManyTimes;

@end
