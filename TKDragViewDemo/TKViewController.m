//
//  TKViewController.m
//  TKDragViewDemo
//
//  Created by Tomasz Kuźma on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TKViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation TKViewController

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)loadView{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
}

- (void)viewDidLoad{
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor underPageBackgroundColor];
    
    NSBundle *bundle = [NSBundle mainBundle];
    
    NSString *path = [bundle pathForResource:@"tile_green.png" ofType:nil];
    
    UIImage *image = [UIImage imageWithContentsOfFile:path];




    
    int device = 7;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        device = 3;
    }
    
    self.goodFrames = [NSMutableArray arrayWithCapacity:device];
    self.badFrames = [NSMutableArray arrayWithCapacity:device];
    
    NSMutableArray *goodFrames = [NSMutableArray arrayWithCapacity:device];
    NSMutableArray *badFrames = [NSMutableArray arrayWithCapacity:device];
    self.dragViews = [NSMutableArray arrayWithCapacity:device];
    
    for (int i = 0; i< device; i++) {

        
        CGRect endFrame =   CGRectMake(6 + i * 103, 150, 100, 100);
        
        CGRect badFrame =   CGRectMake(6 + i * 103, 290, 100, 100);
        
        [goodFrames addObject:[TKCGRect from:endFrame forView:self.view]];
        [badFrames addObject:[TKCGRect from:badFrame forView:self.view]];
        
        UIView *endView = [[UIView alloc] initWithFrame:endFrame];
        endView.layer.borderColor = [UIColor greenColor].CGColor;
        endView.layer.borderWidth = 1.0f;
        
        [self.view addSubview:endView];
        
        [self.goodFrames addObject:endView];
        
        UIView *badView = [[UIView alloc] initWithFrame:badFrame];
        badView.layer.borderWidth = 1.0f;
        badView.layer.borderColor = [UIColor redColor].CGColor;
        [self.view addSubview:badView];
        
        [self.badFrames addObject:badView];
    }
    
    self.canUseTheSameFrameManyTimes = NO;
    self.canDragMultipleViewsAtOnce = NO;
    
    
    for (int i = 0; i< device; i++) {
        
        CGRect startFrame = CGRectMake(6 + i * 103, 10, 100, 100);

        
        TKDragView *dragView = [[TKDragView alloc] initWithImage:image
                                                       startFrame:startFrame
                                                       goodFrames:goodFrames
                                                        badFrames:badFrames
                                                      andDelegate:self];
        
        
        //dragView.dragsAtCenter = YES;
        dragView.canDragMultipleDragViewsAtOnce = NO;
        dragView.canUseSameEndFrameManyTimes = NO;
        
        [self.dragViews addObject:dragView];
        
        [self.view addSubview:dragView];
        
        UITapGestureRecognizer *g = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(taped:)];
        [g setNumberOfTapsRequired:2];
        [dragView addGestureRecognizer:g];
    }
    
    CGFloat width = self.view.frame.size.width /2;
    
    UIButton *allowMultidrag = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    allowMultidrag.frame = CGRectMake(6, 400, width*0.9 , 44);
    [allowMultidrag setTitle:@"Multidrag : OFF" forState:UIControlStateNormal];
    [allowMultidrag addTarget:self action:@selector(allowMultidrag:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:allowMultidrag];
    
    UIButton *allowTakeSameSpot = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    allowTakeSameSpot.frame = CGRectMake(width, 400, width*0.9, 44);
    [allowTakeSameSpot addTarget:self action:@selector(allowTakeSameSpot:) forControlEvents:UIControlEventTouchUpInside];
    [allowTakeSameSpot setTitle:@"Same frame: OFF" forState:UIControlStateNormal];
    [self.view addSubview:allowTakeSameSpot];
    

}

