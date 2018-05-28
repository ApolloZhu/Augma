//
//  ViewController.h
//  Augma
//
//  Created by Apollo Zhu on 5/8/18.
//  Copyright © 2018 Augma. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/video/background_segm.hpp>
#import <opencv2/videoio/cap_ios.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface ViewController : UIViewController<AVCaptureDepthDataOutputDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@end

