#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL

// ---- Shadows ----
#define SHADOW_RES 2048 // [1024 2048 4096]
const int shadowMapResolution = SHADOW_RES;
const float shadowDistance = 128.0;
const float sunPathRotation = -20.0;
#define SHADOW_SOFTNESS 1.5 // [0.5 1.0 1.5 2.0 3.0]

// ---- The frozen sun ----
#define FROZEN_SUN // Sky/light always use a dying sun stuck on the horizon
#define SUN_ELEVATION 0.06 // [0.0 0.03 0.06 0.1 0.15 0.2] radians above horizon
#define SUN_SIZE 0.08 // [0.03 0.05 0.08 0.12 0.16] angular radius (vanilla ~0.01)
#define GODRAYS_STRENGTH 1.0 // [0.0 0.5 1.0 1.5 2.0]

// ---- Atmosphere ----
#define FOG_DENSITY 1.0 // [0.25 0.5 1.0 1.5 2.0 3.0]
#define MIN_LIGHT 0.004 // [0.0 0.002 0.004 0.008 0.016]

// ---- Dread / sanity ----
#define DREAD_STRENGTH 1.0 // [0.0 0.5 1.0 1.5]
#define VIGNETTE_STRENGTH 1.0 // [0.0 0.5 1.0 1.5]
#define HEAT_HAZE 1.0 // [0.0 0.5 1.0 2.0]

// ---- Post ----
#define EXPOSURE 1.0 // [0.5 0.75 1.0 1.25 1.5 2.0]
#define BLOOM_STRENGTH 1.0 // [0.0 0.5 1.0 1.5 2.0]
#define GRAIN 1.0 // [0.0 0.5 1.0 2.0]
#define CHROMATIC 1.0 // [0.0 0.5 1.0 2.0]

// Buffer formats are read by the loader from this comment (not compiled):
/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16;
*/

#endif
