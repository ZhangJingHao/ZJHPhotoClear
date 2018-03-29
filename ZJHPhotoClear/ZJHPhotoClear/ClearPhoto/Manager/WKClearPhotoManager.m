//
//  WKClearPhotoManager.m
//  WKClearPhoto
//
//  Created by ZhangJingHao2345 on 2018/2/28.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import "WKClearPhotoManager.h"
#import "GetSimilarity.h"
#import "ImageCompare.h"

@interface WKClearPhotoManager () <PHPhotoLibraryChangeObserver>

@property (nonatomic, strong, readwrite) NSMutableArray *similarArr;
@property (nonatomic, strong, readwrite) NSDictionary *similarInfo;
@property (nonatomic, strong, readwrite) NSMutableArray *screenshotsArr;
@property (nonatomic, strong, readwrite) NSDictionary *screenshotsInfo;
@property (nonatomic, strong, readwrite) NSMutableArray *thinPhotoArr;
@property (nonatomic, strong, readwrite) NSDictionary *thinPhotoInfo;
@property (nonatomic, assign, readwrite) double totalSaveSpace;

@property (nonatomic, assign) NSUInteger similarSaveSpace;
@property (nonatomic, assign) NSUInteger screenshotsSaveSpace;
@property (nonatomic, assign) NSUInteger thinPhotoSaveSpce;

@property (nonatomic, strong) PHFetchResult *assetArr;
@property (nonatomic, strong) PHImageRequestOptions *imageOpt;
@property (nonatomic, strong) PHImageRequestOptions *sizeOpt;
@property (nonatomic, strong) PHAsset *lastAsset;
@property (nonatomic, strong) UIImage *lastImage;
@property (nonatomic, strong) NSData *lastImageData;
@property (nonatomic, assign) BOOL lastSame;

@property (nonatomic, copy) void (^completionHandler)(BOOL success, NSError *error);
@property (nonatomic, copy) void (^processHandler)(NSInteger current, NSInteger total);


@end

@implementation WKClearPhotoManager

+ (WKClearPhotoManager *)shareManager {
    static WKClearPhotoManager *mgr = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        mgr = [[WKClearPhotoManager alloc] init];
    });
    return mgr;
}

#pragma mark - LibraryChange 相册变换通知

- (instancetype)init {
    self = [super init];
    if (self) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    // 筛选出没必要的变动
    PHFetchResultChangeDetails *collectionChanges =
    [changeInstance changeDetailsForFetchResult:self.assetArr];
    if (collectionChanges == nil || self.notificationStatus != WKPhotoNotificationStatusDefualt) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(clearPhotoLibraryDidChange)]) {
            [self.delegate clearPhotoLibraryDidChange];
        }
    });
}

#pragma mark - GetImage 获取图片

// 加载照片
- (void)loadPhotoWithProcess:(void (^)(NSInteger current, NSInteger total))process
           completionHandler:(void (^)(BOOL success, NSError *error))completion {
    [self resetTagData];
    self.processHandler = process;
    self.completionHandler = completion;
    
    // 获取当前App的相册授权状态
    PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
    // 判断授权状态
    if (authorizationStatus == PHAuthorizationStatusAuthorized) {
        // 如果已经授权, 获取图片
        [self getAllAsset];
    }
    // 如果没决定, 弹出指示框, 让用户选择
    else if (authorizationStatus == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            // 如果用户选择授权, 则获取图片
            if (status == PHAuthorizationStatusAuthorized) {
                [self getAllAsset];
            }
        }];
    } else {
        [self noticeAlert];
    }
}

// 获取相簿中的PHAsset对象
- (void)getAllAsset {
    // 获取所有资源的集合，并按资源的创建时间排序
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate"
                                                              ascending:NO]];
    PHFetchResult *result = [PHAsset fetchAssetsWithOptions:options];
    self.assetArr = result;
    
    [self requestImageWithIndex:0];
}

