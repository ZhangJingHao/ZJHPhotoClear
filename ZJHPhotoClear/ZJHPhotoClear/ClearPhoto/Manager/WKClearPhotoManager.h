//
//  WKClearPhotoManager.h
//  WKClearPhoto
//
//  Created by ZhangJingHao2345 on 2018/2/28.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef NS_ENUM(NSInteger, WKPhotoNotificationStatus) {
    WKPhotoNotificationStatusDefualt  = 0, // 相册变更默认处理
    WKPhotoNotificationStatusClose    = 1, // 相册变更不处理
    WKPhotoNotificationStatusNeed     = 2, // 相册变更主动处理
};

@protocol WKClearPhotoManagerDelegate<NSObject>
@optional
/// 相册变动代理方法
- (void)clearPhotoLibraryDidChange;
@end

@interface WKClearPhotoManager : NSObject

+ (WKClearPhotoManager *)shareManager;

/// 代理
@property (nonatomic, weak) id<WKClearPhotoManagerDelegate> delegate;

/// 变更状态
@property (nonatomic, assign) WKPhotoNotificationStatus notificationStatus;

/// 相似照片数据 [{date1:[dict1,dict2]}, {date2:[dict3,dict4]}...]
@property (nonatomic, strong, readonly) NSMutableArray *similarArr;
/// 相似照片信息
@property (nonatomic, strong, readonly) NSDictionary *similarInfo;

/// 截图照片数据
@property (nonatomic, strong, readonly) NSMutableArray *screenshotsArr;
/// 截图照片信息
@property (nonatomic, strong, readonly) NSDictionary *screenshotsInfo;

/// 照片瘦身数据
@property (nonatomic, strong, readonly) NSMutableArray *thinPhotoArr;
/// 照片瘦身信息
@property (nonatomic, strong, readonly) NSDictionary *thinPhotoInfo;

/// 节约空间 [dict3,dict4,....]
@property (nonatomic, assign, readonly) double totalSaveSpace;

/// 加载照片
- (void)loadPhotoWithProcess:(void (^)(NSInteger current, NSInteger total))process
           completionHandler:(void (^)(BOOL success, NSError *error))completion;

/// 删除照片
+ (void)deleteAssets:(NSArray<PHAsset *> *)assets
   completionHandler:(void (^)(BOOL success, NSError *error))completion;

/// 获取原图
+ (void)getOriginImageWithAsset:(PHAsset *)asset
              completionHandler:(void (^)(UIImage *result, NSDictionary *info))completion;

/// 压缩照片
+ (void)compressImageWithData:(NSData *)imageData
            completionHandler:(void (^)(UIImage *compressImg, NSUInteger compresSize))completion;

+ (void)tipWithMessage:(NSString *)str;

@end
