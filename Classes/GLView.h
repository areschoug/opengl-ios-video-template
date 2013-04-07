//
//  GLView.h
//  opengl-inputs-template
//
//  Created by Andreas Areschoug on 4/6/13.
//  Copyright (c) 2013 Andreas Areschoug. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface GLView : UIView  {
	/* The pixel dimensions of the backbuffer */
	GLint _backingWidth;
    GLint _backingHeight;
	
	EAGLContext *_context;
	
	/* OpenGL names for the renderbuffer and framebuffers used to render to this view */
	GLuint _viewRenderbuffer;
	GLuint _viewFramebuffer;
    
	GLuint _positionRenderTexture;
    
	GLuint _positionRenderbuffer;
    GLuint _positionFramebuffer;
}

// OpenGL drawing
- (BOOL)createFramebuffers;
- (void)destroyFramebuffer;
- (void)setDisplayFramebuffer;
- (void)setPositionThresholdFramebuffer;
- (BOOL)presentFramebuffer;

@property(nonatomic,assign) int fboWidht;
@property(nonatomic,assign) int fboHeight;

@end
