//
//  BossTableViewCell.m
//  Boss直聘
//
//  Created by 杨运辉 on 16/7/12.
//  Copyright © 2016年 杨运辉. All rights reserved.
//

#import "BossTableViewCell.h"

@interface BossTableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *label;

@end
@implementation BossTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

//- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//    [super setSelected:selected animated:animated];
//
//    // Configure the view for the selected state
//}

- (void)setContent:(NSString *)content {
    _content = content;
    self.label.text = content;
}

@end
