//
//  TKDragView.h
//  Retail Incentive
//
//  Created by Mapedd on 11-05-14.
//  Copyright 2011 Tomasz Kuzma. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef BOOL TKVelocity;

#define kTKDragConstantTime YES

#define kTKDragConstantSpeed NO

/**
 Holds a rectangle position along with the parent container view.
 */

@interface TKCGRect : NSObject

@property (nonatomic, weak) UIView *parent;
@property (nonatomic, assign) CGRect rect;

+ (TKCGRect*)from:(CGRect)rect forView:(UIView*)view;

@end


/**
 Returns the distance between centers of the two frames
 */

CGFloat TKDistanceBetweenFrames(CGRect rect1, CGRect rect2);

/**
 Compute center of the given CGRect
 */

inline CGPoint TKCGRectCenter(CGRect rect);

@protocol TKDragViewDelegate;

@interface TKDragView : UIView <UIGestureRecognizerDelegate> {
    
    @private
    
    UIImageView *imageView_;
    
    CGRect startFrame_;
    
    CGPoint startLocation;
    
    BOOL isDragging_;
    
    BOOL isAnimating_;
    
    BOOL isOverEndFrame_;
    
    BOOL isOverBadFrame_;
    
    BOOL isOverStartFrame_;
    
    BOOL isAtEndFrame_;
    
    BOOL isAtStartFrame_;
    
    BOOL dragsAtCenter_;
    
    BOOL canDragFromEndPosition_;
    
    BOOL canSwapToStartPosition_;
    
    BOOL canDragMultipleDragViewsAtOnce_;
    
    BOOL canUseSameEndFrameManyTimes_;
    
    BOOL shouldStickToEndFrame_;
    
    BOOL isAddedToManager_;
    
    NSInteger currentGoodFrameIndex_;
    
    NSInteger currentBadFrameIndex_;
    
    __weak id<TKDragViewDelegate> delegate_;
    
    struct {
        unsigned int dragViewDidStartDragging:1;
        unsigned int dragViewDidEndDragging:1;
        
        unsigned int dragViewDidEnterStartFrame:1;
        unsigned int dragViewDidLeaveStartFrame:1;
        
        unsigned int dragViewDidEnterGoodFrame:1;
        unsigned int dragViewDidLeaveGoodFrame:1;
        
        unsigned int dragViewDidEnterBadFrame:1;
        unsigned int dragViewDidLeaveBadFrame:1;
        
        unsigned int dragViewWillSwapToEndFrame:1;
        unsigned int dragViewDidSwapToEndFrame:1;
        
        unsigned int dragViewWillSwapToStartFrame:1;
        unsigned int dragViewDidSwapToStartFrame:1;
        
        unsigned int dragViewCanAnimateToEndFrame:1;

    } delegateFlags_;
}

/**
 UIImageView instance already added to this view as a subview with autoresizing mask set to flexible width and height
 */

@property (nonatomic, strong) UIImageView *imageView;

/**
 Array to hold NSValues from CGRects with frames where drag view can be placed
 
 @seealso badFramesArray
 */

@property (nonatomic, strong) NSArray *goodFramesArray;

/**
 Array to hold NSValues from CGRects with frames where drag view cannot be placed
 
 @seealso goodFramesArray
 */

@property (nonatomic, strong) NSArray *badFramesArray;

/**
 initial frame, set on initialization
 */

@property (nonatomic) CGRect startFrame;

/**
 is YES when user is dragging the view
 */

@property (nonatomic) BOOL isDragging;

/**
 is YES when view is animating for example to one of the end frames or to start frame
 */

@property (nonatomic) BOOL isAnimating;

/**
 is YES when view is hovering over one of the good end frames
 */

@property (nonatomic) BOOL isOverEndFrame;

/**
 is YES when view is hovering over one of the bad frames
 */

@property (nonatomic) BOOL isOverBadFrame;

/**
 is YES when view placed on end frame (view have animated to end frame)
 */

@property (nonatomic) BOOL isAtEndFrame;

/**
 is YES when view sits on start frame 
 */

@property (nonatomic) BOOL isAtStartFrame;

/**
 When you set this property to NO, when drag view was once placed on end frame it can't swap back to start frame.
 Default: YES
 */

@property (nonatomic, setter = setCanSwapToStartPosition:) BOOL canSwapToStartPosition;

/**
 By setting this property to NO, drag view is added to TKDragManager, it's purpose it to prevent placing two views 
 on the same end frame
 Default: YES
 */

@property (nonatomic, setter = setCanUseSameEndFrameManyTimes:) BOOL canUseSameEndFrameManyTimes;

/**
 By setting this property to NO only one drag view can be dragged in the givien moment
 Default: YES
 */

@property (nonatomic, setter = setCanDragMultipleDragViewsAtOnce:) BOOL canDragMultipleDragViewsAtOnce;

