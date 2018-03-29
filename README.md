# iOS照片清理功能，包括相似照片清理、截屏照片清理、图片压缩

![照片清理动画.gif](https://upload-images.jianshu.io/upload_images/2120486-ceae19bb2abb134b.gif?imageMogr2/auto-orient/strip)

###一、获取照片

#####1、开启相册权限

首先，需在工程对应的plist文件内添加“Privacy - Photo Library Usage Description”这个key，同时设置其值为“App needs your permission to access the Photo”类似这样的说明。

```
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
```

#####2、获取相簿中的PHAsset对象

PHAsset: 代表照片库中的一个资源，跟 ALAsset 类似，通过 PHAsset 可以获取和保存资源
PHFetchOptions: 获取资源时的参数，可以传 nil，即使用系统默认值
PHFetchResult: 表示一系列的资源结果集合，也可以是相册的集合，从 PHCollection 的类方法中获得

```
    // 获取所有资源的集合，并按资源的创建时间排序
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate"
                                                              ascending:NO]];
    PHFetchResult *result = [PHAsset fetchAssetsWithOptions:options];
```

#####3、获取相片

PhotoKit 无法直接从 PHAsset 的实例中获取图像，而是引入了一个管理器?PHImageManager 获取图像。PHImageManager 是通过请求的方式拉取图像，并可以控制请求得到的图像的尺寸、剪裁方式、质量，缓存以及请求本身的管理（发出请求、取消请求）等。而请求图像的方法是 ?PHImageManager 的一个实例方法。

```
    // 筛选本地图片，过滤视频、iCloud图片
    PHAsset *asset = self.assetArr[index];
    if (asset.mediaType != PHAssetMediaTypeImage || asset.sourceType != PHAssetSourceTypeUserLibrary) {
        [self requestImageWithIndex:index+1];
        return;
    }
    
    // 请求图像的属性
    PHImageRequestOptions *imageOpt = [[PHImageRequestOptions alloc] init];
    // resizeMode 属性控制图像的剪裁
    imageOpt.resizeMode = PHImageRequestOptionsResizeModeNone;
    // deliveryMode 则用于控制请求的图片质量
    imageOpt.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    // 获取缩率图
    PHImageManager *mgr = [PHImageManager defaultManager];
    __weak typeof(self) weakSelf = self;
    [mgr requestImageForAsset:asset
                   targetSize:CGSizeMake(125, 125)
                  contentMode:PHImageContentModeDefault
                      options:imageOpt
                resultHandler:^(UIImage *result, NSDictionary *info) {
                    [weakSelf getImageSizeWithIndex:index
                                              image:result];
                }];
```

* asset，图像对应的 PHAsset。
* targetSize，需要获取的图像的尺寸，如果输入的尺寸大于资源原图的尺寸，则只返回原图。需要注意在 PHImageManager 中，所有的尺寸都是用 Pixel 作为单位（Note that all sizes are in pixels），因此这里想要获得正确大小的图像，需要把输入的尺寸转换为 Pixel。如果需要返回原图尺寸，可以传入 PhotoKit 中预先定义好的常量?PHImageManagerMaximumSize，表示返回可选范围内的最大的尺寸，即原图尺寸。
* contentMode，图像的剪裁方式，与?UIView 的 contentMode 参数相似，控制照片应该以按比例缩放还是按比例填充的方式放到最终展示的容器内。注意如果 targetSize 传入?PHImageManagerMaximumSize，则 contentMode 无论传入什么值都会被视为?PHImageContentModeDefault。
* options，一个?PHImageRequestOptions 的实例，可以控制的内容相当丰富，包括图像的质量、版本，也会有参数控制图像的剪裁，下面再展开说明。
* resultHandler，请求结束后被调用的 block，返回一个包含资源对于图像的 UIImage 和包含图像信息的一个 NSDictionary，在整个请求的周期中，这个 block 可能会被多次调用，关于这点连同 options 参数在下面展开说明。

参考链接：http://kayosite.com/ios-development-and-detail-of-photo-framework-part-two.html

#####3、获取相片原图大小

这里获取的是相片原图的数据大小，请求参数与获取图片类似，可参考上面

```
PHImageRequestOptions *sizeOpt = [[PHImageRequestOptions alloc] init];
    sizeOpt.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    sizeOpt.resizeMode = PHImageRequestOptionsResizeModeExact;
    
    __weak typeof(self) weakSelf = self;
    PHImageManager *mgr = [PHImageManager defaultManager];
    [mgr requestImageDataForAsset:self.assetArr[index]
                          options:sizeOpt
                    resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                        [weakSelf dealImageWithIndex:index
                                               image:image
                                           imageData:imageData];
                    }];
```


###二、存储照片

#####1、保存图片到系统相册

此方法可以直接保存在系统相册的"相机胶卷"中

```
- (void)save {
    // 存储图片到"相机胶卷"
    UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

// 成功保存图片到相册中, 必须调用此方法, 否则会报参数越界错误
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error) {
        NSLog(@"保存失败");
    } else {
        NSLog(@"保存成功");
    }
}
```

#####2、保存图片到自定义相册

首先根据相簿名获取相簿，然后将图片存入到相簿中。详情可参考：https://www.jianshu.com/p/1b3616945fc3


###三、删除照片

```
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
```

###四、相似照片

判断照片的相似度，可分为五步：
1、缩小尺寸
2、简化色彩
3、计算平均值
4、比较像素的灰度
5、计算哈希值

原理介绍参考：https://www.jianshu.com/p/8c3296ba6522
使用opencv判断相似度：http://www.qingpingshan.com/rjbc/ios/202983.html
iOS,OC,图片相似度比较,图片指纹：http://www.cnblogs.com/kongkaikai/p/5251543.html

###五、压缩照片

压缩图片不能压缩到指定大小，有误差，只能计算近似值。这里通过递归的方法，压缩到小于1.5M

```
// 压缩图片 小于1.5M -- 先压缩大小再压缩数据
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
```






