//
//  JAQRCodeScanner.m
//  Pods-JACodeScannerDemo
//
//  Created by Jason on 25/04/2018.
//

#import "JAQRCodeScanner.h"

static const char *kScanCodeQueueName = "ScanCodeQueue";
static const char *kVideoOutputQueueName = "VideoOutputQueue";

NSNotificationName const JAQRCodeScanDidDisappearNotification = @"JAQRCodeScanDidDisappearNotification";
NSNotificationName const JAQRCodeScanCompletedNotification = @"JAQRCodeScanCompletedNotification";
NSNotificationName const JAQRCodeScanDidAppearNotification = @"JAQRCodeScanDidAppearNotification";

@interface JAQRCodeScanner ()<
AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureMetadataOutputObjectsDelegate
> {
    CGRect _rect;
    UIView *_view;
    UIView *_containerView;
    UIImageView *_borderImageView;
    UIImageView *_scanLineImageView;
}

@property (nonatomic,strong) AVCaptureSession *captureSession;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic,strong) AVCaptureMetadataOutput *captureMetadataOutput;
@property (nonatomic,weak) AVCaptureVideoDataOutput *captureVideoDataOutput;
@property (nonatomic,weak) AVCaptureDevice *captureDevice;
/// 关闭
@property (nonatomic,assign) BOOL forceTurnOff;
@end

@implementation JAQRCodeScanner

+ (instancetype)scannerWithCameraView:(UIView *)view availableRect:(CGRect)rect {
    JAQRCodeScanner *scanner = [[JAQRCodeScanner alloc] init];
    scanner->_rect = rect;
    scanner->_containerView = [[UIView alloc] initWithFrame:rect];
    scanner->_containerView.clipsToBounds = true;    
    scanner->_view = view;
    
    [scanner addNotifications];
    return scanner;
}

- (instancetype)defalutTheme {
    NSString *resourceBundlePath = [[NSBundle mainBundle] pathForResource:@"Frameworks/JACodeScanner.framework/JACodeScanner" ofType:@"bundle"];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:resourceBundlePath];
    if (resourceBundle) {
        NSString *scaleValue = [UIScreen mainScreen].scale != 3 ? @"@2x" : @"@3x";
        NSString *borderPath = [resourceBundle pathForResource:[@"qrcode_border" stringByAppendingString:scaleValue]  ofType:@"png"];
        UIImage *borderImage = [[[UIImage alloc] initWithContentsOfFile:borderPath] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 25, 25.5, 25.5) resizingMode:UIImageResizingModeTile];
        self->_borderImageView = [[UIImageView alloc] initWithImage:borderImage];
        self->_borderImageView.frame = self->_containerView.bounds;
        NSString *scanLinePath = [resourceBundle pathForResource:[@"qrcode_scanline_qrcode" stringByAppendingString:scaleValue] ofType:@"png"];
        UIImage *scanLineImage = [[UIImage alloc] initWithContentsOfFile:scanLinePath];
        self->_scanLineImageView = [[UIImageView alloc] initWithImage:scanLineImage];
        self->_scanLineImageView.frame = self->_containerView.bounds;
        
        NSString *flashlightPath = [resourceBundle pathForResource:[@"bulb" stringByAppendingString:scaleValue] ofType:@"png"];
        UIImage *flashlightImage = [[UIImage alloc] initWithContentsOfFile:flashlightPath];
        self.flashlightImageView = [[UIImageView alloc] initWithImage:flashlightImage];
        CGRect rect = self.flashlightImageView.frame;
        rect.origin.x = self->_containerView.frame.origin.x;
        rect.origin.y = CGRectGetMaxY(self->_containerView.frame) + 10;
        rect.size.width = CGRectGetWidth(self->_containerView.frame);
        rect.size.height = 60;
        self.flashlightImageView.frame = rect;
        self.flashlightImageView.contentMode = UIViewContentModeCenter;
    }
    
    return self;
}

- (void)addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qrcodeScanAvaiableAction:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qrcodeScanAvaiableAction:) name:JAQRCodeScanDidAppearNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qrcodeScanUnavaiableAction:) name:JAQRCodeScanDidDisappearNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qrcodeScanCompletedAction:) name:JAQRCodeScanCompletedNotification object:nil];
}

- (BOOL)startRecognize {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        if ([self.delegate respondsToSelector:@selector(qrcodeScanner:authorizationStatus:)]) {
            [self.delegate qrcodeScanner:self authorizationStatus:status];
        }
        return false;
    }else if (status == AVAuthorizationStatusNotDetermined){        
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self internalStartRecognize];
                });
            }
        }];
        
    }else {
        return [self internalStartRecognize];
    }
    
    return true;
}

- (void)stopRecognize {
    if (_captureSession) {
        [_captureSession stopRunning];
    }
}

