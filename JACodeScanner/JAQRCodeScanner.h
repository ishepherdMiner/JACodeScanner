//
//  JAQRCodeScanner.h
//  Pods-JACodeScannerDemo
//
//  Created by Jason on 25/04/2018.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSNotificationName const JAQRCodeScanDidDisappearNotification;
UIKIT_EXTERN NSNotificationName const JAQRCodeScanCompletedNotification;
UIKIT_EXTERN NSNotificationName const JAQRCodeScanDidAppearNotification;

@class JAQRCodeScanner;

@protocol JAQRCodeScannerDelegate <NSObject>

@optional

- (void)qrcodeScanner:(JAQRCodeScanner *)scanner
  authorizationStatus:(AVAuthorizationStatus)status;

@end

NS_CLASS_AVAILABLE_IOS(7_0)
@interface JAQRCodeScanner : NSObject

/// 扫码的边框图片
@property (nonatomic,strong) UIImage *borderImage;
@property (nonatomic,strong) UIImage *scanLineImage;
@property (nonatomic,strong) UIImageView *flashlightImageView;

/// 是否在光线不足时,自动开启手电筒
@property (nonatomic,assign) BOOL autoTurnOn;
@property (nonatomic,copy) void ((^scanAnimationBlock)(UIImageView *scanLineImageView));

@property (nonatomic,weak) id<JAQRCodeScannerDelegate> delegate;

/**
 扫码识别完成后的回调
 */
@property (nonatomic,copy) void (^completionHandler)(NSString * _Nonnull result);

/**
 返回扫描器对象
 
 @param view 放置摄像头的视图
 @param rect 有效的扫描区域
 @return 扫描器对象
 */
+ (instancetype)scannerWithCameraView:(UIView *)view
                        availableRect:(CGRect)rect;

/**
 默认的样式
 
 @return 扫描器对象
 */
- (instancetype)defalutTheme;

/**
 识别二维码
 */
- (BOOL)startRecognize;

/**
 停止识别
 */
- (void)stopRecognize;

@end

NS_ASSUME_NONNULL_END