// 获取图片
- (void)requestImageWithIndex:(NSInteger)index {
    self.processHandler(index, self.assetArr.count);

    if (index >= self.assetArr.count) {
        [self loadCompletion];
        self.completionHandler(YES, nil);
        return;
    }
    
    // 筛选本地图片，过滤视频、iCloud图片
    PHAsset *asset = self.assetArr[index];
    if (asset.mediaType != PHAssetMediaTypeImage || asset.sourceType != PHAssetSourceTypeUserLibrary) {
        [self requestImageWithIndex:index+1];
        return;
    }

    // 获取缩率图
    PHImageManager *mgr = [PHImageManager defaultManager];
    __weak typeof(self) weakSelf = self;
    [mgr requestImageForAsset:asset
                   targetSize:CGSizeMake(125, 125)
                  contentMode:PHImageContentModeDefault
                      options:self.imageOpt
                resultHandler:^(UIImage *result, NSDictionary *info) {
                    [weakSelf getImageSizeWithIndex:index
                                              image:result];
                }];
}

// 获取原图片大小
- (void)getImageSizeWithIndex:(NSInteger)index
                        image:(UIImage *)image {
    __weak typeof(self) weakSelf = self;
    PHImageManager *mgr = [PHImageManager defaultManager];
    [mgr requestImageDataForAsset:self.assetArr[index]
                          options:self.sizeOpt
                    resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                        [weakSelf dealImageWithIndex:index
                                               image:image
                                           imageData:imageData];
                    }];
}

#pragma mark - DealImage 处理图片

// 处理相片
- (void)dealImageWithIndex:(NSInteger)index
                     image:(UIImage *)image
                 imageData:(NSData *)imageData {
    NSLog(@"原图 %.2fM，缩率图 %@", imageData.length/1024.0/1024.0, NSStringFromCGSize(image.size));

    PHAsset *asset = self.assetArr[index];
    BOOL isSameDay = [self isSameDay:self.lastAsset.creationDate
                               date2:asset.creationDate];
    // 相似图片
    if (self.lastAsset && isSameDay) {
//        BOOL isLike = [GetSimilarity getSimilarityValueWithImgA:self.lastImage ImgB:image] > 0.9;
        BOOL isLike = [ImageCompare isImage:self.lastImage likeImage:image];
        if (isLike) {
            [self updateSimilarArrWithAsset:asset image:image imageData:imageData];
            self.lastSame = YES;
        } else {
            self.lastSame = NO;
        }
    } else {
        self.lastSame = NO;
    }
    
    // 截屏图片
    if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoScreenshot) {
        NSDictionary *lastDict = self.screenshotsArr.lastObject;
        if (lastDict && !isSameDay) {
            lastDict = nil;
        }
        [self updateScreenShotsWithAsset:asset
                                   image:image
                               imageData:imageData
                                lastDict:lastDict];
    }
    
    // 照片瘦身
    [self dealThinPhotoWithAsset:asset
                           image:image
                       imageData:imageData];
    
    self.lastAsset = asset;
    self.lastImage = image;
    self.lastImageData = imageData;
    [self requestImageWithIndex:index+1];
}

// 更新相似图片数据
- (void)updateSimilarArrWithAsset:(PHAsset *)asset
                            image:(UIImage *)image
                        imageData:(NSData *)imageData {
    NSDictionary *lastDict = self.similarArr.lastObject;
    if (!self.lastSame) {
        lastDict = nil;
    }
    
    if (!lastDict) {
        NSDictionary *itemDict = @{ @"asset" : self.lastAsset,
                                    @"image" : self.lastImage,
                                    @"imageData" : self.lastImageData,
                                    @"imageSize" : @(self.lastImageData.length) };
        NSString *keyStr = [self stringWithDate:asset.creationDate];
        lastDict = @{keyStr : [@[itemDict] mutableCopy]};
        [self.similarArr addObject:lastDict];
    }
    
    self.similarSaveSpace = self.similarSaveSpace + imageData.length;
    NSMutableArray *itemArr = lastDict.allValues.lastObject;
    NSDictionary *itemDict = @{ @"asset" : asset,
                                @"image" : image,
                                @"imageData" : self.lastImageData,
                                @"imageSize" : @(imageData.length)};
    [itemArr addObject:itemDict];
    lastDict = @{lastDict.allKeys.lastObject : itemArr};
    [self.similarArr replaceObjectAtIndex:self.similarArr.count-1
                               withObject:lastDict];
}

