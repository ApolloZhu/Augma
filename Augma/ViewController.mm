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
    // Display the transformed images.
    @property (nonatomic, weak) UIImageView *imageView;
    @property (nonatomic, retain) AVCaptureSession *captureSession;
    @property (nonatomic, retain) AVCapturePhotoOutput *photoOutput;
    @end

@implementation ViewController {
    cv::Mat photo;
    float xScale;
    float yScale;
}
    
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"%f", UIScreen.mainScreen.scale);
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:imageView];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView = imageView;
    
    // Select a depth-capable capture device.
    AVCaptureDevice *videoDevice = [AVCaptureDevice
                                    defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera
                                    mediaType:AVMediaTypeVideo
                                    position:AVCaptureDevicePositionBack];
    AVCaptureDeviceInput *videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:NULL];
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession beginConfiguration];
    [self.captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    [self.captureSession addInput:videoDeviceInput];
    
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    [videoOutput setSampleBufferDelegate:self queue:queue];
    /// videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    [self.captureSession addOutput:videoOutput];
    AVCaptureDepthDataOutput *depthOutput = [[AVCaptureDepthDataOutput alloc] init];
    [depthOutput setDelegate: self callbackQueue: queue];
    [depthOutput setFilteringEnabled:YES];
    [self.captureSession addOutput:depthOutput];
    [self.captureSession commitConfiguration];
    // Capture the video from back camera.
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
    
- (void)processImage:(cv::Mat &)image outputTo:(cv::Mat &)photo {
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
        cv::drawContours(photo, contours, largestContourIndex, color);
        
        // MARK: - Find Hand Boundary
        
        // MARK: Find a polygon around the hand.
        std::vector<std::vector<int>> hulls(1);
        cv::convexHull(largestContour, hulls[0]);
        std::vector<std::vector<cv::Point>> hullPoints(1);
        cv::convexHull(largestContour, hullPoints[0]);
        
        // MARK: Draw convex hull with green
        color = cv::Scalar(0, 255, 0);
        cv::drawContours(photo, hullPoints, 0, color);
        std::cout << '\n' << std::endl;
        
        // MARK: - Find Fingers.
        std::vector<std::vector<cv::Vec4i>> defects(1);
        cv::convexityDefects(largestContour, hulls[0], defects[0]);
        // MARK: Draw convexity defects with blue
        color = cv::Scalar(0, 0, 255);
        for (cv::Vec4i defect : defects[0]) {
            cv::Point start = largestContour[defect[0]];
            cv::Point end = largestContour[defect[1]];
            cv::Point far = largestContour[defect[2]];
            float distance = defect[3] / 256.0;
            // cv::line(photo, start, end, color);
            cv::line(photo, end, far, color);
            cv::line(photo, far, start, color);
            cv::circle(photo, far, distance, color);
            std::cout << start << ',' << end << ',' << far << " - " << distance << std::endl;
        }
        std::cout << "\n\n" << std::endl;
        // MARK: - Process Gesture
    } catch (...) {
        // std::cout << e.what() << std::endl;
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
    });
}
    
    @end
