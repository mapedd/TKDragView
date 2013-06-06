//
//  TKDragView.m
//  Retail Incentive
//
//  Created by Mapedd on 11-05-14.
//  Copyright 2011 Tomasz Kuzma. All rights reserved.
//

#import "TKDragView.h"

#include <mach/mach_time.h>
#include <stdint.h>

#define SWAP_TO_START_DURATION .24f

#define SWAP_TO_END_DURATION   .24f

#define VELOCITY_PARAMETER 1000.0f

@implementation TKCGRect

+ (TKCGRect*)from:(CGRect)rect forView:(UIView*)view
{
	TKCGRect *r = [TKCGRect new];
	r.rect = rect;
	r.parent = view;
	return r;
}

@end

CGPoint TKCGRectCenter(CGRect rect){
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

CGFloat TKDistanceBetweenFrames(CGRect rect1, CGRect rect2){
    CGPoint p1 = TKCGRectCenter(rect1);
    CGPoint p2 = TKCGRectCenter(rect2);
    return sqrtf(powf(p1.x - p2.x, 2) + powf(p1.y - p2.y, 2));
}


@interface TKDragView ()

- (BOOL)didEnterGoodFrameWithPoint:(CGPoint)point;

- (BOOL)didEnterBadFrameWithPoint:(CGPoint)point;

- (BOOL)didEnterStartFrameWithPoint:(CGPoint)point;


- (NSInteger)badFrameIndexWithPoint:(CGPoint)point;

- (NSInteger)goodFrameIndexWithPoint:(CGPoint)point;


- (void)panBegan:(UIPanGestureRecognizer *)gestureRecognizer;

- (void)panMoved:(UIPanGestureRecognizer *)gestureRecognizer;

- (void)panEnded:(UIPanGestureRecognizer *)gestureRecognizer;


- (NSTimeInterval)swapToStartAnimationDuration;

- (NSTimeInterval)swapToEndAnimationDurationWithFrame:(CGRect)endFrame;

@property (nonatomic, weak) UIView *startView;


@end


@implementation TKDragView

@synthesize imageView = imageView_;

@synthesize goodFramesArray = goodFramesArray_;

@synthesize badFramesArray = badFramesArray_;

@synthesize startFrame = startFrame_;

@synthesize isDragging = _sDragging_;

@synthesize isAnimating = isAnimating_;

@synthesize isOverBadFrame = isOverBadFrame_;

@synthesize isOverEndFrame = isOverEndFrame_;

@synthesize isAtEndFrame = isAtEndFrame_;

@synthesize isAtStartFrame = isAtStartFrame_;

@synthesize canDragFromEndPosition = canDragFromEndPosition_;

@synthesize canSwapToStartPosition = canSwapToStartPosition_;

@synthesize canDragMultipleDragViewsAtOnce = canDragMultipleDragViewsAtOnce_;

@synthesize canUseSameEndFrameManyTimes = canUseSameEndFrameManyTimes_;

@synthesize shouldStickToEndFrame = shouldStickToEndFrame_;

@synthesize usedVelocity = _usedVelocity;

@synthesize delegate = delegate_;

#pragma mark - Initializers

- (id)initWithImage:(UIImage *)image 
         startFrame:(CGRect)startFrame 
           endFrame:(CGRect)endFrame{
    
    self = [self  initWithImage:image
                     startFrame:startFrame 
                     goodFrames:[NSArray arrayWithObject:[NSValue valueWithCGRect:endFrame]]
                      badFrames:nil
                    andDelegate:nil];
    
    return self;
}

- (id)initWithImage:(UIImage *)image
         startFrame:(CGRect)startFrame 
           endFrame:(CGRect)endFrame
        andDelegate:(id<TKDragViewDelegate>) delegate{
    

    self = [self initWithImage:image 
                    startFrame:startFrame
                    goodFrames:[NSArray arrayWithObject:[NSValue valueWithCGRect:endFrame]] 
                     badFrames:nil
                   andDelegate:delegate];
    
    return self;
}

- (id)initWithImage:(UIImage *)image
         startFrame:(CGRect)startFrame 
         goodFrames:(NSArray *)goodFrames
          badFrames:(NSArray *)badFrames
        andDelegate:(id<TKDragViewDelegate>) delegate{
    
    self = [super initWithFrame:startFrame];
    
    if(!self) return nil;
    
    self.goodFramesArray = goodFrames;
    
    self.badFramesArray = badFrames;
    
    self.startFrame = startFrame;
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self.imageView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [self.imageView setImage:image];
    [self addSubview:self.imageView];
    
    
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDetected:)];
    [panGesture setMaximumNumberOfTouches:2];
    panGesture.delaysTouchesEnded = NO;
    [panGesture setDelegate:self];
    [self addGestureRecognizer:panGesture];
    
    
    self.userInteractionEnabled = YES;
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    self.exclusiveTouch = NO;
    self.multipleTouchEnabled = NO;
    
    self.usedVelocity = kTKDragConstantTime;
    self.isDragging =       NO;
    self.isAnimating =      NO;
    self.isOverBadFrame =   NO;
    self.isOverEndFrame =   NO;
    self.isAtEndFrame =     NO;
    self.shouldStickToEndFrame = NO;
    self.isAtStartFrame =   YES;
    self.canDragFromEndPosition = YES;
    
    canUseSameEndFrameManyTimes_ = YES;
    canDragMultipleDragViewsAtOnce_ = YES;
    
    canSwapToStartPosition_ = YES;
    isOverStartFrame_ = YES;
    
    isAddedToManager_ = NO;
    
    currentBadFrameIndex_ = currentGoodFrameIndex_ = -1;
    
    startLocation = CGPointZero;
    
    self.delegate = delegate;
    
    return self;
}

