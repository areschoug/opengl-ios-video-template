attribute vec4 position;
attribute vec4 inputTextureCoordinate;

const lowp int GAUSSIAN_SAMPLES = 9;

//uniform highp float texelWidthOffset;
//uniform highp float texelHeightOffset;
uniform highp float uniformBlur;

varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];

void main()
{
	//gl_Position = position;
	//textureCoordinate = inputTextureCoordinate.xy;
    
    gl_Position = position;
 	
 	// Calculate the positions for the blur
 	int multiplier = 0;
 	highp vec2 blurStep;
    highp vec2 singleStepOffset = vec2(0.0,uniformBlur);
     
 	for (lowp int i = 0; i < GAUSSIAN_SAMPLES; i++) {
 		multiplier = (i - ((GAUSSIAN_SAMPLES - 1) / 2));
        // Blur in x (horizontal)
        blurStep = float(multiplier) * singleStepOffset;
 		blurCoordinates[i] = inputTextureCoordinate.xy + blurStep;
 	}
}
