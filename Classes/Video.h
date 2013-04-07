//
//  Video.h
//  opengl-inputs-template
//
//  Created by Andreas Areschoug on 4/6/13.
//  Copyright (c) 2013 Andreas Areschoug. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@protocol VideoDelegate;

@interface Video : NSObject

@property(nonatomic, weak) id<VideoDelegate> delegate;

-(void)startReading:(NSString *)videoFile;

@end

@protocol VideoDelegate
- (void)processVideoFrame:(CVImageBufferRef)cameraFrame;
- (void)didStopReading:(AVAssetReaderStatus)status;
@end