#pragma mark - Memory

- (void)dealloc{
    delegate_ = nil;
}

#pragma mark - Setters

- (void)setDelegate:(id<TKDragViewDelegate>)delegate{
    if (delegate != delegate_) {
        delegate_ = delegate;
    
        delegateFlags_.dragViewDidStartDragging     = [delegate_ respondsToSelector:@selector(dragViewDidStartDragging:)];
        delegateFlags_.dragViewDidEndDragging       = [delegate_ respondsToSelector:@selector(dragViewDidEndDragging:)];
        
        delegateFlags_.dragViewDidEnterStartFrame   = [delegate_ respondsToSelector:@selector(dragViewDidEnterStartFrame:)];
        delegateFlags_.dragViewDidLeaveStartFrame   = [delegate_ respondsToSelector:@selector(dragViewDidLeaveStartFrame:)];
        
        delegateFlags_.dragViewDidEnterGoodFrame    = [delegate_ respondsToSelector:@selector(dragViewDidEnterGoodFrame:atIndex:)];            
        delegateFlags_.dragViewDidLeaveGoodFrame    = [delegate_ respondsToSelector:@selector(dragViewDidLeaveGoodFrame:atIndex:)];
        
        delegateFlags_.dragViewDidEnterBadFrame     = [delegate_ respondsToSelector:@selector(dragViewDidEnterBadFrame:atIndex:)];
        delegateFlags_.dragViewDidLeaveBadFrame     = [delegate_ respondsToSelector:@selector(dragViewDidLeaveBadFrame:atIndex:)];
        
        delegateFlags_.dragViewWillSwapToEndFrame = [delegate_ respondsToSelector:@selector(dragViewWillSwapToEndFrame:atIndex:)];
        delegateFlags_.dragViewDidSwapToEndFrame    = [delegate_ respondsToSelector:@selector(dragViewDidSwapToEndFrame:atIndex:)];
        
        delegateFlags_.dragViewWillSwapToStartFrame = [delegate_ respondsToSelector:@selector(dragViewWillSwapToStartFrame:)];
        delegateFlags_.dragViewDidSwapToStartFrame  = [delegate_ respondsToSelector:@selector(dragViewDidSwapToStartFrame:)];
        
        delegateFlags_.dragViewCanAnimateToEndFrame = [delegate_ respondsToSelector:@selector(dragView:canAnimateToEndFrameWithIndex:)];
    }
}

