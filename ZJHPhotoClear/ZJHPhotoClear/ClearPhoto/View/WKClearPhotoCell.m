//
//  WKClearPhotoCell.m
//  WuKongClearPhotoDemo
//
//  Created by ZhangJingHao2345 on 2018/3/8.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import "WKClearPhotoCell.h"

@interface WKClearPhotoCell ()

@end

@implementation WKClearPhotoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return self;
}

- (void)bindWithMode:(WKClearPhotoItem *)item {
    self.textLabel.text = item.name;
    self.detailTextLabel.text = [NSString stringWithFormat:@"%@ 可省 %@", item.detail, item.saveStr];
}

@end
