
//
//  GPLoadingMoreView.h
//  GPLoadingMoreViewDemo
//
//  Created by liuxj on 2017/11/13.
//  Copyright © 2017年 liuxj. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    WMLoadMoreViewStateLoading = 0,
    WMLoadMoreViewStateStopped ,
} WMLoadMoreViewState;

@interface GPLoadingMoreView : UIView

@property (nonatomic, readonly) WMLoadMoreViewState state;
@property(nonatomic) BOOL hidesWhenStopped;//default is YES

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@end

@interface UIScrollView (WMLoadMoreView)

@property (nonatomic, strong, readonly) GPLoadingMoreView *loadMoreView;

@property (nonatomic, assign, readonly)  BOOL isLoadingMore;

- (void)addLoadMoreViewWithActionHandler:(void (^)(void))actionHandler;

- (void)triggerLoadMoreView;

- (void)endLoadingMore;

- (void)endLoadingWithNoMoreDataText:(NSString *)text;

@end