- (UIView*)parentContainer
{
	return _parentContainer ? _parentContainer : [self superview];
}

- (void)setCanUseSameEndFrameManyTimes:(BOOL)canUseSameEndFrameManyTimes{
    canUseSameEndFrameManyTimes_ = canUseSameEndFrameManyTimes;
    
    if (!canUseSameEndFrameManyTimes_ && !isAddedToManager_) {
        [[TKDragManager manager] addDragView:self];
        isAddedToManager_ = YES;
    }
    else if(canUseSameEndFrameManyTimes_){
        [[TKDragManager manager] removeDragView:self];
        isAddedToManager_ = NO;
    }
}

- (void)setCanDragMultipleDragViewsAtOnce:(BOOL)canDragMultipleDragViewsAtOnce{
    canDragMultipleDragViewsAtOnce_ = canDragMultipleDragViewsAtOnce;
    
    if (canDragMultipleDragViewsAtOnce) {
        [[TKDragManager manager] dragViewDidEndDragging:self];
    }
}

#pragma mark - Gesture handling

- (void)panDetected:(UIPanGestureRecognizer*)gestureRecognizer{
    switch ([gestureRecognizer state]) {
        case UIGestureRecognizerStateBegan:
            [self panBegan:gestureRecognizer];
            break;
        case UIGestureRecognizerStateChanged:
            [self panMoved:gestureRecognizer];
            break;
        case UIGestureRecognizerStateEnded:
            [self panEnded:gestureRecognizer];
            break;
        default:
            break;
    }
}

- (void)panBegan:(UIPanGestureRecognizer*)gestureRecognizer{
    
    if (!canDragMultipleDragViewsAtOnce_) {
        if (![[TKDragManager manager] dragViewCanStartDragging:self]) {
            return;
        }
    }
    
    
    
    if (isAtEndFrame_ && !canDragFromEndPosition_) {
        return;
    }
    
	if (!isDragging_ && !isAnimating_) {
        
        isDragging_ = YES;

        const CGPoint pt = [gestureRecognizer locationInView:self];

        startLocation = pt;

        self.startView = [self superview];
        self.startFrame = self.frame;

        // Displace view to match point as center.
        if (self.dragsAtCenter)
            [self setCenter:CGPointMake(self.frame.origin.x + startLocation.x,
                self.frame.origin.y + startLocation.y)];

        if (self.startView != [self parentContainer]) {
            self.frame = [[self superview] convertRect:self.frame toView:[self parentContainer]];
            [self.parentContainer addSubview:self];
        }

        [[self parentContainer] bringSubviewToFront:self];

        if (delegateFlags_.dragViewDidStartDragging) {
            [self.delegate dragViewDidStartDragging:self];
        }

    }
}

