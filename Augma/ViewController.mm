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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView* imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:imageView];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView = imageView;


    self.videoCamera = [CvVideoCamera new];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
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
    cv::Mat temp;
    cv::cvtColor(image, temp, CV_RGB2YCrCb);

    // Reduce noise while keeping sharp edges. (Slow algorithm)
    cv::Mat filtered;
    filtered = image;
    // cv::bilateralFilter(temp, filtered, /*recommended*/ 5, /*random values*/50, 100);
    // Get the mask if we remove the background.
    cv::Mat foregroundMask;
    backgroundRemover->apply(filtered, foregroundMask);

    // Erode and dilate with mask and kernel to remove noise,
    // and save the result back to image.
    cv::morphologyEx(foregroundMask, filtered, cv::MORPH_OPEN, kernel);

    #warning Test the gaussian blur, or just blur
    cv::GaussianBlur(filtered, filtered, cvSize(5, 5), 100);
    
    #warning Use threshold if we know what color to filter out

    // Find the largest contour (assuming that would be the hand).
    // Contour: connected area.
    std::vector<Point> largestContour;
    double largestContourArea = -1;
    std::vector<std::vector<Point>> contours;
    cv::findContours(filtered, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    for (std::vector<Point> contour : contours) {
        double area = fabs(cv::contourArea(contour));
        if (area > largestContourArea) {
            largestContourArea = area;
            largestContour = contour;
        }
    }
    
    // Find a polygon around the hand.
    std::vector<Point> hulls;
    cv::convexHull(largestContour, hulls);
    
    // Finding the fingers.
    std::vector<std::vector<cv::Vec4i>> defects;
    cv::convexityDefects(cv::Mat(largestContour), hulls, defects);
    
    // MARK: Display

    // Convert to displayable image.
    UIImage *uiImage = MatToUIImage(filtered);
    // Switch to main thread for UI update.
    __weak ViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController *strongSelf = weakSelf;
        // Show the image.
        [strongSelf.imageView setImage:uiImage];
    });
}
@end
