//
//  GLView.m
//  opengl-inputs-template
//
//  Created by Andreas Areschoug on 4/6/13.
//  Copyright (c) 2013 Andreas Areschoug. All rights reserved.
//


#import "GLView.h"
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>

@interface GLView(){


}

@property(nonatomic,assign) GLuint positionRenderTexture;

@end

@implementation GLView

#pragma mark -
#pragma mark Initialization and teardown

// Override the class method to return the OpenGL layer, as opposed to the normal CALayer
+ (Class) layerClass  {
	return [CAEAGLLayer class];
}


- (id)initWithFrame:(CGRect)frame  {
    if ((self = [super initWithFrame:frame])){

		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;

        _fboHeight = 480;
        _fboWidht = 640;

		
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @NO, kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};		
		_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		
		if (!_context || ![EAGLContext setCurrentContext:_context] || ![self createFramebuffers]) {
            return nil;
		}

    }
    return self;
}



#pragma mark -
#pragma mark OpenGL drawing

- (BOOL)createFramebuffers {	
	glEnable(GL_TEXTURE_2D);
	glDisable(GL_DEPTH_TEST);

	// Onscreen framebuffer object
	glGenFramebuffers(1, &_viewFramebuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, _viewFramebuffer);
	
	glGenRenderbuffers(1, &_viewRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, _viewRenderbuffer);
	
	[_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
	
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
	NSLog(@"Backing width: %d, height: %d", _backingWidth, _backingHeight);
	
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _viewRenderbuffer);
	
	if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)  {
		NSLog(@"Failure with framebuffer generation");
		return NO;
	}
    

	
	// Offscreen position framebuffer object
	glGenFramebuffers(1, &_positionFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _positionFramebuffer);

	glGenRenderbuffers(1, &_positionRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _positionRenderbuffer);
	
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, _fboWidht, _fboHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _positionRenderbuffer);	
    

	// Offscreen position framebuffer texture target
	glGenTextures(1, &_positionRenderTexture);
    glBindTexture(GL_TEXTURE_2D, _positionRenderTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glHint(GL_GENERATE_MIPMAP_HINT, GL_NICEST);
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	//GL_NEAREST_MIPMAP_NEAREST

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _fboWidht, _fboHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, FBO_WIDTH, FBO_HEIGHT, 0, GL_RGBA, GL_FLOAT, 0);

	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _positionRenderTexture, 0);
//	NSLog(@"GL error15: %d", glGetError());
	
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE)  {
		NSLog(@"Incomplete FBO: %d", status);
        exit(1);
    }
	
	return YES;
}

- (void)destroyFramebuffer {
	if (_viewFramebuffer) {
		glDeleteFramebuffers(1, &_viewFramebuffer);
		_viewFramebuffer = 0;
	}
	
	if (_viewRenderbuffer) {
		glDeleteRenderbuffers(1, &_viewRenderbuffer);
		_viewRenderbuffer = 0;
	}
}

- (void)setDisplayFramebuffer {
    if (_context) {

        if (!_viewFramebuffer) [self createFramebuffers];
		
        
        glBindFramebuffer(GL_FRAMEBUFFER, _viewFramebuffer);
        
        glViewport(0, 0, _backingWidth, _backingHeight);
    }
}

- (void)setPositionThresholdFramebuffer {
    if (_context) {
        if (!_positionFramebuffer) {
            [self createFramebuffers];
		}
        
        glBindFramebuffer(GL_FRAMEBUFFER, _positionFramebuffer);
        
        glViewport(0, 0, _fboWidht, _fboHeight);
    }
}

- (BOOL)presentFramebuffer {
    BOOL success = NO;
    
    if (_context) {
        glBindRenderbuffer(GL_RENDERBUFFER, _viewRenderbuffer);
        success = [_context presentRenderbuffer:GL_RENDERBUFFER];
    }
    
    return success;
}


@end