- (void)panMoved:(UIPanGestureRecognizer*)gestureRecognizer{
    
    if(!isDragging_)
        return;
    
        
    CGPoint pt = [gestureRecognizer locationInView:[self parentContainer]];
    CGPoint translation = [gestureRecognizer translationInView:[self parentContainer]];
    [self setCenter:CGPointMake([self center].x + translation.x,
								[self center].y + translation.y)];
    [gestureRecognizer setTranslation:CGPointZero inView:[self parentContainer]];
    
    // Is over start frame
    
    BOOL isOverStartFrame = [self didEnterStartFrameWithPoint:pt];
    
    if (!isOverStartFrame_ && isOverStartFrame) {
        
        if (delegateFlags_.dragViewDidEnterStartFrame)
            [self.delegate dragViewDidEnterStartFrame:self];
        isOverStartFrame_ = YES;
    }
    else if(isOverStartFrame_ && !isOverStartFrame){
        
        if (delegateFlags_.dragViewDidLeaveStartFrame)
            [self.delegate dragViewDidLeaveStartFrame:self];
        isOverStartFrame_ = NO;
    }
    
    
    
    // Is over good or bad frame?
    
    NSInteger goodFrameIndex = [self goodFrameIndexWithPoint:pt];
    NSInteger badFrameIndex = [self badFrameIndexWithPoint:pt];
    
    
    // Entered new good frame
    if (goodFrameIndex >= 0 && !isOverEndFrame_) {
        
        if (delegateFlags_.dragViewDidEnterGoodFrame) {
            [self.delegate dragViewDidEnterGoodFrame:self atIndex:goodFrameIndex];
        }
        
        currentGoodFrameIndex_ = goodFrameIndex;
        isOverEndFrame_ = YES;
    }
    
    
    // Did leave good frame
    if (isOverEndFrame_ && goodFrameIndex < 0) {
        
        if (delegateFlags_.dragViewDidLeaveGoodFrame) {
            [self.delegate dragViewDidLeaveGoodFrame:self atIndex:currentGoodFrameIndex_];
            
        }
        
        if(!canUseSameEndFrameManyTimes_){
            TKCGRect *r = self.goodFramesArray[currentGoodFrameIndex_];
            CGRect goodFrame = r.rect;
            [[TKDragManager manager] dragView:self didLeaveEndFrame:goodFrame];
        }
        
        currentGoodFrameIndex_ = -1;
        isOverEndFrame_ = NO;
        isAtEndFrame_ = NO;
        
    }
    
    // Did switch from one good from to another
    
    if (isOverEndFrame_ && goodFrameIndex != currentGoodFrameIndex_) {
        
        if (delegateFlags_.dragViewDidLeaveGoodFrame) {
            [self.delegate dragViewDidLeaveGoodFrame:self atIndex:currentGoodFrameIndex_];
            
        }
        
        if (!canUseSameEndFrameManyTimes_ && isAtEndFrame_) {
            TKCGRect *r = self.goodFramesArray[currentGoodFrameIndex_];
            CGRect rect = r.rect;
            [[TKDragManager manager] dragView:self didLeaveEndFrame:rect];
        }
        
        if (delegateFlags_.dragViewDidEnterGoodFrame) {
            [self.delegate dragViewDidEnterGoodFrame:self atIndex:goodFrameIndex];
        }
        
        currentGoodFrameIndex_ = goodFrameIndex;
        isAtEndFrame_ = NO;
    }
    
    
    // Is over bad frame
    
    if(badFrameIndex >= 0 && !isOverBadFrame_) {
        
        if (delegateFlags_.dragViewDidEnterBadFrame)
            [self.delegate dragViewDidEnterBadFrame:self atIndex:badFrameIndex];
        
        isOverBadFrame_ = YES;
        currentBadFrameIndex_ = badFrameIndex;
    }
    
    if (isOverBadFrame_ && badFrameIndex < 0) {
        if (delegateFlags_.dragViewDidLeaveBadFrame) 
            [self.delegate dragViewDidLeaveBadFrame:self atIndex:currentBadFrameIndex_];
        
        isOverBadFrame_ = NO;
        currentBadFrameIndex_ = -1;
    }
    
    
    // Did switch bad frames
    if (isOverBadFrame_ && badFrameIndex != currentBadFrameIndex_){
        if (delegateFlags_.dragViewDidLeaveBadFrame) 
            [self.delegate dragViewDidLeaveBadFrame:self atIndex:currentBadFrameIndex_];
        
        if (delegateFlags_.dragViewDidEnterBadFrame)
            [self.delegate dragViewDidEnterBadFrame:self atIndex:badFrameIndex];
        
        currentBadFrameIndex_ = badFrameIndex;

    }
    
}

