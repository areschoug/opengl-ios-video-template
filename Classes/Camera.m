//
//  Camera.m
//  opengl-inputs-template
//
//  Created by Andreas Areschoug on 4/6/13.
//  Copyright (c) 2013 Andreas Areschoug. All rights reserved.
//

#import "Camera.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@interface Camera() <AVCaptureVideoDataOutputSampleBufferDelegate>

@property(nonatomic,strong) AVCaptureSession *captureSession;
@property(nonatomic,strong) AVCaptureDeviceInput *videoInput;
@property(nonatomic,strong) AVCaptureVideoDataOutput *videoOutput;

@end

@implementation Camera

#pragma mark -
#pragma mark Initialization and teardown

- (id)init {
    self = [super init];
    if (self) {
        AVCaptureDevice *backFacingCamera = nil;
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices) {
            if ([device position] == AVCaptureDevicePositionBack) {
                backFacingCamera = device;
            }
        }
        

        _captureSession = [[AVCaptureSession alloc] init];
        
        NSError *error = nil;
        _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:backFacingCamera error:&error];
        if ([_captureSession canAddInput:_videoInput]) {
            [_captureSession addInput:_videoInput];
        }

        
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setAlwaysDiscardsLateVideoFrames:YES];

        [_videoOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];

        [_videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];

        
        if ([_captureSession canAddOutput:_videoOutput]) {
            [_captureSession addOutput:_videoOutput];
        } else {
            NSLog(@"Couldn't add video output");
        }
        
        [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];

    }
    return self;
}

- (void)startCamera{
    if (![_captureSession isRunning]) [_captureSession startRunning];
}

- (void)stopCamera{
    if ([_captureSession isRunning])[_captureSession stopRunning];
}

- (void)dealloc {
    [self stopCamera];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	[self.delegate processCameraFrame:pixelBuffer];
}


@end
