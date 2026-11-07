#version 330 compatibility
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/sun.glsl"

const bool colortex0MipmapEnabled = true;

uniform sampler2D colortex0;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform vec3 sunPosition;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform ivec2 eyeBrightnessSmooth;
uniform float darknessFactor;   // vanilla Darkness effect (0 if unsupported) - hook for sanity mods
uniform float blindness;

in vec2 texcoord;
layout(location = 0) out vec4 outColor;

vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void main() {
    float t = frameTimeCounter;
    float aspect = viewWidth / viewHeight;
    vec2 uv = texcoord;
    vec2 c = uv - 0.5;
    float r2 = dot(c, c);

    // Dread grows in darkness (no sky light reaching the eyes) and under the Darkness effect.
    float dark = 1.0 - clamp(float(eyeBrightnessSmooth.y) / 240.0, 0.0, 1.0);
    float dread = clamp((0.15 + 0.85 * dark + darknessFactor) * DREAD_STRENGTH, 0.0, 1.6);

    // Breathing lens - the world slowly inhales at the edges
    float breath = sin(t * 0.9) * 0.5 + 0.5;
    uv += c * r2 * 0.07 * dread * breath;

    // Heat haze boiling around the sun
    vec3 ss = sunScreen(sunPosition, gbufferModelViewInverse, gbufferModelView, gbufferProjection);
    float sd = length((uv - ss.xy) * vec2(aspect, 1.0));
    float haze = HEAT_HAZE * exp(-sd * 3.5) * ss.z;
    uv += (vec2(vnoise(uv * 45.0 + vec2(0.0, t * 3.0)), vnoise(uv * 45.0 + vec2(t * 2.5, 7.0))) - 0.5) * 0.008 * haze;

    // Chromatic aberration intensifies with dread
    float ca = CHROMATIC * (0.003 + 0.008 * dread) * r2 * 4.0;
    vec3 col;
    col.r = texture(colortex0, uv + c * ca).r;
    col.g = texture(colortex0, uv).g;
    col.b = texture(colortex0, uv - c * ca).b;

    // Bloom from the mip chain
    vec3 bloom = textureLod(colortex0, uv, 2.0).rgb * 0.30 + textureLod(colortex0, uv, 3.0).rgb * 0.25
               + textureLod(colortex0, uv, 4.0).rgb * 0.20 + textureLod(colortex0, uv, 5.0).rgb * 0.15
               + textureLod(colortex0, uv, 6.0).rgb * 0.10;
    col += max(bloom - 0.8, 0.0) * 0.25 * BLOOM_STRENGTH;

    col = aces(col * EXPOSURE);

    // Grade: everything bleeds out except red. Shadows crush to black.
    float l = luma(col);
    float redness = clamp((col.r - max(col.g, col.b)) * 3.0, 0.0, 1.0);
    col = mix(vec3(l), col, mix(0.30, 1.15, redness));
    col = pow(max(col, 0.0), vec3(1.04)); // saturation boost can push channels negative -> NaN
    col *= mix(vec3(1.0), vec3(1.05, 0.92, 0.92), 1.0 - smoothstep(0.0, 0.25, l));

    col = linearToSrgb(col);

    // Creeping darkness at the screen edges, pulsing with a heartbeat
    float ph = fract(t * 0.85);
    float hb = (exp(-pow((ph - 0.05) * 22.0, 2.0)) + 0.6 * exp(-pow((ph - 0.22) * 22.0, 2.0))) * dread * dread;
    vec2 cc = c * vec2(aspect, 1.0);
    float edge = length(cc) * 1.5;
    float tendrils = fbm(normalize(cc + 1e-5) * 3.0 + vec2(t * 0.07, -t * 0.05)) * 0.6
                   + fbm(cc * 5.0 - t * 0.05) * 0.4;
    float creep = smoothstep(1.0 - 0.35 * dread - 0.08 * hb, 1.45, edge + (tendrils - 0.5) * 0.45 * dread);
    col *= 1.0 - clamp(creep * 0.85 * VIGNETTE_STRENGTH, 0.0, 1.0);
    col = mix(col, col * vec3(1.0, 0.75, 0.75), hb * 0.25);

    // Rare flicker - something is wrong
    col *= 1.0 - 0.05 * dread * step(0.985, hash12(vec2(floor(t * 14.0), 3.1)));

    // Film grain, heavier in the dark
    float g = hash12(gl_FragCoord.xy + fract(t * 13.1) * 1000.0) - 0.5;
    col += g * GRAIN * (0.025 + 0.045 * dread) * (1.0 - 0.5 * luma(col));

    outColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
