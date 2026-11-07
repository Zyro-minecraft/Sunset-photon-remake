#ifndef COMMON_GLSL
#define COMMON_GLSL

vec3 srgbToLinear(vec3 c) { return pow(c, vec3(2.2)); }
vec3 linearToSrgb(vec3 c) { return pow(c, vec3(1.0 / 2.2)); }

vec2 encodeNormal(vec3 n) { return n.xy * 0.5 + 0.5; }
vec3 decodeNormal(vec2 e) {
    vec2 f = e * 2.0 - 1.0;
    return vec3(f, sqrt(max(0.0, 1.0 - dot(f, f))));
}

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

#endif
