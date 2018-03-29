//
//  GetSimilarity.h
//  imgsimlartest
//
//  Created by test on 16/3/3.
//  Copyright © 2016年 com.facishare.CoreTest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef double Similarity;

@interface GetSimilarity : NSObject

- (void)setImgWithImgA:(UIImage*)imgA ImgB:(UIImage*)imgB;
- (void)setImgAWidthImg:(UIImage*)img;
- (void)setImgBWidthImg:(UIImage*)img;

- (Similarity)getSimilarityValue; 
+ (Similarity)getSimilarityValueWithImgA:(UIImage*)imga ImgB:(UIImage*)imgb;

@end
