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
const cv::Mat kernel = cv::getStructuringElement(cv::MORPH_ELLIPSE, cvSize(3, 3));

@interface ViewController ()
// Capture the video from back camera.
@property (nonatomic, retain) CvVideoCamera *videoCamera;
// Display the transformed images.
@property (nonatomic, weak) UIImageView *imageView;
@end

@implementation ViewController {
    cv::Ptr<cv::BackgroundSubtractorMOG2> backgroundRemover;
    cv::Rect rect;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView* imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:imageView];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView = imageView;
    rect = cv::Rect(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);

    self.videoCamera = [CvVideoCamera new];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Reset background
    backgroundRemover.release();
    backgroundRemover = cv::createBackgroundSubtractorMOG2();
    rect = cv::Rect(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Setting history to 0 since we don't want hands to be considered as background.
    #warning Try `0, 50, false`.
    backgroundRemover = cv::createBackgroundSubtractorMOG2();
    self.videoCamera.delegate = self;
    [self.videoCamera start];
}

- (void)processImage:(cv::Mat &)image {
    #warning Convert to YCC to have better differentiation of colors.
    // And for the background remover to work.
    cv::Mat imageInAnotherColorSpace;
    // cv::cvtColor(image, temp, CV_RGB2YCrCb);
    cv::cvtColor(image, imageInAnotherColorSpace, CV_RGB2HSV);
    
    // Quantize the hue to 30 levels
    // and the saturation to 32 levels
    int hbins = 30, sbins = 32;
    int histSize[] = {hbins, sbins};
    // hue varies from 0 to 179, see cvtColor
    float hranges[] = { 0, 180 };
    // saturation varies from 0 (black-gray-white) to
    // 255 (pure spectrum color)
    float sranges[] = { 0, 256 };
    const float* ranges[] = { hranges, sranges };
    cv::MatND hist;
    // we compute the histogram from the 0-th and 1-st channels
    int channels[] = {0, 1};
    
    calcHist( &imageInAnotherColorSpace, 1, channels, cv::Mat(), // do not use mask
             hist, 2, histSize, ranges,
             true, // the histogram is uniform
             false );
    double maxVal=0;
    minMaxLoc(hist, 0, &maxVal, 0, 0);
    
    int scale = 10;
    cv::Mat histImg = cv::Mat::zeros(sbins*scale, hbins*10, CV_8UC3);
    
    for( int h = 0; h < hbins; h++ )
        for( int s = 0; s < sbins; s++ )
        {
            float binVal = hist.at<float>(h, s);
            int intensity = cvRound(binVal*255/maxVal);
            rectangle( histImg, cv::Point(h*scale, s*scale),
                      cv::Point( (h+1)*scale - 1, (s+1)*scale - 1),
                      cv::Scalar::all(intensity),
                      CV_FILLED );
        }
//    cv::TermCriteria criteria(cv::TermCriteria::Type::MAX_ITER | cv::TermCriteria::Type::EPS, 10, 1);
//    cv::meanShift(hist, rect, criteria);

    // Reduce noise while keeping sharp edges. (Slow algorithm)
//    cv::Mat filtered;
//    filtered = image;
    // cv::bilateralFilter(temp, filtered, /*recommended*/ 5, /*random values*/50, 100);
    // Get the mask if we remove the background.
//    cv::Mat foregroundMask;
//    backgroundRemover->apply(filtered, foregroundMask);

    // Erode and dilate with mask and kernel to remove noise,
    // and save the result back to image.
//    cv::morphologyEx(foregroundMask, filtered, cv::MORPH_OPEN, kernel);

    #warning Test the gaussian blur, or just blur
//    cv::GaussianBlur(filtered, filtered, cvSize(5, 5), 100);
    
    #warning Use threshold if we know what color to filter out

    // Find the largest contour (assuming that would be the hand).
    // Contour: connected area.
//    std::vector<cv::Point> largestContour;
//    double largestContourArea = -1;
//    int largestContourIndex = 0;
//    std::vector<std::vector<cv::Point>> contours;
//    cv::findContours(filtered, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
//    for (int i = 0; i < contours.size();i++) {
//        std::vector<cv::Point> contour = contours[i];
//        double area = fabs(cv::contourArea(contour));
//        if (area > largestContourArea) {
//            largestContourArea = area;
//            largestContour = contour;
//            largestContourIndex = i;
//        }
//    }
    
    // Find a polygon around the hand.
//    std::vector<cv::Point> hulls;
//    cv::convexHull(largestContour, hulls);
//    cv::Scalar color(0x66/255., 0xCC/255., 0xFF/255.);
//    cv::drawContours(filtered, contours, largestContourIndex, color, 10);
    
    // Finding the fingers.
    // std::vector<std::vector<cv::Vec4i>> defects;
    // cv::convexityDefects(largestContour, hulls, defects);
    
    // MARK: Display

    // Convert to displayable image.
    UIImage *uiImage = MatToUIImage(histImg);
    // Switch to main thread for UI update.
    __weak ViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController *strongSelf = weakSelf;
        // Show the image.
        [strongSelf.imageView setImage:uiImage];
    });
}
@end
