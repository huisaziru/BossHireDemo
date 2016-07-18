//
//  DetailViewController.m
//  Boss直聘
//
//  Created by 杨运辉 on 16/7/10.
//  Copyright © 2016年 杨运辉. All rights reserved.
//

#import "DetailViewController.h"
#import "BossTableViewCell.h"
#import "UIView+Frame.h"

const NSInteger MenuHeight = 49;
const NSInteger InsetValue = 12;
NSString * const GroupAnimationKey = @"groupAnimation";
@interface DetailViewController ()<UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UIView *startView;
@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *contentMenuView;
@property (nonatomic, strong) UIView *contentMenuMaskView;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *tableHeaderBackGroundView;
@property (nonatomic, strong) UIView *tableFooterBackGroundView;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) UILabel *firstPromptLabel;
@property (nonatomic, strong) UILabel *lastPromptLabel;

@property (nonatomic, strong) NSArray *modelArr;
@property (nonatomic, assign) CGPoint lastOffset;

@property (nonatomic, assign) BOOL hasCollect;
@property (nonatomic, assign) BOOL hasChat;
@property (nonatomic, assign) BOOL firstDidAppear;
@property (nonatomic, strong) NSTimer *timer;

/**
 *  下面四个用于动画效果
 */
@property (weak, nonatomic) IBOutlet UILabel *heartLabel;
@property (weak, nonatomic) IBOutlet UILabel *collectLabel;
@property (weak, nonatomic) IBOutlet UIImageView *chatImage;
@property (weak, nonatomic) IBOutlet UILabel *chatLabel;




@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"详情";
    self.view.backgroundColor = [UIColor clearColor];
    self.startView = [[UIView alloc] initWithFrame:self.startRect];
    self.startView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.firstDidAppear = YES;
    [self.view addSubview:self.startView];
}

- (void)dealloc {
    [self.tableView removeObserver:self forKeyPath:@"contentSize"];
}

- (void)viewDidAppear:(BOOL)animated {
    if (!self.firstDidAppear) {
        return;
    } else {
        self.firstDidAppear = NO;
    }
    [UIView animateWithDuration:0.3 animations:^{
        CGRect frame = self.view.frame;
        frame.origin.y = 0;
        self.startView.frame =frame;
    } completion:^(BOOL finished) {
        CGRect frame = self.startView.frame;
        [self.startView removeFromSuperview];

        //scrollView设置3个view的宽度，当处于中间时，可以左右拖动；
        self.scrollView = [[UIScrollView alloc] initWithFrame:frame];
        self.scrollView.contentSize = CGSizeMake(frame.size.width * 3, frame.size.height);
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        self.scrollView.delegate = self;
        self.scrollView.pagingEnabled = YES;
        self.scrollView.tag = 1;
        self.scrollView.contentOffset = CGPointMake(0, 0);

        [self.view addSubview:self.scrollView];
        
        self.firstPromptLabel = [self createVerticalPromptLabel:@"已\n是\n第\n一\n页"];
        self.firstPromptLabel.center = CGPointMake(24, CGRectGetMidY(frame));
        self.lastPromptLabel = [self createVerticalPromptLabel:@"已\n是\n最\n后\n一\n页"];
        self.lastPromptLabel.center = CGPointMake(frame.size.width - 24, CGRectGetMidY(frame));
        
        [self.view addSubview:self.firstPromptLabel];
        [self.view addSubview:self.lastPromptLabel];
        [self getData];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self clearTimer];
}

- (void)clearTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (IBAction)close:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismiss" object:nil userInfo:@{@"isDismissUp" : @(NO)}];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [UIActivityIndicatorView new];
        _indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        _indicatorView.frame = CGRectMake(0, 0, 30, 30);
        _indicatorView.center = CGPointMake(self.view.center.x, self.scrollView.center.y) ;
        [self.scrollView addSubview:_indicatorView];
    }
    return _indicatorView;
}

- (UIView *)createContentView {
    UIView * contentView = [[UIView alloc] initWithFrame:CGRectMake(self.view.width, 0, self.view.width, self.view.height)];
    [self createTableView:CGRectMake(0, 0, contentView.width, contentView.height - MenuHeight)];
    [contentView addSubview:self.tableView];
    
    self.contentMenuView = [self createMenuView:CGRectMake(0, contentView.height - MenuHeight, contentView.width, MenuHeight)];
    
    [contentView addSubview:self.contentMenuView];
    return contentView;
}

