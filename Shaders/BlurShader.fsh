
const lowp int GAUSSIAN_SAMPLES = 9;

varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];

uniform sampler2D videoFrame;
uniform lowp float testUniform;

void main()
{

 	lowp vec4 sum = vec4(0.0);
 	
     sum += texture2D(videoFrame, blurCoordinates[0]) * 0.05;
     sum += texture2D(videoFrame, blurCoordinates[1]) * 0.09;
     sum += texture2D(videoFrame, blurCoordinates[2]) * 0.12;
     sum += texture2D(videoFrame, blurCoordinates[3]) * 0.15;
     sum += texture2D(videoFrame, blurCoordinates[4]) * 0.18;
     sum += texture2D(videoFrame, blurCoordinates[5]) * 0.15;
     sum += texture2D(videoFrame, blurCoordinates[6]) * 0.12;
     sum += texture2D(videoFrame, blurCoordinates[7]) * 0.09;
     sum += texture2D(videoFrame, blurCoordinates[8]) * 0.05;

    gl_FragColor = sum;

    gl_FragColor = vec4((sum.rgb + vec3(testUniform)), sum.w);
    gl_FragColor = gl_FragColor.bgra;
}