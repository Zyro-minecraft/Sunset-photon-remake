#ifndef WATER_GLSL
#define WATER_GLSL
#include "/lib/settings.glsl"
#include "/lib/noise.glsl"

// Slow, viscous waves: blood and oil do not ripple like water.
float waterHeight(vec2 p, float t) {
    float h = vnoise(p * 0.35 + vec2(t * 0.12, t * 0.05)) * 0.55;
    h += vnoise(p * 0.9 - vec2(t * 0.18, -t * 0.1)) * 0.3;
    h += vnoise(p * 2.3 + vec2(-t * 0.25, t * 0.2)) * 0.15;
    return h;
}
vec3 waterNormal(vec2 p, float t) {
    const float e = 0.08;
    float h = waterHeight(p, t);
    float dx = waterHeight(p + vec2(e, 0.0), t) - h;
    float dz = waterHeight(p + vec2(0.0, e), t) - h;
    return normalize(vec3(-dx / e * 0.35, 1.0, -dz / e * 0.35));
}
vec3 waterBaseColor() {
#if WATER_STYLE == 1
    return vec3(0.004, 0.0035, 0.0035);   // black oil
#elif WATER_STYLE == 2
    return vec3(0.045, 0.018, 0.008);     // rusty ash water
#else
    return vec3(0.07, 0.004, 0.002);      // blood
#endif
}
float waterRoughSheen(vec2 p) { return vnoise(p * 0.25); }
#endif