/**
 By settings this property to YES, if drag view is placed on end frame and user will drag it but not leave the current end frame, 
 after releasing it will animate to current end frame, otherwise it will animate to start frame
 Default: NO
 */

@property (nonatomic, setter = setShouldStickToEndFrame:) BOOL shouldStickToEndFrame;

/**
 You can select duration of the swaping animations:
 kTKDragConstantTime - animation duration is constant and given be macros SWAP_TO_START_DURATION and SWAP_TO_END_DURATION 
 kTKDragConstantSpeed - animation is a function of a distance from a target frame from current position
 Default: kTKDragConstantTime
 */

@property (nonatomic) TKVelocity usedVelocity ;

/**
 When set to YES the view's center will translate to the touche's point. This can feel more natural for certain uses, when set to NO the touch position within the view is used for hit testing.
 Default: NO
 */

@property (nonatomic) BOOL dragsAtCenter;

/**
 When set to NO, after placing view on the good end frame, drag view cannot be moved at all
 Default: YES
 */

@property (nonatomic) BOOL canDragFromEndPosition;

/**
 @discusion all methods in TKDragViewDelegate protocol are optional
 
 Default: nil
 */

@property (nonatomic, weak) id<TKDragViewDelegate> delegate;

// Adds option to specify a different parent than the normal superview.
@property (nonatomic, weak) UIView *parentContainer;

/**
 @discusion Initializer for drag views with only one end frame
 */

- (id)initWithImage:(UIImage *)image 
         startFrame:(CGRect)startFrame 
           endFrame:(CGRect)endFrame;

/**
 @discusion Initializer for drag views with only one end frame and delegate
 */

- (id)initWithImage:(UIImage *)image
         startFrame:(CGRect)startFrame 
           endFrame:(CGRect)endFrame
        andDelegate:(id<TKDragViewDelegate>) delegate;

/**
 @discusion Default initilizer, it's called by all others init methods
 */

- (id)initWithImage:(UIImage *)image
         startFrame:(CGRect)startFrame 
         goodFrames:(NSArray *)goodFrames
          badFrames:(NSArray *)badFrames
        andDelegate:(id<TKDragViewDelegate>) delegate;


/**
 Animates drag view to current startFrame
 @seealso startFrame
 */

- (void)swapToStartPosition;

/**
 Animates drag view to good frame with given index from the goodFramesArray
 @seealso goodFrameArray
 */

- (void)swapToEndPositionAtIndex:(NSInteger)index;


@end


@protocol TKDragViewDelegate <NSObject>

@optional

- (void)dragViewDidStartDragging:(TKDragView *)dragView;

- (void)dragViewDidEndDragging:(TKDragView *)dragView;


- (void)dragViewDidEnterStartFrame:(TKDragView *)dragView;

- (void)dragViewDidLeaveStartFrame:(TKDragView *)dragView;


- (void)dragViewDidEnterGoodFrame:(TKDragView *)dragView atIndex:(NSInteger)index;

- (void)dragViewDidLeaveGoodFrame:(TKDragView *)dragView atIndex:(NSInteger)index;


- (void)dragViewDidEnterBadFrame:(TKDragView *)dragView atIndex:(NSInteger)index;

- (void)dragViewDidLeaveBadFrame:(TKDragView *)dragView atIndex:(NSInteger)index;


- (void)dragViewWillSwapToEndFrame:(TKDragView *)dragView atIndex:(NSInteger)index;

- (void)dragViewDidSwapToEndFrame:(TKDragView *)dragView atIndex:(NSInteger)index;


- (void)dragViewWillSwapToStartFrame:(TKDragView *)dragView;

- (void)dragViewDidSwapToStartFrame:(TKDragView *)dragView;

- (BOOL)dragView:(TKDragView *)dragView canAnimateToEndFrameWithIndex:(NSInteger)index;



@end

/*
 * 
 * Drag View manager to manage dragging and occupancy of the good end frames 
 * 
 */


@interface TKDragManager : NSObject

+ (TKDragManager *)manager;

- (void)addDragView:(TKDragView *)dragView;

- (void)removeDragView:(TKDragView *)dragView;

- (BOOL)dragView:(TKDragView*)dragView wantSwapToEndFrame:(CGRect)endFrame;

- (BOOL)dragViewCanStartDragging:(TKDragView*)dragView;

- (void)dragViewDidEndDragging:(TKDragView *)dragView;

- (void)dragView:(TKDragView *)dragView didLeaveEndFrame:(CGRect)endFrame;

@end

@interface TKOccupancyIndicator : NSObject

@property CGRect frame;
@property NSInteger count;
@property BOOL isFree;

+ (TKOccupancyIndicator *)indicatorWithFrame:(CGRect)frame;

- (id)initWithFrame:(CGRect)frame;

@end
