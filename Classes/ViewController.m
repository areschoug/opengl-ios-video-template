//
//  ViewController.m
//  opengl-inputs-template
//
//  Created by Andreas Areschoug on 4/6/13.
//  Copyright (c) 2013 Andreas Areschoug. All rights reserved.
//

#import "ViewController.h"
#import "MathHelper.h"

#import <AssetsLibrary/AssetsLibrary.h>

static const GLfloat squareVertices[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
};

static const GLfloat textureVertices[] = {
    1.0f, 1.0f,
    1.0f, 0.0f,
    0.0f,  1.0f,
    0.0f,  0.0f,
};

// Shaders.
typedef enum {
    PASSTHROUGH_SHADER,
    TEST_SHADER,
    BLUR_SHADER,
    LOTR_SHADER,
} Shader;

// Uniform index.
enum {
    UNIFORM_VIDEOFRAME,
    UNIFORM_BLUR,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};


#define videoWidth 640
#define videoHeight 480

@interface ViewController()<VideoDelegate,CameraDelegate>

@property(nonatomic,assign) BOOL recordOnTouch;

@property(nonatomic,assign) BOOL recording;
@property(nonatomic,assign) int recordedFrames;
@property(nonatomic,assign) int shouldRecordFrames;

@property(nonatomic,assign) Shader currentShader;

@property(nonatomic,assign) BOOL shouldReplaceThresholdColor;
@property(nonatomic,assign) CGPoint currentTouchPoint;

@property(nonatomic,assign) GLuint passthroughProgram;
@property(nonatomic,assign) GLuint testProgram;
@property(nonatomic,assign) GLuint blurProgram;
@property(nonatomic,assign) GLuint lotrProgram;

@property(nonatomic,assign) float blur;

@property(nonatomic,assign) GLuint videoFrameTexture;

@property(nonatomic,assign) CGPoint startTouch;
@property(nonatomic,assign) CMTime time;

@property(nonatomic,strong) GLView *glView;

@end

@implementation ViewController

#define DEBUG

#pragma mark - Initialization and teardown

-(void)viewDidLoad{
    [super viewDidLoad];
    
    _currentShader = BLUR_SHADER;
    
	_glView = [[GLView alloc] initWithFrame:CGRectMake(0, 0, videoHeight, videoWidth)];
	[self.view addSubview:_glView];
    float factor = self.view.bounds.size.height/640.0;
    _glView.transform = CGAffineTransformMakeScale(factor, factor);
    _glView.center = self.view.center;
    

    [self loadShaders:@"PassthroughShader" forProgram:&_passthroughProgram];
    [self loadShaders:@"TestShader" forProgram:&_testProgram];
    [self loadShaders:@"LotrShader" forProgram:&_lotrProgram];
    [self loadShaders:@"BlurShader" forProgram:&_blurProgram];
    
    _recordOnTouch = YES;
    
    if (YES) {
        _camera = [[Camera alloc] init];
        _camera.delegate = self;
        [_camera startCamera];
    } else {
        _video = [[Video alloc] init];
        _video.delegate = self;
        [_video startReading:@"video.mov"];
    }
}

#pragma mark - OpenGL ES 2.0 rendering methods

- (void)drawFrame {    
    
	// Use shader program.
	switch (_currentShader) {
		case PASSTHROUGH_SHADER:
			[_glView setDisplayFramebuffer];
			glUseProgram(_passthroughProgram);
            break;
        case TEST_SHADER:
			[_glView setDisplayFramebuffer];
			glUseProgram(_testProgram);
            break;
        case BLUR_SHADER:
			[_glView setDisplayFramebuffer];
			glUseProgram(_blurProgram);
            break;
        case LOTR_SHADER:
			[_glView setDisplayFramebuffer];
			glUseProgram(_lotrProgram);
            break;
	}

	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, _videoFrameTexture);
	
	// Update uniform values
	glUniform1i(uniforms[UNIFORM_VIDEOFRAME], 0);
    glUniform1f(uniforms[UNIFORM_BLUR], _blur);

	// Update attribute values.
	glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
	glEnableVertexAttribArray(ATTRIB_VERTEX);
	glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureVertices);
	glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
    
    
	
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
    if (_recording) {
        
        CVPixelBufferRef pixelBuffer = nil;
        
        CVReturn status = CVPixelBufferPoolCreatePixelBuffer (nil, _adaptor.pixelBufferPool, &pixelBuffer);
        
        if (pixelBuffer == nil || status != kCVReturnSuccess) {
            NSLog(@"REC ERROR: pixelBuffer:%@ status:%i",_adaptor.pixelBufferPool,status);
            return;
        } else {
            glPixelStorei(GL_PACK_ALIGNMENT,1) ;
            CVPixelBufferLockBaseAddress(pixelBuffer, 0);
            GLubyte *pixelBufferData = (GLubyte *)CVPixelBufferGetBaseAddress(pixelBuffer);
            glReadPixels(0, 0, videoHeight, videoWidth, GL_BGRA, GL_UNSIGNED_BYTE, pixelBufferData);
        }
        
        CMTime currentTime = _time;
        
        if(![_adaptor appendPixelBuffer:pixelBuffer withPresentationTime:currentTime]) {
            NSLog(@"REC ERROR: Failed to append pixel buffer : %lld", currentTime.value);
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
        CVPixelBufferRelease(pixelBuffer);

        _time.value += 1;
        
        if (_recordedFrames > _shouldRecordFrames) [self performSelectorInBackground:@selector(stopRecording) withObject:nil];
        
        _recordedFrames++;        
    }
    
    
    [_glView presentFramebuffer];
}

#pragma mark - OpenGL ES 2.0 setup methods

