//
//  ViewController.h
//  opengl-inputs-template
//
//  Created by Andreas Areschoug on 4/6/13.
//  Copyright (c) 2013 Andreas Areschoug. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Video.h"
#import "Camera.h"
#import "GLView.h"

@interface ViewController : UIViewController

@property(nonatomic,strong) Video *video;
@property(nonatomic,strong) Camera *camera;

@property(nonatomic,strong) AVAssetWriter *assetWriter;
@property(nonatomic,strong) AVAssetWriterInput *assetWriterVideoInput;

@property(nonatomic,strong) AVAssetWriterInputPixelBufferAdaptor *adaptor;

// OpenGL ES 2.0 setup methods
- (BOOL)loadShaders:(NSString *)shadersName forProgram:(GLuint *)programPointer;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;


@end

