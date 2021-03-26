
//
//  GPLoadingMoreView.m
//  GPLoadingMoreViewDemo
//
//  Created by liuxj on 2017/11/13.
//  Copyright © 2017年 liuxj. All rights reserved.
//

#import "GPLoadingMoreView.h"
#import <objc/runtime.h>

static void     *      kWMLoadMoreView          = &kWMLoadMoreView;
static NSString *const kFrontStrokeAnimation    = @"kFrontStrokeAnimation";
static NSString *const kBackStrokeAnimation     = @"kBackStrokeAnimation";
static CGFloat   const DESIGN_LINE_LENGTH       = 40.0;
static CGFloat   const DISPLAY_LINE_LENGTH      = 15.0;
static CGFloat   const WMLoadMoreViewHeight     = 40.0;

@interface GPLoadingMoreView ()
{
    CAShapeLayer *_frontIndicatorLayer;
    CAShapeLayer *_backIndicatorLayer;
    CAAnimationGroup *_frontAnimationGroup;
    CAAnimationGroup *_backAnimationGroup;
    UILabel *_noMoreDataFooter;
    BOOL _isAnimating;
}

@property (nonatomic, copy) void (^loadMoreHandler)(void);
@property (nonatomic, assign) BOOL isObserving;

@end

@implementation GPLoadingMoreView

#pragma mark - Override Method

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initializeView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _frontIndicatorLayer.position = CGPointMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0);
    _backIndicatorLayer.position = _frontIndicatorLayer.position;
}

- (void)willMoveToSuperview:(UIView *)superview
{
    [super willMoveToSuperview:superview];
    if ([self.superview isKindOfClass:[UIScrollView class]] && superview == nil) {
        if (self.isObserving) {
            [self.superview removeObserver:self forKeyPath:@"contentSize"];
            [self.superview removeObserver:self forKeyPath:@"contentOffset"];
            self.isObserving = NO;
        }
    }
}

#pragma mark - Configuration

- (void)initializeView {
    
    _hidesWhenStopped = YES;
    _isObserving = NO;
    _isAnimating = NO;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    CGFloat ratio = DISPLAY_LINE_LENGTH / DESIGN_LINE_LENGTH;
    CGFloat lineWidth = DISPLAY_LINE_LENGTH / 9.0;
    
    _frontIndicatorLayer = [CAShapeLayer layer];
    _frontIndicatorLayer.fillColor = [UIColor clearColor].CGColor;
    _frontIndicatorLayer.strokeColor = [[UIColor alloc] initWithRed:255.0 / 255.0 green:45.0 / 255.0 blue:75.0/255.0 alpha:1.0].CGColor;
    _frontIndicatorLayer.lineCap = kCALineCapRound;
    _frontIndicatorLayer.lineJoin = kCALineJoinMiter;
    _frontIndicatorLayer.lineWidth = lineWidth;
    
    _backIndicatorLayer = [CAShapeLayer layer];
    _backIndicatorLayer.fillColor = [UIColor clearColor].CGColor;
    _backIndicatorLayer.strokeColor = [[UIColor alloc] initWithRed:255.0 / 255.0 green:45.0 / 255.0 blue:75.0/255.0 alpha:1.0].CGColor;
    _backIndicatorLayer.lineCap = kCALineCapRound;
    _backIndicatorLayer.lineJoin = kCALineCapRound;
    _backIndicatorLayer.lineWidth = lineWidth;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    [path moveToPoint:CGPointMake(20.07 * ratio, 0.0)];
    
    [path addCurveToPoint:CGPointMake(DISPLAY_LINE_LENGTH, 19.93 * ratio)
            controlPoint1:CGPointMake(34.48 * ratio, 0.0)
            controlPoint2:CGPointMake(DISPLAY_LINE_LENGTH, 5.6 * ratio)];
    
    [path addCurveToPoint:CGPointMake(20.07 * ratio, 40.07 * ratio)
            controlPoint1:CGPointMake(DISPLAY_LINE_LENGTH, 34.55 * ratio)
            controlPoint2:CGPointMake(34.4 * ratio, DISPLAY_LINE_LENGTH)];
    
    [path addCurveToPoint:CGPointMake(0.0, 20.07 * ratio)
            controlPoint1:CGPointMake(5.52 * ratio, DISPLAY_LINE_LENGTH)
            controlPoint2:CGPointMake(0.0, 34.48 * ratio)];
    
    [path addCurveToPoint:CGPointMake(19.93 * ratio, 0.0)
            controlPoint1:CGPointMake(0.0, 5.5 * ratio)
            controlPoint2:CGPointMake(5.45 * ratio, 0.0)];
    
    [path closePath];
    
    _frontIndicatorLayer.path = path.CGPath;
    _frontIndicatorLayer.bounds = CGRectMake(0, 0, DISPLAY_LINE_LENGTH, DISPLAY_LINE_LENGTH);
    
    _backIndicatorLayer.path = _frontIndicatorLayer.path;
    _backIndicatorLayer.bounds = _frontIndicatorLayer.bounds;
    
    [self.layer addSublayer:_frontIndicatorLayer];
    [self.layer addSublayer:_backIndicatorLayer];
    
    self.state = WMLoadMoreViewStateStopped;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.superview && [keyPath isEqualToString:@"contentSize"]) {
        if ([self.superview isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)self.superview;
            CGFloat scrollViewY = scrollView.contentSize.height;
            self.frame = CGRectMake(0, scrollViewY, scrollView.frame.size.width, WMLoadMoreViewHeight);
            [self layoutIfNeeded];
        }
    }
    else if (object == self.superview && [keyPath isEqualToString:@"contentOffset"]) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        [self scrollView:scrollView didScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)scrollView:(UIScrollView *)scrollView didScroll:(CGPoint)contentOffset {
    if(self.state != WMLoadMoreViewStateLoading) {
        
        CGFloat scrollViewContentHeight = MAX(scrollView.contentSize.height, scrollView.bounds.size.height);
        CGFloat scrollOffsetThreshold = scrollViewContentHeight - scrollView.bounds.size.height;
        
#ifdef __IPHONE_11_0
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
        scrollOffsetThreshold -= scrollView.adjustedContentInset.top;
#pragma clang diagnostic pop
#else
        scrollOffsetThreshold -= scrollView.contentInset.top;
#endif
        
        if(contentOffset.y > scrollOffsetThreshold && self.state == WMLoadMoreViewStateStopped && scrollView.isDragging)
        {
            self.state = WMLoadMoreViewStateLoading;
        }
    }
}