- (void)viewDidUnload{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

#pragma mark - Private

- (void)allowMultidrag:(UIButton * )button{
    
    self.canDragMultipleViewsAtOnce = !self.canDragMultipleViewsAtOnce;
    
    for (TKDragView *drag in self.dragViews) {
        drag.canDragMultipleDragViewsAtOnce = !drag.canDragMultipleDragViewsAtOnce;
    }
    
    if (self.canDragMultipleViewsAtOnce) {
        [button setTitle:@"Multidrag: ON" forState:UIControlStateNormal];
    }
    else{
        [button setTitle:@"Multidrag: OFF" forState:UIControlStateNormal];
    }
    
    
}

- (void)allowTakeSameSpot:(UIButton * )button{
    
    self.canUseTheSameFrameManyTimes = !self.canUseTheSameFrameManyTimes;
    
    for (TKDragView *drag in self.dragViews) {
        drag.canUseSameEndFrameManyTimes = !drag.canUseSameEndFrameManyTimes;
    } 
   
    if (self.canUseTheSameFrameManyTimes) {
        [button setTitle:@"Same frame: ON" forState:UIControlStateNormal];
    }
    else{
        [button setTitle:@"Same frame: OFF" forState:UIControlStateNormal];
    }
}

- (void)taped:(UITapGestureRecognizer *)tap{

}


#pragma mark - TKDragViewDelegate

- (void)dragViewDidStartDragging:(TKDragView *)dragView{
    
    [UIView animateWithDuration:0.2 animations:^{
        dragView.transform = CGAffineTransformMakeScale(1.2, 1.2);
    }];
}

- (void)dragViewDidEndDragging:(TKDragView *)dragView{
    
    [UIView animateWithDuration:0.2 animations:^{
        dragView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }];
}


- (void)dragViewDidEnterStartFrame:(TKDragView *)dragView{

    [UIView animateWithDuration:0.2 animations:^{
        dragView.alpha = 0.5;
    }];
}

- (void)dragViewDidLeaveStartFrame:(TKDragView *)dragView{
    
    [UIView animateWithDuration:0.2 animations:^{
        dragView.alpha = 1.0;
    }];
}


- (void)dragViewDidEnterGoodFrame:(TKDragView *)dragView atIndex:(NSInteger)index{

    UIView *view = [self.goodFrames objectAtIndex:index];
    
    if (view) view.layer.borderWidth = 4.0f;
    
    
}

- (void)dragViewDidLeaveGoodFrame:(TKDragView *)dragView atIndex:(NSInteger)index{    
    UIView *view = [self.goodFrames objectAtIndex:index];
    
    if (view) view.layer.borderWidth = 1.0f;
}


- (void)dragViewDidEnterBadFrame:(TKDragView *)dragView atIndex:(NSInteger)index{

    UIView *view = [self.badFrames objectAtIndex:index];
    
    if (view) view.layer.borderWidth = 4.0f;
}

- (void)dragViewDidLeaveBadFrame:(TKDragView *)dragView atIndex:(NSInteger)index{
    
    UIView *view = [self.badFrames objectAtIndex:index];
    
    if (view) view.layer.borderWidth = 1.0f;
}


- (void)dragViewWillSwapToEndFrame:(TKDragView *)dragView atIndex:(NSInteger)index{
    

    
}

- (void)dragViewDidSwapToEndFrame:(TKDragView *)dragView atIndex:(NSInteger)index{

    
    [UIView animateWithDuration:0.2
                          delay:0.1
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         dragView.transform = CGAffineTransformMakeRotation(M_PI);
                     } 
                     completion:^(BOOL finished) {
                         
                     }];
}


- (void)dragViewWillSwapToStartFrame:(TKDragView *)dragView{
    [UIView animateWithDuration:0.2 animations:^{
        dragView.alpha = 1.0f; 
    }];
}

- (void)dragViewDidSwapToStartFrame:(TKDragView *)dragView{

}

@synthesize dragViews = dragViews_;

@synthesize goodFrames =goodFrames_;

@synthesize badFrames = badFrames_;

@synthesize canDragMultipleViewsAtOnce =canDragMultipleViewsAtOnce_;

@synthesize canUseTheSameFrameManyTimes =canUseTheSameFrameManyTimes_;

@end