// 更新截屏图片数据
- (void)updateScreenShotsWithAsset:(PHAsset *)asset
                             image:(UIImage *)image
                         imageData:(NSData *)imageData
                          lastDict:(NSDictionary *)lastDict{
    NSDictionary *itemDict = @{ @"asset" : asset,
                                @"image" : image,
                                @"imageData" : imageData,
                                @"imageSize" : @(imageData.length) };
    if (!lastDict) {
        NSString *keyStr = [self stringWithDate:asset.creationDate];
        lastDict = @{keyStr : [@[itemDict] mutableCopy]};
        [self.screenshotsArr addObject:lastDict];
    } else {
        NSMutableArray *itemArr = lastDict.allValues.lastObject;
        [itemArr addObject:itemDict];
        lastDict = @{lastDict.allKeys.lastObject : itemArr};
        [self.screenshotsArr replaceObjectAtIndex:self.screenshotsArr.count-1
                                       withObject:lastDict];
    }
    self.screenshotsSaveSpace = self.screenshotsSaveSpace + imageData.length;
}

// 处理瘦身图片
- (void)dealThinPhotoWithAsset:(PHAsset *)asset
                         image:(UIImage *)image
                     imageData:(NSData *)imageData {
    if (imageData.length < 1024.0 * 1024.0 * 1.5) {
        return;
    }
    
    NSDictionary *itemDict = @{ @"asset" : asset,
                                @"image" : image,
                                @"imageData" : imageData,
                                @"imageSize" : @(imageData.length)};
    [self.thinPhotoArr addObject:itemDict];
    
    self.thinPhotoSaveSpce = self.thinPhotoSaveSpce + (imageData.length - 1024.0 * 1024.0);
}

// 重置数据
- (void)resetTagData {
    self.similarArr = nil;
    self.similarInfo = nil;
    self.similarSaveSpace = 0;
    
    self.screenshotsArr = nil;
    self.screenshotsInfo = nil;
    self.thinPhotoSaveSpce = 0;
    
    self.thinPhotoArr = nil;
    self.thinPhotoInfo = nil;
    self.screenshotsSaveSpace = 0;
    
    self.totalSaveSpace = 0;
}

// 加载完成
- (void)loadCompletion {
    self.similarInfo = [self getInfoWithDataArr:self.similarArr
                                      saveSpace:self.similarSaveSpace];
    self.screenshotsInfo = [self getInfoWithDataArr:self.screenshotsArr
                                          saveSpace:self.screenshotsSaveSpace];
    
    self.thinPhotoInfo = @{@"count" : @(self.thinPhotoArr.count),
                           @"saveSpace" : @(self.thinPhotoSaveSpce)};
    self.totalSaveSpace = self.similarSaveSpace + self.thinPhotoSaveSpce + self.screenshotsSaveSpace;
    
    NSLog(@"相似照片可省 ：%.2fMB", self.similarSaveSpace / 1024.0 / 1024.0);
    NSLog(@"截屏照片可省 ：%.2fMB", self.screenshotsSaveSpace / 1024.0 / 1024.0);
    NSLog(@"压缩照片可省 ：%.2fMB", self.thinPhotoSaveSpce / 1024.0 / 1024.0);
    
    
    NSLog(@"***ZJH 加载完成");
}

