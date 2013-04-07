//
//  Video.m
//  opengl-inputs-template
//
//  Created by Andreas Areschoug on 4/6/13.
//  Copyright (c) 2013 Andreas Areschoug. All rights reserved.
//

#import "Video.h"

@interface Video()

@property(nonatomic,strong)	AVCaptureDeviceInput *videoInput;
@property(nonatomic,strong) AVCaptureVideoDataOutput *videoOutput;
@property(nonatomic,strong) AVAssetReaderTrackOutput *assetReaderOutput;
@property(nonatomic,strong) AVAssetReader *reader;
@property(nonatomic,assign) CMSampleBufferRef buffer;

@property(nonatomic,strong) NSTimer *timer;

@end


@implementation Video

-(void)startReading:(NSString *) videoFile{
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:videoFile];
    
    AVAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:path] options:nil];
    NSError *error = nil;
    
    _reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];

    NSDictionary *options = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
                              (id)kCVPixelBufferWidthKey : @(480),
                              (id)kCVPixelBufferHeightKey : @(320)};

    
    _assetReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:options];
    [_reader addOutput:_assetReaderOutput];
    [_reader startReading];

    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0 target:self selector:@selector(read) userInfo:nil repeats:YES];
    [_timer fire];
    
}

-(void)read {
    
    if ([_reader status] == AVAssetReaderStatusReading) {
        
        _buffer = [_assetReaderOutput copyNextSampleBuffer];
        CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(_buffer);
        
        if (pixelBuffer) {
            [self.delegate processVideoFrame:pixelBuffer];
            CFRelease(pixelBuffer);
        }

    } else {
        [_timer invalidate], _timer = nil;
        [self.delegate didStopReading:[_reader status]];
    }
}


@end
