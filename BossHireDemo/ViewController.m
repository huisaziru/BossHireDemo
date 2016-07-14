//
//  ViewController.m
//  Boss直聘
//
//  Created by 杨运辉 on 16/7/10.
//  Copyright © 2016年 杨运辉. All rights reserved.
//

#import "ViewController.h"
#import "DetailViewController.h"
#import "ModalTransitionAnimator.h"
#import "BossTableViewCell.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) ModalTransitionAnimator *animator;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.tableView.rowHeight = 160;
    self.tableView.tableHeaderView = [self headView];
    self.navigationItem.title = @"首页";
    [self.tableView registerNib:[UINib nibWithNibName:@"BossTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"BossCell"];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsSelection = YES;
    // Do any additional setup after loading the view, typically from a nib.
}

- (UIView *)headView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 80)];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, view.frame.size.height - 12)];
    imageView.backgroundColor = [UIColor greenColor];
    [view addSubview:imageView];
    view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    return view;
}

- (ModalTransitionAnimator *)animator {
    if (!_animator) {
        _animator = [[ModalTransitionAnimator alloc] init];
    }
    return _animator;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 15;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * identifer = @"BossCell";
    BossTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer forIndexPath:indexPath];
    //cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.content = [NSString stringWithFormat:@"%ld", indexPath.row];
    return cell;
}

- (void)presentDetailViewController:(CGRect)rect atIndex:(NSInteger)index {
    UINavigationController *nav = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"DetailNavigationController"];
    nav.transitioningDelegate = self.animator;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    DetailViewController *dst =  nav.viewControllers[0];
    dst.startRect = rect;
    dst.totalNum = 15;
    dst.curIndex = index;
    
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CGRect rectInTableView = [tableView rectForRowAtIndexPath:indexPath];
    [self presentDetailViewController:[tableView convertRect:rectInTableView toView:self.view] atIndex:indexPath.row];
}

@end