#pragma mark - Public Method

- (void)startAnimating {
    self.state = WMLoadMoreViewStateLoading;
}

- (void)stopAnimating {
    self.state = WMLoadMoreViewStateStopped;
}

- (BOOL)isAnimating {
    return _isAnimating;
}

- (void)showsNoMoreDataViewWithText:(NSString *)title {
    [_noMoreDataFooter removeFromSuperview];
    _noMoreDataFooter = nil;
    
    _noMoreDataFooter = [[UILabel alloc] init];
    _noMoreDataFooter.textAlignment = NSTextAlignmentCenter;
    _noMoreDataFooter.font = [UIFont systemFontOfSize:12];
    _noMoreDataFooter.textColor = [[UIColor alloc] initWithRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0/255.0 alpha:1.0];
    _noMoreDataFooter.text = title;
    [_noMoreDataFooter sizeToFit];
    _noMoreDataFooter.center = CGPointMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0);
    [self addSubview:_noMoreDataFooter];
}

#pragma mark - Private Method

- (void)setState:(WMLoadMoreViewState)newState {
    
    if(_state == newState)
    {
        return;
    }
    
    _state = newState;
    switch (_state) {
        case WMLoadMoreViewStateStopped:
        {
            [self stopIndicatorAnimating];
        }
            break;
            
        case WMLoadMoreViewStateLoading:
        {
            [self startIndicatorAnimating];
            if(self.loadMoreHandler){
                self.loadMoreHandler();
            }
        }
            break;
    }
    
}

- (void)startIndicatorAnimating {
    
    if (_hidesWhenStopped) {
        [self.subviews setValue:@(NO) forKey:@"hidden"];
        [self.layer.sublayers setValue:@(NO) forKey:@"hidden"];
    }
    
    if (_isAnimating) {
        return;
    }
    _isAnimating = YES;

    [self createAnimationIfNeeded];

    [_frontIndicatorLayer addAnimation:_frontAnimationGroup forKey:kFrontStrokeAnimation];
    [_backIndicatorLayer addAnimation:_backAnimationGroup forKey:kBackStrokeAnimation];
}

- (void)stopIndicatorAnimating {
    
    if (_hidesWhenStopped) {
        [self.subviews setValue:@(YES) forKey:@"hidden"];
        [self.layer.sublayers setValue:@(YES) forKey:@"hidden"];
    }
    
    if (!_isAnimating) {
        return;
    }
    _isAnimating = NO;
    [_frontIndicatorLayer removeAllAnimations];
    [_backIndicatorLayer removeAllAnimations];
}