- (BOOL)loadShaders:(NSString *)shadersName forProgram:(GLuint *)programPointer {
    
    GLuint vertexShader;
    GLuint fragShader;

    // Create shader program.
    *programPointer = glCreateProgram();
    
    // Create and compile vertex shader.
    NSString *vertShaderPathname = [[NSBundle mainBundle] pathForResource:shadersName ofType:@"vsh"];
    if (![self compileShader:&vertexShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    NSString *fragShaderPathname = [[NSBundle mainBundle] pathForResource:shadersName ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(*programPointer, vertexShader);
    
    // Attach fragment shader to program.
    glAttachShader(*programPointer, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(*programPointer, ATTRIB_VERTEX, "position");
    glBindAttribLocation(*programPointer, ATTRIB_TEXTUREPOSITON, "inputTextureCoordinate");

    
    // Link program.
    if (![self linkProgram:*programPointer]) {
        NSLog(@"Failed to link program: %d", *programPointer);
        
        if (vertexShader) {
            glDeleteShader(vertexShader);
            vertexShader = 0;
        }
        
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        
        if (*programPointer) {
            glDeleteProgram(*programPointer);
            *programPointer = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_VIDEOFRAME] = glGetUniformLocation(*programPointer, "videoFrame");
    uniforms[UNIFORM_BLUR] = glGetUniformLocation(*programPointer, "uniformBlur");
    // Release vertex and fragment shaders.
    if (vertexShader) {
        glDeleteShader(vertexShader);
	}
    
    if (fragShader) {
        glDeleteShader(fragShader);		
	}
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return YES;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, nil);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0){
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)program{
    GLint status;
    
    glLinkProgram(program);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(program, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == 0) return NO;
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)program {
    GLint logLength;
    GLint status;
    
    glValidateProgram(program);
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(program, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(program, GL_VALIDATE_STATUS, &status);
    if (status == 0) return NO;
    
    return YES;
}


#pragma mark - Image processing


-(void)processFrameBuffer:(CVImageBufferRef) frame{
	CVPixelBufferLockBaseAddress(frame, 0);
	int bufferHeight = CVPixelBufferGetHeight(frame);
	int bufferWidth = CVPixelBufferGetWidth(frame);
	
	// Create a new texture from the camera frame data, display that using the shaders
	glGenTextures(1, &_videoFrameTexture);
	glBindTexture(GL_TEXTURE_2D, _videoFrameTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	// This is necessary for non-power-of-two textures
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
	// Using BGRA extension to pull in video frame data directly
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferWidth, bufferHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(frame));
    
	[self drawFrame];
	
	glDeleteTextures(1, &_videoFrameTexture);
    
	CVPixelBufferUnlockBaseAddress(frame, 0);
}


#pragma mark - VideoDelegate methods

- (void)processVideoFrame:(CVImageBufferRef)cameraFrame {
    [self processFrameBuffer:cameraFrame];
}

-(void)didStopReading:(AVAssetReaderStatus)status{
    [_video startReading:@"video.mov"];
}

#pragma mark - CameraDelegate methods
-(void)processCameraFrame:(CVImageBufferRef)cameraFrame{
    [self processFrameBuffer:cameraFrame];
}


#pragma mark - Touches

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if (_recordOnTouch) {
        [self startRecordingNumberOfFrames:-1];
    }
    
    _startTouch = [[touches anyObject] locationInView:self.view];
    
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{

    float f = _startTouch.x - [[touches anyObject] locationInView:self.view].x;
    
    _blur = clamp(0.0, 0.01, map(f, 0, 150, 0.0, 0.01));
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if (_recording && _recordOnTouch) {
        [self performSelectorInBackground:@selector(stopRecording) withObject:nil];
    }
}

#pragma mark - Record

-(void)startRecordingNumberOfFrames:(int)numberOfFramesToRecord{
    _recording = YES;
    
    if (numberOfFramesToRecord == -1) numberOfFramesToRecord = MAXFLOAT;
    _shouldRecordFrames = numberOfFramesToRecord;
    _recordedFrames = 0;
    _time = CMTimeMake(0, 30);

    CGSize size = CGSizeMake(videoHeight, videoWidth);
    
    NSString *urlString = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie2.m4v"];
    
    NSError *error = nil;
    
    unlink([urlString UTF8String]);
    
    _assetWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:urlString]
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(_assetWriter);
    if(error) NSLog(@"START REC ERROR: %@", [error localizedDescription]);
    
    NSDictionary *videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                    AVVideoWidthKey:@(size.width),
                                    AVVideoHeightKey:@(size.height)};
    
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    _assetWriterVideoInput.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(-M_PI/2), 1, -1);

    
    NSDictionary *pixelBufferAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    
    _adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:pixelBufferAttributes];
    
    NSParameterAssert(_assetWriterVideoInput);
    NSParameterAssert([_assetWriter canAddInput:_assetWriterVideoInput]);
    
    if ([_assetWriter canAddInput:_assetWriterVideoInput]) [_assetWriter addInput:_assetWriterVideoInput];


    [_assetWriter startWriting];
    [_assetWriter startSessionAtSourceTime:_time];

}

-(void)stopRecording {
    _recording = NO;
    
    [_assetWriterVideoInput markAsFinished];    
    [_assetWriter finishWriting];
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    NSString *localVid = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie2.m4v"];
    NSURL* fileURL = [NSURL fileURLWithPath:localVid];

    [library writeVideoAtPathToSavedPhotosAlbum:fileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        if (!error) {
            NSLog(@"Video Saved - %@",assetURL);
        } else {
            NSLog(@"%@: Error saving context: %@", [self class], [error localizedDescription]);
        }
    }];
}




@end
