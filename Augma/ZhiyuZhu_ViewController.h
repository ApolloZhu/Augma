//
//  ViewController.h
//  Augma
//
//  Created by Apollo Zhu on 5/8/18.
//  Copyright © 2018 Augma. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <UIKit/UIKit.h>

#define LINE_WIDTH 2

@interface ViewController :
    UIViewController<
    AVCaptureDepthDataOutputDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate>
@end
