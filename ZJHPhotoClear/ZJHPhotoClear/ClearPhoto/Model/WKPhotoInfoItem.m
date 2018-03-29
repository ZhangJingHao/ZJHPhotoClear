//
//  WKPhotoInfoItem.m
//  WuKongClearPhotoDemo
//
//  Created by ZhangJingHao2345 on 2018/3/8.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import "WKPhotoInfoItem.h"

@implementation WKPhotoInfoItem

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        [self dealWithDict:dict];
    }
    return self;
}

- (void)dealWithDict:(NSDictionary *)dict {
    self.asset = dict[@"asset"];
    self.image = dict[@"image"];
    self.imageData = dict[@"imageData"];
    self.imageSize = [dict[@"imageSize"] unsignedIntegerValue];
    
}

@end
