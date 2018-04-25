//
//  ViewController.m
//  JACodeScannerDemo
//
//  Created by Jason on 25/04/2018.
//  Copyright © 2018 Jason. All rights reserved.
//

#import "ViewController.h"
#import <JACodeScanner/JACodeScanner.h>

@interface ViewController () <JAQRCodeScannerDelegate>

@property (nonatomic,strong) JAQRCodeScanner *qrscanner;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"扫一扫";
    CGRect availableRect = CGRectMake(40, 103, UIScreen.mainScreen.bounds.size.width - 80, UIScreen.mainScreen.bounds.size.width - 80);
    self.qrscanner = [[JAQRCodeScanner scannerWithCameraView:self.view
                                               availableRect:availableRect] defalutTheme];
    self.qrscanner.delegate = self;
    self.qrscanner.autoTurnOn = true;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.qrscanner startRecognize];
    typeof(self) weakself = self;
    [self.qrscanner setCompletionHandler:^(NSString * _Nonnull result) {
        [weakself parsingWithString:result];
    }];    
    [[NSNotificationCenter defaultCenter] postNotificationName:JAQRCodeScanDidAppearNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:JAQRCodeScanDidDisappearNotification object:nil];
}

- (void)parsingWithString:(NSString *)qrString {
    if ([qrString hasPrefix:@"http"]) {
        
    }else {
        
    }
}

- (void)qrcodeScanner:(JAQRCodeScanner *)scanner authorizationStatus:(AVAuthorizationStatus)status {
    if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        // 尝试弹窗重新申请权限
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
