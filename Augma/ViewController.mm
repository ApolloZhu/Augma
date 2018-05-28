//
//  ViewController.m
//  Augma
//
//  Created by Apollo Zhu on 5/8/18.
//  Copyright © 2018 Augma. All rights reserved.
//

#import "ViewController.h"

/* Use this pattern to match pixels: [
 [0, 1, 0],
 [1, 1, 1],
 [0, 1, 0]
 ], which will result in smooth edges. */
const cv::Mat kernel = cv::getStructuringElement(cv::MORPH_ELLIPSE, cvSize(10, 10));

@interface ViewController ()
    // Capture the video from back camera.
    @property (nonatomic, retain) CvVideoCamera *videoCamera;
    // Display the transformed images.
    @property (nonatomic, weak) UIImageView *imageView;
    @property (nonatomic, retain) AVCaptureSession* captureSession;
    @property (nonatomic, retain) AVCapturePhotoOutput* photoOutput;
    @end

@implementation ViewController
    
- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView* imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:imageView];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView = imageView;
    
    // Select a depth-capable capture device.
    AVCaptureDevice* videoDevice = [AVCaptureDevice
                                    defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera
                                    mediaType:AVMediaTypeVideo
                                    position:AVCaptureDevicePositionBack];
    AVCaptureDeviceInput* videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:NULL];
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession beginConfiguration];
    [self.captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    [self.captureSession addInput:videoDeviceInput];
    
    AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    [videoOutput setSampleBufferDelegate:self queue:queue];
    /// videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    [self.captureSession addOutput:videoOutput];
    AVCaptureDepthDataOutput* depthOutput = [[AVCaptureDepthDataOutput alloc] init];
    [depthOutput setDelegate: self callbackQueue: queue];
    [depthOutput setFilteringEnabled:YES];
    [self.captureSession addOutput:depthOutput];
    [self.captureSession commitConfiguration];
    [self.captureSession startRunning];
}
    
- (void)depthDataOutput:(AVCaptureDepthDataOutput *)output didOutputDepthData:(AVDepthData *)depthData timestamp:(CMTime)timestamp connection:(AVCaptureConnection *)connection {
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    CIImage* ciImage = [[CIImage alloc] initWithCVPixelBuffer:depthData.depthDataMap];
    UIImage* uiImage = [[UIImage alloc] initWithCIImage:ciImage scale:1 orientation:UIImageOrientationUp];
    UIGraphicsBeginImageContext(uiImage.size);
    [uiImage drawInRect:CGRectMake(0, 0, uiImage.size.width, uiImage.size.height)];
    UIImage* copy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    cv::Mat mat;
    UIImageToMat(copy, mat);
    [self processImage:mat];
}
    
- (void)processImage:(cv::Mat &)image {
    try {
        cv::cvtColor(image, image, CV_RGBA2GRAY);
        cv::threshold(image, image,250, 255, CV_THRESH_BINARY);
        // Erode and dilate with mask and kernel to remove noise,
        // and save the result back to image.
        // cv::morphologyEx(image, image, cv::MORPH_OPEN, kernel);
        // Find the largest contour (assuming that would be the hand).
        // Contour: connected area.
        std::vector<cv::Point> largestContour;
        double largestContourArea = -1;
        int largestContourIndex = 0;
        std::vector<std::vector<cv::Point>> contours;
        cv::findContours(image, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
        for (int i = 0;i<contours.size();i++) {
            std::vector<cv::Point> contour = contours[i];
            double area = fabs(cv::contourArea(contour));
            if (area > largestContourArea) {
                largestContourArea = area;
                largestContour = contour;
                largestContourIndex = i;
            }
        }
        
        // cv::approxPolyDP(largestContour, largestContour, 3, true);
        
        cv::cvtColor(image, image, CV_GRAY2RGB);
        cv::Scalar color = cv::Scalar(255, 0, 0);
        cv::drawContours(image, contours, largestContourIndex, color);
        
        // Find a polygon around the hand.
        std::vector<std::vector<cv::Point>> hulls(1);
        cv::convexHull(largestContour, hulls[0]);
        
        color = cv::Scalar(0, 255, 0);
        cv::drawContours(image, hulls, 0, color);
        try {
            // Finding the fingers.
            std::vector<std::vector<cv::Vec4i>> defects(1);
            cv::convexityDefects(largestContour, hulls[0], defects[0]);
            color = cv::Scalar(0, 0, 255);
            for (cv::Vec4i defect : defects[0]) {
                cv::Point start = hulls[0][defect[0]];
                cv::Point end = hulls[0][defect[1]];
                cv::Point far = hulls[0][defect[2]];
                float distance = defect[3] / 256.0;
                cv::line(image, start, end, color);
                cv::line(image, end, far, color);
                cv::line(image, far, start, color);
                cv::circle(image, far, distance, color);
            }
        } catch (std::exception& e) {
            std::cout << e.what() << std::endl;
        }
    } catch (std::exception& e) {
    }
    // MARK: Display
    // Convert to displayable image.
    UIImage *uiImage = MatToUIImage(image);
    // Switch to main thread for UI update.
    __weak ViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController *strongSelf = weakSelf;
        // Show the image.
        [strongSelf.imageView setImage:uiImage];
    });
}
    
    @end
