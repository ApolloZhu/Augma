//
//  ViewController.m
//  Augma
//
//  Created by Apollo Zhu on 5/8/18.
//  Copyright © 2018 Augma. All rights reserved.
//

#import "ZhiyuZhu_ViewController.h"

/* Use this pattern to match pixels: [
 [0, 1, 0],
 [1, 1, 1],
 [0, 1, 0]
 ], which will result in smooth edges. */
const cv::Mat kernel = cv::getStructuringElement(cv::MORPH_ELLIPSE, cvSize(10, 10));

@interface ViewController ()
    // Display the transformed images.
    @property (nonatomic) UIImageView *imageView;
    @property (nonatomic) UILabel *label;
    @property (nonatomic) AVCaptureSession *captureSession;
    @property (nonatomic) AVCapturePhotoOutput *photoOutput;
@end

@implementation ViewController {
    cv::Mat photo;
    float xScale;
    float yScale;
}
    
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}
    
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}
    
- (void)viewDidLoad {
    [super viewDidLoad];
    // MARK: Layout Contents
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.imageView];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.imageView setContentMode:UIViewContentModeScaleAspectFill];
    UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *background = [[UIVisualEffectView alloc] initWithEffect: effect];
    [self.view addSubview:background];
    [background setTranslatesAutoresizingMaskIntoConstraints:NO];
    [background.layer setCornerRadius:10];
    [background.layer setMasksToBounds:YES];
    NSArray<NSLayoutConstraint *> *constraints =
    @[[background.widthAnchor constraintEqualToConstant:200],
      [background.heightAnchor constraintEqualToConstant:50],
      [background.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
      [background.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor]];
    [NSLayoutConstraint activateConstraints: constraints];
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
    [background.contentView addSubview:self.label];
    [self.label setTextColor:UIColor.whiteColor];
    [self.label setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle]];
    [self.label setMinimumScaleFactor:0.5];
    [self.label setTextAlignment:NSTextAlignmentCenter];
    [self.label setText:@"Loading..."];
    
    // MARK: Select a depth-capable capture device
    AVCaptureDevice *videoDevice = [AVCaptureDevice
                                    defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera
                                    mediaType:AVMediaTypeVideo
                                    position:AVCaptureDevicePositionBack];
    AVCaptureDeviceInput *videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:NULL];
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession beginConfiguration];
    // MARK: Capture the video from back camera
    [self.captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    [self.captureSession addInput:videoDeviceInput];
    // MARK: Get Video Frames
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    [videoOutput setSampleBufferDelegate:self queue:queue];
    [self.captureSession addOutput:videoOutput];
    // MARK: Get Depth Data
    AVCaptureDepthDataOutput *depthOutput = [[AVCaptureDepthDataOutput alloc] init];
    [depthOutput setDelegate: self callbackQueue: queue];
    [depthOutput setFilteringEnabled:YES];
    [self.captureSession addOutput:depthOutput];
    
    [self.captureSession commitConfiguration];
    [self.captureSession startRunning];
}
    
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    CVPixelBufferRef pixels = CMSampleBufferGetImageBuffer(sampleBuffer);
    cv::cvtColor([self pixelBufferToMat:pixels], photo, CV_RGBA2RGB);
}
    
- (void)depthDataOutput:(AVCaptureDepthDataOutput *)output didOutputDepthData:(AVDepthData *)depthData timestamp:(CMTime)timestamp connection:(AVCaptureConnection *)connection {
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    cv::Mat mat = [self pixelBufferToMat:depthData.depthDataMap];
    xScale = (float)photo.size().width / mat.size().width;
    yScale = (float)photo.size().height / mat.size().height;
    [self processImage:mat outputTo:photo];
}
    
- (cv::Mat)pixelBufferToMat:(CVPixelBufferRef)pixels {
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixels];
    UIImage *uiImage = [[UIImage alloc] initWithCIImage:ciImage scale:1 orientation:UIImageOrientationUp];
    UIGraphicsBeginImageContext(uiImage.size);
    [uiImage drawInRect:CGRectMake(0, 0, uiImage.size.width, uiImage.size.height)];
    UIImage *copy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    cv::Mat mat;
    UIImageToMat(copy, mat);
    return mat;
}
    