#pragma mark - Private 私有方法

- (NSDictionary *)getInfoWithDataArr:(NSArray *)dataArr
                           saveSpace:(NSUInteger)saveSpace {
    NSUInteger similarCount = 0;
    for (NSDictionary *dict in dataArr) {
        NSArray *arr = dict.allValues.lastObject;
        similarCount = similarCount + arr.count;
    }
    return @{@"count":@(similarCount), @"saveSpace" : @(saveSpace)};
}

// 是否为同一天
- (BOOL)isSameDay:(NSDate *)date1 date2:(NSDate *)date2 {
    if (!date1 || !date2) {
        return NO;
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents *comp2 = [calendar components:unitFlags fromDate:date2];
    return  [comp1 day] == [comp2 day] &&
            [comp1 month] == [comp2 month] &&
            [comp1 year]  == [comp2 year];
}

// NSDate转NSString
- (NSString *)stringWithDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy年MM月dd日"];
    return [dateFormatter stringFromDate:date];
}

// 开启权限提示
- (void)noticeAlert {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"此功能需要相册授权"
                                        message:@"请您在设置系统中打开授权开关"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *left = [UIAlertAction actionWithTitle:@"取消"
                                                   style:UIAlertActionStyleCancel
                                                 handler:nil];
    UIAlertAction *right = [UIAlertAction actionWithTitle:@"前往设置"
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * _Nonnull action) {
                                                      NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                      [[UIApplication sharedApplication] openURL:url];
                                                  }];
    [alert addAction:left];
    [alert addAction:right];
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    [vc presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Getter 懒加载

- (NSMutableArray *)similarArr {
    if (!_similarArr) {
        _similarArr = [NSMutableArray array];
    }
    return _similarArr;
}

- (NSMutableArray *)screenshotsArr {
    if (!_screenshotsArr) {
        _screenshotsArr = [NSMutableArray array];
    }
    return _screenshotsArr;
}

- (NSMutableArray *)thinPhotoArr {
    if (!_thinPhotoArr) {
        _thinPhotoArr = [NSMutableArray array];
    }
    return _thinPhotoArr;
}

- (PHImageRequestOptions *)imageOpt {
    if (!_imageOpt) {
        _imageOpt = [[PHImageRequestOptions alloc] init];
        // resizeMode 属性控制图像的剪裁
        _imageOpt.resizeMode = PHImageRequestOptionsResizeModeNone;
        // deliveryMode 则用于控制请求的图片质量
        _imageOpt.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    }
    return _imageOpt;
}

- (PHImageRequestOptions *)sizeOpt {
    if (!_sizeOpt) {
        _sizeOpt = [[PHImageRequestOptions alloc] init];
        _sizeOpt.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        _sizeOpt.resizeMode = PHImageRequestOptionsResizeModeExact;
    }
    return _sizeOpt;
}

#pragma mark - DeleteImage 删除图片

/// 删除照片
+ (void)deleteAssets:(NSArray<PHAsset *> *)assets completionHandler:(void (^)(BOOL success, NSError *error))completion {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest deleteAssets:assets];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(success, error);
            });
        }
    }];
}

// 获取原图
+ (void)getOriginImageWithAsset:(PHAsset *)asset completionHandler:(void (^)(UIImage *result, NSDictionary *info))completion {
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    PHImageManager *mgr = [PHImageManager defaultManager];
    [mgr requestImageForAsset:asset
                   targetSize:PHImageManagerMaximumSize
                  contentMode:PHImageContentModeDefault
                      options:options
                resultHandler:completion];
}

#pragma mark - 图片压缩

+ (void)compressImage:(UIImage *)image
            imageSize:(NSUInteger)imageSize
    completionHandler:(void (^)(UIImage *compressImg, NSUInteger compresSize))completion {
    // 子线程压缩
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSDictionary *imgDict = [self compressImage:image imageSize:imageSize];
        //获取主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(imgDict[@"image"], [imgDict[@"length"] unsignedIntegerValue]);
            }
        });
    });
}

