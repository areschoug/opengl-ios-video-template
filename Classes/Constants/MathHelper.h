//
//  MathHelper.h
//  redbull-ss-ios
//
//  Created by Simon Andersson on 11/27/12.
//  Copyright (c) 2012 Monterosa. All rights reserved.
//

#ifndef redbull_ss_ios_MathHelper_h
#define redbull_ss_ios_MathHelper_h

// Map
#define map(x, in_min, in_max, out_min, out_max) ((x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min)

// Clamp
#define clamp(min, max, value) (MIN(max, MAX(min, value)))

// Lerp
#define lerpf(a, b, t) (a + (b - a) * t)

// Float equals
#define fequal(a, b) (fabs((a) - (b)) < FLT_EPSILON)

// Random between numbers
#define rrandom(smallNumber, bigNumber) ((((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * (bigNumber - smallNumber)) + smallNumber)


#endif