- (cv::Point)scaled:(cv::Point)point {
    return cv::Point(MIN(MAX(point.x * xScale, 0), photo.size().width) ,
                     MIN(MAX(point.y * yScale, 0), photo.size().height));
}
    
- (bool)drawLineFrom:(cv::Point)vertex to:(cv::Point)far in:(cv::Mat &)image withColor:(cv::Scalar)color {
    // Direction of finger
    double angle = atan2(vertex.y - far.y, vertex.x - far.x);
    #warning criteria should base on device orientation
    if (0 > angle) { // Fingers point upwards
        cv::line(image, vertex, far, color, LINE_WIDTH);
        return true;
    } else {
        return false;
    }
}
    
- (void)updateFingerCountTo:(int) num {
    if (num <= 0) {
        [self.label setText:@"Not Found"];
    } else if (num == 1) {
        [self.label setText:@"1 Finger"];
    } else {
        NSString *str = [[NSString alloc] initWithFormat:@"%d Fingers", num];
        [self.label setText: str];
    }
}
    
- (void)processImage:(cv::Mat &)image outputTo:(cv::Mat &)photo {
    int fingerCount = 0;
    try {
        // MARK: - Fix Color
        cv::cvtColor(image, image, CV_RGBA2GRAY);
        cv::threshold(image, image, 250, 255, CV_THRESH_BINARY);
        // Erode and dilate with mask and kernel to remove noise,
        // and save the result back to image.
        cv::morphologyEx(image, image, cv::MORPH_OPEN, kernel);
        
        // MARK: - Find Dominate Connected Area
        
        double largestContourArea = -1;
        int largestContourIndex = -1;
        #define largestContour contours[largestContourIndex]
        std::vector<std::vector<cv::Point>> contours;
        cv::findContours(image, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
        // MARK: Find the largest contour (assuming that would be the hand).
        for (int i = 0;i<contours.size();i++) {
            std::vector<cv::Point> contour = contours[i];
            double area = fabs(cv::contourArea(contour));
            if (area > largestContourArea) {
                largestContourArea = area;
                largestContourIndex = i;
            }
        }
        
        if (-1 == largestContourIndex) throw "Not Found";
        cv::approxPolyDP(largestContour, largestContour, 3, true);
        
        // MARK: Draw contour with red
        cv::Scalar color = cv::Scalar(255, 0, 0);
        for (int i = 0;i<largestContour.size();i++) {
            largestContour[i] = [self scaled:largestContour[i]];
        }
        cv::drawContours(photo, contours, largestContourIndex, color, LINE_WIDTH);
        
        // MARK: - Find Hand Boundary
        
        // MARK: Find a polygon around the hand
        std::vector<std::vector<int>> hulls(1);
        cv::convexHull(largestContour, hulls[0]);
        std::vector<std::vector<cv::Point>> hullPoints(1);
        cv::convexHull(largestContour, hullPoints[0]);
        
        // MARK: Draw convex hull with green
        color = cv::Scalar(0, 255, 0);
        cv::drawContours(photo, hullPoints, 0, color, LINE_WIDTH);
        
        // MARK: - Find Fingers
        std::vector<std::vector<cv::Vec4i>> defects(1);
        cv::convexityDefects(largestContour, hulls[0], defects[0]);
        // MARK: Draw convexity defects with blue
        color = cv::Scalar(0, 0, 255);
        for (cv::Vec4i defect : defects[0]) {
            cv::Point start = largestContour[defect[0]];
            cv::Point end = largestContour[defect[1]];
            cv::Point far = largestContour[defect[2]];
            // Length of finger
            #warning float distance = defect[3] / 256.0;
            fingerCount += [self drawLineFrom:start to:far in:photo withColor:color] ? 1 : 0;
            fingerCount += [self drawLineFrom:end to:far in:photo withColor:color] ? 1 : 0;
            // cv::circle(photo, far, distance, color);
        }
        // TODO: - Process Gesture
    } catch (...) {
        // Ignore all exceptions, and that's OK
    }
    // MARK: - Display
    // Convert to displayable image.
    UIImage *uiImage = MatToUIImage(photo);
    // Switch to main thread for UI update.
    __weak ViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController *strongSelf = weakSelf;
        // Show the image.
        [strongSelf.imageView setImage:uiImage];
        [strongSelf updateFingerCountTo:fingerCount / 2];
    });
}

@end
