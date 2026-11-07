#ifndef WAVING_GLSL
#define WAVING_GLSL
#include "/lib/settings.glsl"
// Hot, gusty wind. wp = world position, isTop = vertex is at the top of its texture.
vec3 waveOffset(vec3 wp, int id, bool isTop, float t, float rain) {
    float str = WAVE_STRENGTH * (1.0 + 1.2 * rain);
    float gust = 0.6 + 0.4 * sin(t * 0.35 + wp.x * 0.04 + wp.z * 0.03);
    vec2 w = vec2(sin(t * 1.9 + wp.x * 0.7 + wp.z * 0.4), cos(t * 1.5 + wp.z * 0.8 - wp.x * 0.3)) * gust;
    w += vec2(sin(t * 6.0 + wp.x * 3.0), cos(t * 5.0 + wp.z * 3.0)) * 0.15; // nervous tremble
    if (id == 10010) return isTop ? vec3(w.x, 0.0, w.y) * 0.07 * str : vec3(0.0);
    if (id == 10011) return vec3(w.x, 0.0, w.y) * (isTop ? 0.13 : 0.07) * str;
    if (id == 10012) return vec3(w.x, w.y * 0.4, w.y) * 0.03 * str;
    return vec3(0.0);
}
#endif
