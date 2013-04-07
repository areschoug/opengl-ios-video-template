//
//  Camera.h
//  opengl-inputs-template
//
//  Created by Andreas Areschoug on 4/6/13.
//  Copyright (c) 2013 Andreas Areschoug. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CameraDelegate;

@interface Camera : NSObject

@property(nonatomic, weak) id<CameraDelegate> delegate;

- (void)startCamera;
- (void)stopCamera;

@end


@protocol CameraDelegate
- (void)processCameraFrame:(CVImageBufferRef)cameraFrame;
@end
