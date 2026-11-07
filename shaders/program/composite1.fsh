// Screen-space god rays from the frozen sun (overworld only).
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/sun.glsl"
#include "/lib/water.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform vec3 sunPosition;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform int isEyeInWater;

in vec2 texcoord;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

vec3 viewPos(vec2 uv, float depth) {
    vec4 v = gbufferProjectionInverse * (vec4(uv, depth, 1.0) * 2.0 - 1.0);
    return v.xyz / v.w;
}

// Screen-space reflections on the water: shores, trees and ruins mirrored in the blood sea.
vec3 waterSSR(vec3 col) {
    if (decodeMat(texture(colortex2, texcoord).r) != MAT_WATER || isEyeInWater == 1) return col;
    float depth = texture(depthtex0, texcoord).r;
    vec3 vp = viewPos(texcoord, depth);
    vec3 n = decodeNormal(texture(colortex1, texcoord).xy);
    vec3 nW = mat3(gbufferModelViewInverse) * n;
    if (nW.y < 0.5) return col;
    vec3 wp = (gbufferModelViewInverse * vec4(vp, 1.0)).xyz + cameraPosition;
    vec3 wn = mat3(gbufferModelView) * waterNormal(wp.xz, frameTimeCounter);
    vec3 v = normalize(vp);
    vec3 r = reflect(v, wn);
    if (r.z > 0.0) return col; // reflecting back toward the camera: nothing on screen to hit
    float F = 0.03 + 0.97 * pow(1.0 - max(dot(-v, wn), 0.0), 5.0);

    const int STEPS = 20;
    float stepLen = 0.6 + length(vp) * 0.04;
    vec3 p = vp + r * stepLen * hash12(gl_FragCoord.xy);
    for (int i = 0; i < STEPS; i++) {
        p += r * stepLen;
        stepLen *= 1.15;
        vec4 clip = gbufferProjection * vec4(p, 1.0);
        vec2 uv = clip.xy / clip.w * 0.5 + 0.5;
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) break;
        float sd = texture(depthtex0, uv).r;
        if (sd >= 1.0) continue; // sky: already reflected analytically
        if (decodeMat(texture(colortex2, uv).r) == MAT_WATER) continue; // never the sea itself
        float sz = viewPos(uv, sd).z;
        float diff = sz - p.z;
        if (diff > 0.0 && diff < stepLen * 2.0) {
            vec3 hit = texture(colortex0, uv).rgb;
            vec2 e = abs(uv - 0.5) * 2.0;
            float fade = (1.0 - smoothstep(0.75, 1.0, max(e.x, e.y))) * (1.0 - float(i) / float(STEPS));
            return mix(col, hit * 0.8, clamp(F * 1.8, 0.0, 1.0) * fade);
        }
    }
    return col;
}

void main() {
    vec3 col = texture(colortex0, texcoord).rgb;
    col = waterSSR(col);
#ifdef DIM_OVERWORLD
    vec3 ss = sunScreen(sunPosition, gbufferModelViewInverse, gbufferModelView, gbufferProjection);
    float strength = GODRAYS_STRENGTH * (1.0 - 0.85 * rainStrength) * (isEyeInWater == 0 ? 1.0 : 0.0);
    if (ss.z > 0.5 && strength > 0.0) {
        vec2 delta = (ss.xy - texcoord) / float(GODRAY_SAMPLES);
        float dither = hash12(gl_FragCoord.xy + fract(frameTimeCounter) * 97.0);
        float sum = 0.0, w = 1.0;
        for (int i = 0; i < GODRAY_SAMPLES; i++) {
            vec2 uv = texcoord + delta * (float(i) + dither);
            if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) break;
            sum += step(1.0, texture(depthtex0, uv).r) * w;
            w *= 1.0 - 1.2 / float(GODRAY_SAMPLES);
        }
        float aspect = viewWidth / viewHeight;
        float distToSun = length((texcoord - ss.xy) * vec2(aspect, 1.0));
        float onScreen = 1.0 - smoothstep(0.6, 1.4, length((ss.xy - 0.5) * vec2(aspect, 1.0)));
        float rays = sum / float(GODRAY_SAMPLES) * exp(-distToSun * 1.6) * onScreen;
        col += vec3(1.0, 0.16, 0.03) * rays * 0.7 * strength;
    }
#endif
    outColor = vec4(col, 1.0);
}
