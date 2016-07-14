//
//  ModalTransitionAnimator.m
//  ChangeOver
//
//  Created by 杨运辉 on 15/11/26.
//  Copyright © 2015年 杨运辉. All rights reserved.
//

#import "ModalTransitionAnimator.h"

@interface ModalTransitionAnimator ()

@property (nonatomic, assign) BOOL isDismiss;
@property (nonatomic, strong) UIView *coverView;
@property (nonatomic, assign) BOOL isDismissUp;

@end

static const CGFloat BehindViewScale = 0.95;

@implementation ModalTransitionAnimator


- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissTypeChange:) name:@"dismiss" object:nil];
    }
    return self;
}

- (void)dismissTypeChange:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *boolNumber = userInfo[@"isDismissUp"];
    self.isDismissUp = boolNumber.boolValue;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"dismiss" object:nil];
}

#pragma -mark UIViewControllerAnimatedTransitioning
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.2;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    if (!self.isDismiss){
        
        fromViewController.view.superview.backgroundColor = [UIColor groupTableViewBackgroundColor];

        self.coverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, containerView.bounds.size.width, containerView.bounds.size.height )];
        
        self.coverView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        [containerView addSubview:self.coverView];

        [containerView addSubview:toViewController.view];
        toViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        
        toViewController.view.frame = CGRectMake(0, 0, CGRectGetWidth(toViewController.view.bounds), containerView.bounds.size.height);
    
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                         animations:^{
                             
                             fromViewController.view.transform = CGAffineTransformScale(fromViewController.view.transform, BehindViewScale, BehindViewScale);
                             
                             
                         } completion:^(BOOL finished) {
                             [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                             
                         }];
    }else{
        
        [[transitionContext containerView] bringSubviewToFront:fromViewController.view];
        
        
        CGRect endRect = CGRectMake(0, CGRectGetHeight(fromViewController.view.frame), CGRectGetWidth(fromViewController.view.frame), 0);
        if (self.isDismissUp) {
            endRect.origin.y = 0;
        } else {
            CGFloat scaleBack = (1 / BehindViewScale);
            toViewController.view.transform = CGAffineTransformScale(toViewController.view.transform, scaleBack, scaleBack);
            self.coverView.alpha = 0;
        }
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                         animations:^{
                             fromViewController.view.frame = endRect;
                             if (self.isDismissUp) {
                                 CGFloat scaleBack = (1 / BehindViewScale);
                                 toViewController.view.transform = CGAffineTransformScale(toViewController.view.transform, scaleBack, scaleBack);
                                 self.coverView.alpha = 0;
                             }

                         } completion:^(BOOL finished) {
                             [self.coverView removeFromSuperview];
                             [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                             
                         }];
    }
}

#pragma -mark UIViewControllerTransitioningDelegate
- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    self.isDismiss = NO;
    return self;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    self.isDismiss = YES;
    return self;
}

@end
