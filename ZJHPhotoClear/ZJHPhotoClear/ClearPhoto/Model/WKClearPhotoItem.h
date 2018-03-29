//
//  WKClearPhotoItem.h
//  WuKongClearPhotoDemo
//
//  Created by ZhangJingHao2345 on 2018/3/8.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WKClearPhotoType) {
    WKClearPhotoTypeUnknow      = 0, // 未知
    WKClearPhotoTypeSimilar     = 1, // 相似图片
    WKClearPhotoTypeScreenshots = 2, // 截屏图片
    WKClearPhotoTypeThinPhoto   = 3, // 图片瘦身
};

@interface WKClearPhotoItem : NSObject

@property (nonatomic, assign) WKClearPhotoType type;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, copy) NSString *saveStr;
@property (nonatomic, assign) NSInteger count;

- (instancetype)initWithType:(WKClearPhotoType)type
                    dataDict:(NSDictionary *)dict;

@end