- (void)panEnded:(UIPanGestureRecognizer*)gestureRecognizer{
    
    if (!isDragging_) 
        return;
    
    isDragging_ = NO;
    
    if(!canDragMultipleDragViewsAtOnce_)
        [[TKDragManager manager] dragViewDidEndDragging:self];
    
    if (delegateFlags_.dragViewDidEndDragging) {
        [self.delegate dragViewDidEndDragging:self];
    }

    if (delegateFlags_.dragViewCanAnimateToEndFrame){
        if (![self.delegate dragView:self canAnimateToEndFrameWithIndex:currentGoodFrameIndex_]){
            [self swapToStartPosition];
            return;
        }
    }
    
    if (isOverBadFrame_) {
        if (delegateFlags_.dragViewDidLeaveBadFrame) 
            [self.delegate dragViewDidLeaveBadFrame:self atIndex:currentBadFrameIndex_];
    }
    
    
    if (isAtEndFrame_ && !shouldStickToEndFrame_) {
        if(!canUseSameEndFrameManyTimes_) {
            TKCGRect *r = self.goodFramesArray[currentGoodFrameIndex_];
            CGRect goodFrame = r.rect;
            [[TKDragManager manager] dragView:self didLeaveEndFrame:goodFrame];
        }
        
        if(delegateFlags_.dragViewDidLeaveGoodFrame)
            [self.delegate dragViewDidLeaveGoodFrame:self atIndex:currentGoodFrameIndex_];
        
        [self swapToStartPosition];
    }
    else{
        if (isOverStartFrame_ && canSwapToStartPosition_) {
            [self swapToStartPosition];
        }
        else{
            
            
            if (currentGoodFrameIndex_ >= 0) {
                [self swapToEndPositionAtIndex:currentGoodFrameIndex_];
            }
            else{
                if (isOverEndFrame_ && !canUseSameEndFrameManyTimes_) {
                    TKCGRect *r = self.goodFramesArray[currentGoodFrameIndex_];
                    CGRect goodFrame = r.rect;
                    [[TKDragManager manager] dragView:self didLeaveEndFrame:goodFrame];
                }
                
                [self swapToStartPosition];
            }
        }
    }

    startLocation = CGPointZero;
    
   
}

#pragma mark - Private

- (BOOL)didEnterGoodFrameWithPoint:(CGPoint)point {
    
    if ([self goodFrameIndexWithPoint:point] >= 0) {
        return YES;
    }
    else{
        return NO;
    }
}

- (BOOL)didEnterBadFrameWithPoint:(CGPoint)point {
    
    if ([self badFrameIndexWithPoint:point] >= 0) {
        return YES;
    }
    else{
        return NO;
    }

}
    
- (BOOL)didEnterStartFrameWithPoint:(CGPoint)point {
    
    CGPoint touchInSuperview = [self convertPoint:point toView:[self parentContainer]];
    
    return CGRectContainsPoint(startFrame_,touchInSuperview);
}

- (NSInteger)badFrameIndexWithPoint:(CGPoint)point{

    for (int i=0;i<[self.badFramesArray count];i++) {
        TKCGRect *r = self.badFramesArray[i];
        const CGRect goodFrame = [[self parentContainer] convertRect:r.rect fromView:r.parent];
        if (CGRectContainsPoint(goodFrame, point))
            return i;
    }
    
    return -1;
}

- (NSInteger)goodFrameIndexWithPoint:(CGPoint)point{

    for (int i=0;i<[self.goodFramesArray count];i++) {
        TKCGRect *r = self.goodFramesArray[i];
        const CGRect goodFrame = [[self parentContainer] convertRect:r.rect fromView:r.parent];
        if (CGRectContainsPoint(goodFrame, point))
            return i;
    }

    return -1;
}

- (NSTimeInterval)swapToStartAnimationDuration{
    if (self.usedVelocity == kTKDragConstantTime) {
        return SWAP_TO_START_DURATION;
    }
    else{
        // kTKDragConstantVelocity
        return TKDistanceBetweenFrames(self.frame, self.startFrame)/VELOCITY_PARAMETER;
    }
        
}