- (void)createTableView:(CGRect)frame {
    self.tableView = [[UITableView alloc] initWithFrame:frame];
    self.tableView.tag = 0;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"BossTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"BossCell"];

    //让tableview有缩进
    self.tableView.contentInset = UIEdgeInsetsMake(InsetValue, 0, 0, 0);
    
    //tableHeaderBackGroundView作用：tableview是透明的，self.view也是透明，所以拉到顶部时，再往下拉，就会显示下面的controller,所以就是用来设置背景色，防止透明，再往下拉时，tableHeaderBackGroundView也会变大，保证完全盖住下面
    self.tableHeaderBackGroundView = [[UIView alloc] initWithFrame:CGRectMake(0, -InsetValue, frame.size.width, InsetValue)];
    self.tableHeaderBackGroundView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self.tableView addSubview:self.tableHeaderBackGroundView];

    //tableFooterBackGroundView作用：当tableview拉到底，再往上拉时，menuview 慢慢透出来的部分，如果底下没有view，会看到下面，所以添加此view，位置在tableview底部下面
    self.tableFooterBackGroundView = [[UIView alloc] initWithFrame:CGRectMake(0, self.tableView.contentSize.height, frame.size.width, MenuHeight)];
    self.tableFooterBackGroundView.backgroundColor = [UIColor whiteColor];
    [self.tableView addSubview:self.tableFooterBackGroundView];
    
    // 对tableView的contentSize 进行kvo,因为每次请求的数据不一样，conentSize不一样,更新tableFootBackGroundView的top
    [self.tableView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];

}

/** 创建边界提示lable*/
- (UILabel *)createVerticalPromptLabel:(NSString *)text {
    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.font = [UIFont systemFontOfSize:12];
    nameLabel.text = text;
    nameLabel.numberOfLines = [text length];
    [nameLabel sizeToFit];
    nameLabel.alpha = 0;
    return nameLabel;
}

/** 设置边界提示lable alpha*/
- (void)setPromtLabelAlpha:(UILabel *)label dx:(CGFloat)dx {
    CGFloat alpha = dx / 60;
    alpha = alpha >= 1 ? 1 : alpha;
    label.alpha = alpha;
}

/** 菜单view，和tableview同一级*/
- (UIView *)createMenuView:(CGRect)frame {
    UIView *containerView = [[UIView alloc] initWithFrame:frame];
    
    //遮罩view的作用：tableview上升时，遮罩view慢慢变小，让menuview透出来 tableFooterBackGroundView慢慢出来，刚好挡住了透明的部分，滚动条在tableview之上，所以可以透过menuview
    self.contentMenuMaskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    self.contentMenuMaskView.backgroundColor = [UIColor whiteColor];
    [containerView addSubview:self.contentMenuMaskView];
    
    UIView *menuView = [[[NSBundle mainBundle] loadNibNamed:@"MenuView" owner:self options:nil] firstObject];
    menuView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    menuView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
    [containerView addSubview:menuView];
    
    return containerView;
}

/** 手动设置scrollView的offset，并记录下这次的offset*/
- (void)setScrollViewContentOffset:(CGPoint)offset {
    self.scrollView.contentOffset = offset;
    self.lastOffset = offset;
}