- (void)scanAnimation {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.scanAnimationBlock) {
            self.scanAnimationBlock(self->_scanLineImageView);
        }else {
            CGRect rect = self->_scanLineImageView.frame;
            rect.origin.y = -self->_view.frame.size.height;
            self->_scanLineImageView.frame = rect;
            [UIView animateWithDuration:1.33 animations:^{
                [UIView setAnimationRepeatCount:MAXFLOAT];
                CGRect rect = self->_scanLineImageView.frame;
                rect.origin.y = self->_view.frame.size.height;
                self->_scanLineImageView.frame = rect;
            }];
        }
    });
}

- (BOOL)internalStartRecognize {
    if (self.captureDevice == nil) {
        NSError * error;
        // 获取 AVCaptureDevice 实例
        self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        // 初始化输入流
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
        if (input == nil) { return false; }
        
        // 创建会话
        self.captureSession = [[AVCaptureSession alloc] init];
        
        // 添加输入流
        [self.captureSession addInput:input];
        
        // 初始化 & 添加输出流
        [self.captureSession addOutput:self.captureMetadataOutput];
        
        // 用于检测环境光强度
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        [self.captureSession addOutput:output];
        dispatch_queue_t dispatchOutputQueue = dispatch_queue_create(kVideoOutputQueueName, NULL);
        [output setSampleBufferDelegate:self queue:dispatchOutputQueue];
        self.captureVideoDataOutput = output;
        
        // 创建 dispatch queue.
        dispatch_queue_t dispatchQueue;
        dispatchQueue = dispatch_queue_create(kScanCodeQueueName, NULL);
        [self.captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
        
        // 设置元数据类型 AVMetadataObjectTypeQRCode
        self.captureMetadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
        
        // 创建输出对象
        self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.videoPreviewLayer.frame = self->_view.layer.bounds;
        [self->_view.layer addSublayer:_videoPreviewLayer];
        [self->_view addSubview:self->_containerView];
        [self->_containerView addSubview:self->_borderImageView];
        [self->_containerView addSubview:self->_scanLineImageView];
        [self->_view addSubview:self.flashlightImageView];
    }
    [self.captureSession startRunning];
    [self scanAnimation];
    return true;
}

#pragma mark - getter & setter

- (void)setBorderImage:(UIImage *)borderImage {
    _borderImage = borderImage;
    self->_borderImageView = [[UIImageView alloc] initWithImage:borderImage];
}

- (void)setScanLineImage:(UIImage *)scanLineImage {
    _scanLineImage = scanLineImage;
    self->_scanLineImageView = [[UIImageView alloc] initWithImage:scanLineImage];
}

- (void)setFlashlightImageView:(UIImageView *)flashlightImageView {
    _flashlightImageView = flashlightImageView;
    _flashlightImageView.userInteractionEnabled = true;
}

- (AVCaptureMetadataOutput *)captureMetadataOutput {
    if (!_captureMetadataOutput) {
        _captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
        CGRect viewRect = self->_view.frame;
        CGRect containerRect = self->_rect;
        
        CGFloat x = containerRect.origin.y / viewRect.size.height;
        CGFloat y = containerRect.origin.x / viewRect.size.width;
        CGFloat width = containerRect.size.height / viewRect.size.height;
        CGFloat height = containerRect.size.width / viewRect.size.width;
        
        _captureMetadataOutput.rectOfInterest = CGRectMake(x, y, width, height);
    }
    return _captureMetadataOutput;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
    
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        NSString *result;
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            result = metadataObj.stringValue;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (result) {
                    [self stopRecognize];
                    self.completionHandler(result);
                }
            });
        }
    }
}

-  (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if(self.autoTurnOn == true && self.forceTurnOff == false) {
        CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
        NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
        CFRelease(metadataDict);
        NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
        float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
        
        BOOL result = [self.captureDevice hasTorch];
        
        if ((brightnessValue < 0) && result && self.captureDevice.torchMode == AVCaptureTorchModeOff) {
            if ([self.captureDevice isTorchModeSupported:AVCaptureTorchModeOff]) {
                [self.captureDevice lockForConfiguration:nil];
                [self.captureDevice setTorchMode: AVCaptureTorchModeOn];
                [self.captureDevice unlockForConfiguration];
            }
        }
    }
}

#pragma mark - Events
- (void)qrcodeScanAvaiableAction:(NSNotification *)sender {
    [self scanAnimation];
    if ([sender.name isEqualToString:JAQRCodeScanDidAppearNotification]) {
        self.forceTurnOff = false;
    }
}

- (void)qrcodeScanUnavaiableAction:(NSNotification *)sender {
    self.forceTurnOff = true;
    [self turnOff];    
}

- (void)qrcodeScanCompletedAction:(NSNotification *)sender {
    self.forceTurnOff = true;
    [self turnOff];
}

- (void)turnOff {
    [self.captureDevice lockForConfiguration:nil];
    [self.captureDevice setTorchMode:AVCaptureTorchModeOff];
    [self.captureDevice unlockForConfiguration];
}

#pragma mark - Anything Else
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