// 压缩图片1 小于1.5M -- 先压缩大小再压缩数据
+ (NSDictionary *)compressImage:(UIImage *)image imageSize:(NSUInteger)imageSize {
    NSLog(@"图片压缩前 data: 0MB, size:%@",  NSStringFromCGSize(image.size));
    // 压缩率
    CGFloat rate = 1024 * 1024.0 / imageSize;
    
    // 数据压缩
    NSData *data = UIImageJPEGRepresentation(image, rate);
    UIImage *img = [UIImage imageWithData:data];
    NSLog(@"数据压缩后 data: %.2fMB, size:%@", data.length / 1024.0 / 1024.0, NSStringFromCGSize(img.size));
    
    if (data.length > 1024 * 1024 * 1.5) {
        // 大小压缩
        CGSize size = CGSizeMake(image.size.width * rate, image.size.height * rate);
        UIImage *img2 = [self imageWithImage:img scaledToSize:size];
        NSData *data2 = UIImageJPEGRepresentation(img2, 1);
        NSLog(@"大小压缩后 data: %.2fMB, size:%@", data2.length / 1024.0 / 1024.0, NSStringFromCGSize(img2.size));
        if (data2.length > 1024 * 1024 * 1.5) {
             return [self compressImage:img2 imageSize:data2.length];
        } else {
            return @{@"image":img2, @"length":@(data2.length)};
        }
    } else {
        return @{@"image":img, @"length":@(data.length)};
    }
}

+ (void)compressImageWithData:(NSData *)imageData
            completionHandler:(void (^)(UIImage *compressImg, NSUInteger compresSize))completion {
    // 子线程压缩
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSDictionary *imgDict = [self compressData:imageData];
        //获取主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(imgDict[@"image"], [imgDict[@"length"] unsignedIntegerValue]);
            }
        });
    });
}


// 压缩图片2 小于1.5M -- 先压缩大小再压缩数据
+ (NSDictionary *)compressData:(NSData *)imageData {
    NSUInteger imageSize = imageData.length;
    UIImage *image = [UIImage imageWithData:imageData];
    NSLog(@"图片压缩前 data: %.2fMB, size:%@", imageData.length / 1024.0 / 1024.0, NSStringFromCGSize(image.size));

    // 压缩率
    CGFloat rate = 1024 * 1024.0 / imageSize;
    
    // 大小压缩
    CGSize size = CGSizeMake(image.size.width * rate, image.size.height * rate);
    UIImage *img2 = [self imageWithImage:image scaledToSize:size];
    NSData *data2 =  UIImageJPEGRepresentation(img2, 1);
    NSLog(@"大小压缩后 data: %.2fMB, size:%@", data2.length / 1024.0 / 1024.0, NSStringFromCGSize(size));
    if (data2.length > 1024 * 1024 * 1.5) {
        // 数据压缩
        NSData *data = UIImageJPEGRepresentation(img2, rate);
        UIImage *img = [UIImage imageWithData:data];
        NSLog(@"数据压缩后 data: %.2fMB, size:%@", data.length / 1024.0 / 1024.0, NSStringFromCGSize(img.size));
        if (data.length > 1024 * 1024 * 1.5) {
            return [self compressData:data];
        } else {
            return @{@"image":img, @"length":@(data.length)};
        }
    } else {
        return @{@"image":img2, @"length":@(data2.length)};
    }
}

// 压缩大小
+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (void)tipWithMessage:(NSString *)str {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"提示"
                                        message:str
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action =
    [UIAlertAction actionWithTitle:@"确定"
                             style:UIAlertActionStyleCancel
                           handler:nil];
    [alert addAction:action];
    
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    [vc presentViewController:alert animated:YES completion:nil];
}

@end
