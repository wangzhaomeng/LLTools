//
//  LLBaseComponent.m
//  LLFeature
//
//  Created by WangZhaomeng on 2017/11/25.
//  Copyright © 2017年 WangZhaomeng. All rights reserved.
//

#import "LLBaseComponent.h"

@interface LLBaseComponent ()

@property (strong, nonatomic) UIPanGestureRecognizer *pan;

@end

@implementation LLBaseComponent

#pragma mark - 初始化
- (instancetype)init
{
    if (self = [super init]) {
        // 准备工作
        [self prepare];
        
        // 默认是普通状态
        _refreshState = LLRefreshStateNormal;
    }
    return self;
}

- (void)prepare
{
    // 基本属性
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.backgroundColor  = [UIColor clearColor];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    
    // 如果不是UIScrollView，不做任何事情
    if ([newSuperview isKindOfClass:[UIScrollView class]]) {
        
        if ([newSuperview isKindOfClass:[UITableView class]]) {
            //关闭UITableView的高度预估
            ((UITableView *)newSuperview).estimatedRowHeight = 0;
            ((UITableView *)newSuperview).estimatedSectionHeaderHeight = 0;
            ((UITableView *)newSuperview).estimatedSectionFooterHeight = 0;
        }
        
        // 记录UIScrollView
        _scrollView = (UIScrollView *)newSuperview;
        // 设置永远支持垂直弹簧效果
        _scrollView.alwaysBounceVertical = YES;
        
        // 添加监听
        [self addObservers];
    }
}

- (void)removeFromSuperview {
    [self removeObservers];
    [super removeFromSuperview];
}

#pragma mark - KVO监听
- (void)addObservers
{
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
    [self.scrollView addObserver:self forKeyPath:LLRefreshKeyPathContentOffset options:options context:nil];
    [self.scrollView addObserver:self forKeyPath:LLRefreshKeyPathContentSize options:options context:nil];
    self.pan = self.scrollView.panGestureRecognizer;
    [self.pan addObserver:self forKeyPath:LLRefreshKeyPathPanState options:options context:nil];
}

- (void)removeObservers
{
    [self.superview removeObserver:self forKeyPath:LLRefreshKeyPathContentOffset];
    [self.superview removeObserver:self forKeyPath:LLRefreshKeyPathContentSize];
    [self.pan removeObserver:self forKeyPath:LLRefreshKeyPathPanState];
    self.pan = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.isRefreshing) return;
    if ([keyPath isEqualToString:LLRefreshKeyPathContentSize]) {
        [self scrollViewContentSizeDidChange:change];
    }
    
    if (self.hidden)       return;
    if ([keyPath isEqualToString:LLRefreshKeyPathContentOffset]) {
        [self scrollViewContentOffsetDidChange:change];
    }
    else if ([keyPath isEqualToString:LLRefreshKeyPathPanState]) {
        [self scrollViewPanStateDidChange:change];
    }
}

/** 普通状态 */
- (void)LL_RefreshNormal{
    [self updateRefreshState:LLRefreshStateNormal];
}

/** 松开就刷新的状态 */
- (void)LL_WillRefresh {
    [self updateRefreshState:LLRefreshStateWillRefresh];
}

/** 没有更多的数据 */
- (void)LL_NoMoreData {
    [self updateRefreshState:LLRefreshStateNoMoreData];
}

/** 正在刷新中的状态 */
- (void)LL_BeginRefresh{
    self.refreshing = YES;
    [self updateRefreshState:LLRefreshStateRefreshing];
}

/** 结束刷新 */
- (void)LL_EndRefresh:(BOOL)more{
    self.refreshing = NO;
    if (more) {
        [self LL_RefreshNormal];
    }
    else {
        [self LL_NoMoreData];
    }
}

- (void)LL_EndRefresh{};
- (void)createViews{};
- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change{}
- (void)scrollViewContentSizeDidChange:(NSDictionary *)change{}
- (void)scrollViewPanStateDidChange:(NSDictionary *)change{}
- (void)updateRefreshState:(LLRefreshState)refreshState{}

@end
