//
//  ViewController.m
//  Augma
//
//  Created by Apollo Zhu on 5/8/18.
//  Copyright © 2018 Augma. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, retain) CvVideoCamera* videoCamera;
@end

@implementation ViewController {
    UIImageView *imageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:imageView];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;



    self.videoCamera = [CvVideoCamera new];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    self.videoCamera.delegate = self;
    [self.videoCamera start];
}

- (void)processImage:(cv::Mat &)image {
    cv::cvtColor(image, image, CV_RGB2YCrCb);
    __weak ViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController *strongSelf = weakSelf;
        [strongSelf->imageView setImage:MatToUIImage(image)];
    });
}
@end