- (void)createAnimationIfNeeded {
    if (_frontAnimationGroup) {
        return;
    }
    
    CGFloat animationDuration = 1.0;
    NSArray *startTimes = @[@(0),@(1/30.0),@(0.5),@(2/3.0),@(1.0)];
    NSArray *startValues = @[@(0),@(0),@(0.5),@(1.0),@(1.0)];
    NSArray *endTimes = @[@(0),@(0.4),@(1.0)];
    NSArray *endValues = @[@(0),@(1.0),@(1.0)];
    
    CAKeyframeAnimation *strokeStartAnimation = [CAKeyframeAnimation animationWithKeyPath:@"strokeStart"];
    strokeStartAnimation.removedOnCompletion = NO;
    strokeStartAnimation.repeatCount = INFINITY;
    strokeStartAnimation.duration = animationDuration;
    strokeStartAnimation.values = startValues;
    strokeStartAnimation.keyTimes = startTimes;
    strokeStartAnimation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear],
                                             [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear],
                                             [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
                                             [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    
    CAKeyframeAnimation *strokeEndAnimation = [CAKeyframeAnimation animationWithKeyPath:@"strokeEnd"];
    strokeEndAnimation.removedOnCompletion = NO;
    strokeEndAnimation.repeatCount = INFINITY;
    strokeEndAnimation.duration = animationDuration;
    strokeEndAnimation.values = endValues;
    strokeEndAnimation.keyTimes = endTimes;
    
    _frontAnimationGroup = [CAAnimationGroup animation];
    _frontAnimationGroup.animations = @[strokeStartAnimation,strokeEndAnimation];
    _frontAnimationGroup.removedOnCompletion = NO;
    _frontAnimationGroup.repeatCount = INFINITY;
    _frontAnimationGroup.duration = animationDuration;
    
    NSArray *backStartTimes = @[@(0),@(2/3.0),@(5/6.0),@(1.0)];
    NSArray *backStartValues = @[@(0),@(0),@(0.5),@(1.0)];
    NSArray *backEndTimes = @[@(0),@(0.4),@(0.5),@(1.0)];
    NSArray *backEndValues = @[@(0),@(0.0),@(0.25),@(1.0)];
    
    CAKeyframeAnimation *backStrokeStartAnimation = [CAKeyframeAnimation animationWithKeyPath:@"strokeStart"];
    backStrokeStartAnimation.removedOnCompletion = NO;
    backStrokeStartAnimation.repeatCount = INFINITY;
    backStrokeStartAnimation.duration = animationDuration;
    backStrokeStartAnimation.values = backStartValues;
    backStrokeStartAnimation.keyTimes = backStartTimes;
    
    CAKeyframeAnimation *backStrokeEndAnimation = [CAKeyframeAnimation animationWithKeyPath:@"strokeEnd"];
    backStrokeEndAnimation.removedOnCompletion = NO;
    backStrokeEndAnimation.repeatCount = INFINITY;
    backStrokeEndAnimation.duration = animationDuration;
    backStrokeEndAnimation.values = backEndValues;
    backStrokeEndAnimation.keyTimes = backEndTimes;
    backStrokeEndAnimation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear],
                                               [CAMediaTimingFunction functionWithControlPoints:0.4 :0.19 :0.6 :0.81],
                                               [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]
                                               ];
    
    _backAnimationGroup = [CAAnimationGroup animation];
    _backAnimationGroup.animations = @[backStrokeStartAnimation,backStrokeEndAnimation];
    _backAnimationGroup.removedOnCompletion = NO;
    _backAnimationGroup.repeatCount = INFINITY;
    _backAnimationGroup.duration = animationDuration;
}

@end

@implementation UIScrollView (WMLoadMoreView)

#pragma mark - Public Method
- (void)addLoadMoreViewWithActionHandler:(void (^)(void))actionHandler {
    if(!self.loadMoreView) {
        GPLoadingMoreView *view = [[GPLoadingMoreView alloc] init];
        [self insertSubview:view atIndex:self.subviews.count];
        view.loadMoreHandler = actionHandler;
        self.loadMoreView = view;
        self.observingLoadMoreView = YES;
        //Set ScrollView's contentInset will trigger contentOffset change
        UIEdgeInsets inset = self.contentInset;
        inset.bottom += WMLoadMoreViewHeight;
        self.contentInset = inset;
    }
}

- (void)triggerLoadMoreView {
    [self.loadMoreView startAnimating];
}

- (void)endLoadingMore {
    [self.loadMoreView stopAnimating];
}

- (void)endLoadingWithNoMoreDataText:(NSString *)text {
    [self.loadMoreView stopAnimating];
    self.observingLoadMoreView = NO;
    if (!text || [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        //Set ScrollView's contentInset will trigger contentOffset change
        UIEdgeInsets inset = self.contentInset;
        inset.bottom -= WMLoadMoreViewHeight;
        self.contentInset = inset;
    }else {
        [self.loadMoreView showsNoMoreDataViewWithText:text];
    }
}

- (BOOL)isLoadingMore {
    return self.loadMoreView.state == WMLoadMoreViewStateLoading;
}

#pragma mark - Private Method

- (void)setObservingLoadMoreView:(BOOL)observingLoadMoreView {
    if(!observingLoadMoreView) {
        if (self.loadMoreView.isObserving) {
            [self removeObserver:self.loadMoreView forKeyPath:@"contentOffset"];
            [self removeObserver:self.loadMoreView forKeyPath:@"contentSize"];
            self.loadMoreView.isObserving = NO;
        }
    }
    else {
        if (!self.loadMoreView.isObserving) {
            [self addObserver:self.loadMoreView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.loadMoreView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            self.loadMoreView.isObserving = YES;
        }
    }
}

#pragma mark - Getter && Setter
- (void)setLoadMoreView:(GPLoadingMoreView *)loadmoreView {
    [self willChangeValueForKey:@"loadmoreView"];
    objc_setAssociatedObject(self, kWMLoadMoreView,
                             loadmoreView,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"loadmoreView"];
}

- (GPLoadingMoreView *)loadMoreView {
    return objc_getAssociatedObject(self, kWMLoadMoreView);
}

@end
