#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL

#define SHADOW_RES 2048 // [1024 2048 4096]
const int shadowMapResolution = SHADOW_RES;
const float shadowDistance = 128.0;
const float sunPathRotation = -20.0;

#define SHADOW_SOFTNESS 1.5 // [0.5 1.0 1.5 2.0 3.0]
#define SUNSET_STRENGTH 1.0 // [0.0 0.5 1.0 1.5 2.0]
#define EXPOSURE 1.0 // [0.5 0.75 1.0 1.25 1.5 2.0]
#define TONEMAP_CONTRAST 1.1 // [0.8 0.9 1.0 1.1 1.2 1.4]

const int colortex0Format = RGBA16F;
const int colortex1Format = RGB16;

#endif
