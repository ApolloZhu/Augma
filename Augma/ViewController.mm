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
    @property (nonatomic, retain) AVCaptureSession* captureSession;
    @property (nonatomic, retain) AVCapturePhotoOutput* photoOutput;
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
    [depthOutput setFilteringEnabled:true];
    [self.captureSession addOutput:depthOutput];
    /*
     
     
     let outputRect = CGRect(x: 0, y: 0, width: 1, height: 1)
     let videoRect = videoOutput.outputRectConverted(fromMetadataOutputRect: outputRect)
     let depthRect = depthOutput.outputRectConverted(fromMetadataOutputRect: outputRect)
     
     scale = max(videoRect.width, videoRect.height) / max(depthRect.width, depthRect.height)
     
     do {
     try camera.lockForConfiguration()
     
     if let frameDuration = camera.activeDepthDataFormat?
     .videoSupportedFrameRateRanges.first?.minFrameDuration {
     camera.activeVideoMinFrameDuration = frameDuration
     }
     
     camera.unlockForConfiguration()
     } catch {
     fatalError(error.localizedDescription)
     }
     }
     */
    
    
    //    self.photoOutput = [[AVCapturePhotoOutput alloc] init];
    //    [self.captureSession canAddOutput:self.photoOutput];
    //    [self.captureSession addOutput:self.photoOutput];
    //    [self.photoOutput setDepthDataDeliveryEnabled:YES];
    [self.captureSession commitConfiguration];
    
    //    NSArray<AVCaptureDeviceFormat *> *availableFormats = videoDevice.formats;
    //    NSUInteger loc = [availableFormats indexOfObjectPassingTest:^BOOL(AVCaptureDeviceFormat * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    //        FourCharCode pixelFormatType = CMFormatDescriptionGetMediaSubType(obj.formatDescription);
    //        BOOL result = pixelFormatType == kCVPixelFormatType_DepthFloat16
    //        || pixelFormatType == kCVPixelFormatType_DepthFloat32;
    //        NSLog(result ? @"Yes" : @"No");
    //        return result;
    //    }];
    //
    //    [self.captureSession beginConfiguration];
    //    videoDevice.activeDepthDataFormat = availableFormats[loc];
    //    [self.captureSession commitConfiguration];
    
    [self.captureSession startRunning];
    
    //    self.videoCamera = [CvVideoCamera new];
    //    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    //    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    //    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
}
    
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Setting history to 0 since we don't want hands to be considered as background.
    //    #warning Try `0, 50, false`.
    //    backgroundRemover = cv::createBackgroundSubtractorMOG2();
    //    self.videoCamera.delegate = self;
    //    [self.videoCamera start];
}
    
- (void)depthDataOutput:(AVCaptureDepthDataOutput *)output didOutputDepthData:(AVDepthData *)depthData timestamp:(CMTime)timestamp connection:(AVCaptureConnection *)connection {
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    CIImage* ciImage = [[CIImage alloc] initWithCVPixelBuffer:depthData.depthDataMap];
    UIImage* uiImage = [[UIImage alloc] initWithCIImage:ciImage scale:1 orientation:UIImageOrientationUp];
    __weak ViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController *strongSelf = weakSelf;
        // Show the image.
        [strongSelf.imageView setImage:uiImage];
    });
}
    
    //- (void)capture {
    //    AVCapturePhotoSettings* photoSettings = [AVCapturePhotoSettings photoSettings];
    //    [photoSettings setDepthDataDeliveryEnabled:YES];
    //    // Shoot the photo, using a custom class to handle capture delegate callbacks.
    //    [self.photoOutput capturePhotoWithSettings:photoSettings delegate:self];
    //}
    //
    //- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    //    AVDepthData* data = photo.depthData;
    //    CVPixelBufferRef pixels = data.depthDataMap;
    //    NSLog(@"HI");
    //
    //}
    
    //- (void)processImage:(cv::Mat &)image {
    //    #warning Convert to YCC to have better differentiation of colors.
    //    // And for the background remover to work.
    //    cv::Mat temp;
    //    cv::cvtColor(image, temp, CV_RGB2YCrCb);
    //
    //    // Reduce noise while keeping sharp edges. (Slow algorithm)
    //    cv::Mat filtered;
    //    filtered = image;
    //    // cv::bilateralFilter(temp, filtered, /*recommended*/ 5, /*random values*/50, 100);
    //    // Get the mask if we remove the background.
    //    cv::Mat foregroundMask;
    //    backgroundRemover->apply(filtered, foregroundMask);
    //
    //    // Erode and dilate with mask and kernel to remove noise,
    //    // and save the result back to image.
    //    cv::morphologyEx(foregroundMask, filtered, cv::MORPH_OPEN, kernel);
    //
    //    #warning Test the gaussian blur, or just blur
    //    cv::GaussianBlur(filtered, filtered, cvSize(5, 5), 100);
    //
    //    #warning Use threshold if we know what color to filter out
    //
    //    // Find the largest contour (assuming that would be the hand).
    //    // Contour: connected area.
    //    std::vector<Point> largestContour;
    //    double largestContourArea = -1;
    //    std::vector<std::vector<Point>> contours;
    //    cv::findContours(filtered, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    //    for (std::vector<Point> contour : contours) {
    //        double area = fabs(cv::contourArea(contour));
    //        if (area > largestContourArea) {
    //            largestContourArea = area;
    //            largestContour = contour;
    //        }
    //    }
    //
    //    // Find a polygon around the hand.
    //    std::vector<Point> hulls;
    //    cv::convexHull(largestContour, hulls);
    //
    //    // Finding the fingers.
    //    std::vector<std::vector<cv::Vec4i>> defects;
    //    cv::convexityDefects(cv::Mat(largestContour), hulls, defects);
    //
    //    // MARK: Display
    //
    //    // Convert to displayable image.
    //    UIImage *uiImage = MatToUIImage(filtered);
    //    // Switch to main thread for UI update.
    //    __weak ViewController *weakSelf = self;
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        ViewController *strongSelf = weakSelf;
    //        // Show the image.
    //        [strongSelf.imageView setImage:uiImage];
    //    });
    //}
@end