- (NSTimeInterval)swapToEndAnimationDurationWithFrame:(CGRect)endFrame{
    if (self.usedVelocity == kTKDragConstantTime) {
        return SWAP_TO_END_DURATION;
    }
    else{
        // kTKDragConstantVelocity
        return TKDistanceBetweenFrames(self.frame, endFrame)/VELOCITY_PARAMETER;
    }
}

#pragma mark - Public

- (void)swapToStartPosition{
    
    self.frame = [[self parentContainer] convertRect:self.frame toView:self.startView];
    [self.startView addSubview:self];
    isAnimating_ = YES;
    
    if (delegateFlags_.dragViewWillSwapToStartFrame)
        [self.delegate dragViewWillSwapToStartFrame:self];
    
    
    
    [UIView animateWithDuration:[self swapToStartAnimationDuration]
                          delay:0. 
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                        self.frame = self.startFrame; 
                     } 
                     completion:^(BOOL finished) {
                         if (finished) {
                             if (delegateFlags_.dragViewDidSwapToStartFrame)
                                 [self.delegate dragViewDidSwapToStartFrame:self];
                             
                             isAnimating_ = NO;
                             isAtStartFrame_ = YES;
                             isAtEndFrame_ = NO;
                         }
                     }];
    
    
}

- (void)swapToEndPositionAtIndex:(NSInteger)index{

    // Define a common action performed when the swap can not happen.
    void (^abort_swap)(void) = ^{
        self.frame = [[self parentContainer]
            convertRect:self.frame toView:self.startView];
        [self.startView addSubview:self];
    };
    
    if (![self.goodFramesArray count]) {
        abort_swap();
        return;
    }
    
    TKCGRect *r = self.goodFramesArray[index];
    CGRect endFrame = r.rect;
    
    if (!isAtEndFrame_) {
        if (!canUseSameEndFrameManyTimes_) {
            
            if(![[TKDragManager manager] dragView:self wantSwapToEndFrame:endFrame]){
                if(delegateFlags_.dragViewDidLeaveGoodFrame){
                    [self.delegate dragViewDidLeaveGoodFrame:self atIndex:index];
                }
                abort_swap();
                return;
            }
        }
    }
    
    isAnimating_ = YES;
    
    self.frame = [[self parentContainer] convertRect:self.frame toView:r.parent];
    [r.parent addSubview:self];

    if (delegateFlags_.dragViewWillSwapToEndFrame) 
        [self.delegate dragViewWillSwapToEndFrame:self atIndex:index];
    
    [UIView animateWithDuration:[self swapToEndAnimationDurationWithFrame:endFrame]
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.frame = endFrame;
                     } 
                     completion:^(BOOL finished) {
                         if (finished) {
                             if (delegateFlags_.dragViewDidSwapToEndFrame) 
                                 [self.delegate dragViewDidSwapToEndFrame:self atIndex:index];
                             
                             isAnimating_ = NO;
                             isAtEndFrame_ = YES;
                             isAtStartFrame_ = NO;
                             
                         }
                     }];
}


@end

#pragma mark - TKDragManager

@interface TKDragManager ()

@property (nonatomic, strong) NSMutableArray *managerArray;

@property (nonatomic, unsafe_unretained) TKDragView *currentDragView;

@end


@implementation TKDragManager

@synthesize currentDragView = currentDragView_;

@synthesize managerArray = managerArray_;

static TKDragManager *manager; // it's a singleton, but how to relase it under ARC?

+ (TKDragManager *)manager{
    if (!manager) {
        manager = [[TKDragManager alloc] init];
    }
    
    return manager;
}

- (id)init{
    self = [super init];
    
    if(!self) return nil;
    
    self.managerArray = [NSMutableArray arrayWithCapacity:0];
    self.currentDragView = nil;
    
    
    return self;
}