/** 模拟请求数据，这里用定时器代替*/
- (void)getData {
    [self.indicatorView startAnimating];
    //请求数据时，禁止scrollView交互
    self.scrollView.userInteractionEnabled = NO;
    [self clearTimer];
    [self removeChatImageAnimation];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1ull *NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.indicatorView stopAnimating];
        //模拟数据
        self.modelArr = @[@(self.curIndex), @(self.curIndex), @(self.curIndex), @(self.curIndex), @(self.curIndex)];
        self.hasCollect = self.curIndex % 2 == 1;
        self.hasChat = self.curIndex % 3 == 2;
        self.scrollView.userInteractionEnabled = YES;
        self.scrollView.backgroundColor = [UIColor clearColor];
        //创建内容试图，加入scrollView,只创建一次
        if (!self.contentView) {
            self.contentView = [self createContentView];
            [self.scrollView addSubview:self.contentView];
        }
        //重置contentOffset
        self.tableView.contentOffset = CGPointMake(0, -self.tableView.contentInset.top);
        [self.tableView reloadData];
        
        if (self.curIndex == 0) { //当是第一条信息时，将contentView坐标更新到第一个区域，保证不能再往右拖动
            self.contentView.x = 0;
            [self setScrollViewContentOffset:CGPointMake(0, 0)];
        } else if (self.curIndex == self.totalNum - 1) { //当是最后一条信息时，将contentView坐标更新到第后一个区域，保证不能再往左拖动
            self.contentView.x = self.view.width * 2;
            [self setScrollViewContentOffset:CGPointMake(self.view.width * 2, 0)];
        } else { //contentView始终在中间区域，当offset不在中间，需要设置到中间，保证可以左右拖动
            
            if (self.contentView.x != self.view.width) {
                self.contentView.x = self.view.width;
            }
            [self setScrollViewContentOffset:CGPointMake(self.view.width, 0)];
        }

        if (!self.hasChat) {
            self.chatLabel.text = @"立即沟通";
            //出现后一段时间才播放动画,本来想用下面dispatch_after，但是到了时间就会触发动画，不管现在runloop处于什么状态；
            //用NSTimer这个定时器，只有runloop在default的状态时，到点才会触发指定函数，当滚动的时候，即使到了时间，也不触发，只会在default的时触发，这点和boss直聘一样；
            self.timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(playChatImageAnimation) userInfo:nil repeats:NO];
            //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //            [self.chatImage.layer addAnimation:[self groupAnimation] forKey:GroupAnimationKey];
            //        });
        } else {
            self.chatLabel.text = @"继续沟通";
        }

    });
}

/** 对tableView的contentSize 进行kvo,因为每次请求的数据不一样，conentSize不一样*/
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentSize"] && object == self.tableView) {
        self.tableFooterBackGroundView.y = self.tableView.contentSize.height;
    }
    
}

#pragma mark -TableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.modelArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * identifer = @"BossCell";
    BossTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.content = [NSString stringWithFormat:@"%@", self.modelArr[indexPath.row]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return 120;
    }else if (indexPath.row == 1){
        return 110;
    } else if (indexPath.row == 2) {
        return 160 + 10 * [self.modelArr[indexPath.row] integerValue];
    } else if (indexPath.row == 3) {
        return 160;
    } else{
        return 140;
    }
}

