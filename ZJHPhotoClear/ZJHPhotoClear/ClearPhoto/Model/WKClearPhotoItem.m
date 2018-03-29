//
//  WKClearPhotoItem.m
//  WuKongClearPhotoDemo
//
//  Created by ZhangJingHao2345 on 2018/3/8.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import "WKClearPhotoItem.h"

@implementation WKClearPhotoItem

- (instancetype)initWithType:(WKClearPhotoType)type
                    dataDict:(NSDictionary *)dict {
    self = [self init];
    if (self) {
        [self dealWithType:type dict:dict];
    }
    return self;
}

- (void)dealWithType:(WKClearPhotoType)type dict:(NSDictionary *)dict {
    self.type = type;
    
    if (type == WKClearPhotoTypeSimilar) {
        self.name = @"相似照片处理";
        self.detail = [NSString stringWithFormat:@"相似/连拍照片 %ld 张", [dict[@"count"] integerValue]];
    } else if (type == WKClearPhotoTypeScreenshots) {
        self.name = @"截屏照片清理";
        self.detail = [NSString stringWithFormat:@"可清理照片 %ld 张", [dict[@"count"] integerValue]];
    } else if (type == WKClearPhotoTypeThinPhoto) {
        self.name = @"照片瘦身";
        self.detail = [NSString stringWithFormat:@"可优化照片 %ld 张", [dict[@"count"] integerValue]];
    } else {
        return;
    }
    
    self.count = [dict[@"count"] integerValue];
    self.saveStr = [NSString stringWithFormat:@"%.2fMB", [dict[@"saveSpace"] unsignedIntegerValue]/1024.0/1024.0];
}

@end