- (void)addDragView:(TKDragView *)dragView{
    
    NSMutableArray *framesToAdd = [NSMutableArray arrayWithCapacity:0];
    
    
    
    if ([self.managerArray count]) {
        
            for (TKCGRect *dragViewValue in dragView.goodFramesArray) {
                CGRect dragViewRect = dragViewValue.rect;
                BOOL isInTheArray = NO;

                for (TKOccupancyIndicator *ind in self.managerArray) {
                    
                    CGRect managerRect = ind.frame;
                    
                    if (CGRectEqualToRect(managerRect, dragViewRect)) {
                        ind.count++;
                        isInTheArray = YES;
                        break;
                    }
                }            
                
                if (!isInTheArray) {
                    [framesToAdd addObject:dragViewValue];
                }
                
            }  

    }
    else{
        [framesToAdd addObjectsFromArray:dragView.goodFramesArray];
    }
    
    
    for (int i = 0;i < [framesToAdd count]; i++) {
        
        TKCGRect *r = framesToAdd[i];
        CGRect frame = r.rect;
        
        TKOccupancyIndicator *ind = [TKOccupancyIndicator indicatorWithFrame:frame];
        
        [self.managerArray addObject:ind];
    }
    
    
}

- (void)removeDragView:(TKDragView *)dragView{
    NSMutableArray *arrayToRemove = [NSMutableArray arrayWithCapacity:0];
    
    for (TKOccupancyIndicator *ind in self.managerArray) {
        
        CGRect rect = ind.frame;
        
        for (TKCGRect *value in dragView.goodFramesArray) {
            
            CGRect endFrame = value.rect;
            
            if (CGRectEqualToRect(rect, endFrame)) {
                ind.count--;
                
                if (ind.count == 0) {
                    [arrayToRemove addObject:ind];
                }
            }
            
        }
        
    }
    
    [self.managerArray removeObjectsInArray:arrayToRemove];
    
}

- (BOOL)dragView:(TKDragView*)dragView wantSwapToEndFrame:(CGRect)endFrame{
    
    
    for (TKOccupancyIndicator *ind in self.managerArray) {
        
        CGRect frame = ind.frame;
        
        BOOL isTaken = !ind.isFree;
                    
        if (CGRectEqualToRect(endFrame, frame)) {
            if (isTaken) {
                [dragView swapToStartPosition];
                return NO;
            }
            else{
                ind.isFree = NO;
                return YES;
            }
        }
    }
    
    return YES;
}

- (void)dragView:(TKDragView *)dragView didLeaveEndFrame:(CGRect)endFrame{
    for (TKOccupancyIndicator *ind in self.managerArray) {
        CGRect frame = ind.frame;
        
        if (CGRectEqualToRect(frame, endFrame) && dragView.isAtEndFrame) {
            ind.isFree = YES;
        }
    }
}

- (BOOL)dragViewCanStartDragging:(TKDragView*)dragView{
    if (!self.currentDragView) {
        self.currentDragView = dragView;
        return YES;
    }
    else{
        return NO;
    }
}

- (void)dragViewDidEndDragging:(TKDragView *)dragView{
    if (self.currentDragView == dragView)
        self.currentDragView = nil;
}

@end

#pragma mark - TKOccupancyIndicator

@implementation TKOccupancyIndicator 

@synthesize frame = frame_;
@synthesize count = count_;
@synthesize isFree = isFree_;

- (id)initWithFrame:(CGRect)frame{
    self = [super init];
    if(!self) return nil;
    
    self.frame = frame;
    self.isFree = YES;
    self.count = 1;
    
    return self;
    
}

+ (TKOccupancyIndicator *)indicatorWithFrame:(CGRect)frame{
    return [[TKOccupancyIndicator alloc] initWithFrame:frame];
}

- (NSString *)description{
    return [NSString stringWithFormat:@"TKOccupancyIndicator: frame: %@, count: %d, isFree: %@", 
            NSStringFromCGRect(self.frame), self.count, self.isFree ? @"YES" : @"NO"];
}

@end