#pragma mark - ScrollView delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView.tag == 1) {
        //拖动时，scrollView设置背景颜色，防止看到下面
        self.scrollView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView.tag == 0) {
        //tableView底部拉高80时，关闭页面
        if (scrollView.contentOffset.y + self.tableView.height > self.tableView.contentSize.height + 80) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"dismiss" object:nil userInfo:@{@"isDismissUp" : @(YES)}];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }

}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView.tag == 1) {
        if (scrollView.contentOffset.x != self.lastOffset.x) {
            //更新indicatorView到scrollView当前区域中间
            self.indicatorView.center = CGPointMake(scrollView.contentOffset.x + self.view.center.x, self.indicatorView.center.y);
            //切换到上一条数据或下一条数据
            if (scrollView.contentOffset.x > self.lastOffset.x) {
                self.curIndex++;
                [self getData];
            } else {
                self.curIndex--;
                [self getData];
            }
        } else {
            //还是当前页面时，将背景颜色去掉
            scrollView.backgroundColor = [UIColor clearColor];
        }
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentSize.height > 0 && scrollView.tag == 0) {
        if (scrollView.contentOffset.y + scrollView.height > scrollView.contentSize.height) {
            
            CGFloat dy = scrollView.contentOffset.y + scrollView.height - scrollView.contentSize.height;
            self.contentMenuView.y = self.view.height - self.contentMenuView.height - dy;
            if (dy <= self.contentMenuView.height) {
                self.contentMenuMaskView.y = dy;
                self.contentMenuMaskView.height = self.contentMenuView.height - dy;
            } else {
                //防止menuview上升一部分后突然往上拉，上升高度大于menuview的高度，height还没变成0，所以需要设成0；
                if (self.contentMenuMaskView.height != 0) {
                    self.contentMenuMaskView.height = 0;
                }
            }

        } else {
            //这个是boss直聘的bug
            //防止从底下往上拉时，突然一下下来，因为没有过渡，所以contentMenuView的坐标还在上面，所以需要重置下
            CGFloat originContentMenuY = self.view.height - self.contentMenuView.height;
            if (self.contentMenuView.y != originContentMenuY) {
                self.contentMenuView.y = originContentMenuY;
                self.contentMenuMaskView.y = 0;
                self.contentMenuMaskView.height = self.contentMenuView.height;
            }
        }
        
        //顶部view随着往下拉变大
        if (scrollView.contentOffset.y < 0) {
            self.tableHeaderBackGroundView.y = scrollView.contentOffset.y;
            self.tableHeaderBackGroundView.height = - scrollView.contentOffset.y;
        }
        
    } else if (scrollView.tag == 1) {
        //判断到边界时显示promptlable，alpha过渡
        CGFloat firstMsgAlphaX = - self.firstPromptLabel.x * 2;
        CGFloat lastMsgAlphaX = self.view.width * 3 - self.lastPromptLabel.x;
        if (scrollView.contentOffset.x < firstMsgAlphaX) {
            [self setPromtLabelAlpha:self.firstPromptLabel dx:firstMsgAlphaX - scrollView.contentOffset.x];
        } else if (scrollView.contentOffset.x > lastMsgAlphaX) {
            [self setPromtLabelAlpha:self.lastPromptLabel dx:scrollView.contentOffset.x - lastMsgAlphaX];
        } else {
            if (self.firstPromptLabel.alpha != 0) {
                self.firstPromptLabel.alpha = 0;
            }
            if (self.lastPromptLabel.alpha != 0) {
                self.lastPromptLabel.alpha = 0;
            }
        }
    }

}

- (void)playChatImageAnimation {
    [self.chatImage.layer addAnimation:[self groupAnimation] forKey:GroupAnimationKey];
}

- (void)removeChatImageAnimation {
    [self.chatImage.layer removeAnimationForKey:GroupAnimationKey];
}

- (void)setHasCollect:(BOOL)hasCollect {
    _hasCollect = hasCollect;
    self.heartLabel.text = hasCollect ? @"♥︎" : @"♡";
    self.heartLabel.font = hasCollect ? [UIFont fontWithName:self.heartLabel.font.fontName size:18] :[UIFont fontWithName:self.heartLabel.font.fontName size:15];
    self.collectLabel.text = hasCollect ? @"已收藏" : @"+收藏" ;
}

- (IBAction)chat:(id)sender {
    if (!self.hasChat) {
        [self removeChatImageAnimation];
    }
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)collect:(id)sender {
    self.hasCollect = !self.hasCollect;
    if (self.hasCollect) {
        CABasicAnimation *animation = [CABasicAnimation animation];
        animation.keyPath = @"transform.scale";
        animation.duration = 0.1;
        animation.fromValue = @(1.0);
        animation.toValue = @(1.3);
        [self.heartLabel.layer addAnimation:animation forKey:@"scale"];
    }
}

- (CAAnimationGroup *)groupAnimation {
    CAKeyframeAnimation *keyAnima=[CAKeyframeAnimation animation];
    keyAnima.keyPath=@"transform.rotation";
    keyAnima.duration=1.25 ;
    keyAnima.values=@[@(0),@(M_PI /18),@(0),@(-M_PI /18),@(0)];
    
    CAKeyframeAnimation *keyAnima1=[CAKeyframeAnimation animation];
    keyAnima1.keyPath=@"transform.scale";
    keyAnima1.duration=1.25;
    keyAnima1.values=@[@(1.0),@(1.1),@(1.2),@(1.3),@(1.4)];
    
    CAAnimationGroup *groupAnimation    = [CAAnimationGroup animation];
    
    groupAnimation.duration             = 1.25;
    groupAnimation.repeatCount         = INFINITY;
    groupAnimation.animations             = [NSArray arrayWithObjects:keyAnima,
                                             keyAnima1,
                                             nil];
    groupAnimation.autoreverses = YES;
    return groupAnimation;
}


@end
