// Tonemap, grading and the dread system.
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/sun.glsl"

const bool colortex0MipmapEnabled = true;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform vec3 sunPosition;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform ivec2 eyeBrightnessSmooth;
uniform float darknessFactor;
uniform int isEyeInWater;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

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

    // Dread grows in darkness. Sky light, torches around you and the torch in your hand count as light.
    float skyEye = float(eyeBrightnessSmooth.y) / 240.0;
    float blockEye = float(eyeBrightnessSmooth.x) / 240.0;
    float heldEye = float(max(heldBlockLightValue, heldBlockLightValue2)) / 15.0;
    float lightEye = max(max(skyEye, blockEye * 0.85), heldEye * 0.8);
#if defined DIM_NETHER || defined DIM_END
    lightEye = max(lightEye, 0.4); // no sky light there: dread comes from the place itself
#endif
    float dark = 1.0 - smoothstep(0.08, 0.65, lightEye);
    float dread = clamp((dark + darknessFactor) * DREAD_STRENGTH, 0.0, 1.6);

    // Breathing lens - only in deep darkness, and only a faint inhale at the very edges
    float breath = sin(t * 0.9) * 0.5 + 0.5;
    uv += c * r2 * 0.02 * smoothstep(0.5, 1.0, dread) * breath;

    // Underwater: thick, slow wobble
    if (isEyeInWater == 1) uv += vec2(sin(uv.y * 18.0 + t * 1.5), cos(uv.x * 14.0 + t * 1.2)) * 0.003;

#ifdef DIM_OVERWORLD
    // Heat haze: a faint shimmer of the sky right around the sun disk. Never on blocks,
    // so the world itself does not swim.
    vec3 ss = sunScreen(sunPosition, gbufferModelViewInverse, gbufferModelView, gbufferProjection);
    float sd = length((uv - ss.xy) * vec2(aspect, 1.0));
    float skyHere = step(1.0, texture(depthtex0, texcoord).r);
    float haze = HEAT_HAZE * exp(-sd * 9.0) * ss.z * skyHere;
    vec2 hz = (vec2(vnoise(uv * 45.0 + vec2(0.0, t * 3.0)), vnoise(uv * 45.0 + vec2(t * 2.5, 7.0))) - 0.5) * 0.003 * haze;
    if (texture(depthtex0, uv + hz).r >= 1.0) uv += hz; // don't pull block pixels into the sky
#endif

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
    col += max(bloom - 1.0, 0.0) * 0.15 * BLOOM_STRENGTH; // gentle: must not smear blocks near the sun

    col = aces(col * EXPOSURE);

    // Grade: colour bleeds out of the world except red (and the End's violet). Shadows lean crimson.
    float l = luma(col);
    float redness = clamp((col.r - max(col.g, col.b)) * 3.0, 0.0, 1.0);
#ifdef DIM_END
    redness = max(redness, clamp((min(col.r, col.b) - col.g) * 4.0, 0.0, 1.0));
#endif
    col = mix(vec3(l), col, mix(0.30, 1.15, redness));
    col = pow(max(col, 0.0), vec3(1.04)); // saturation boost can push channels negative -> NaN
    col *= mix(vec3(1.0), vec3(1.05, 0.92, 0.92), 1.0 - smoothstep(0.0, 0.25, l));

    col = linearToSrgb(col);

    // In darkness the void creeps in from every edge; in light only thin ragged side strips remain.
    float ph = fract(t * 0.85);
    float hb = (exp(-pow((ph - 0.05) * 22.0, 2.0)) + 0.6 * exp(-pow((ph - 0.22) * 22.0, 2.0))) * dread * dread;
    vec2 cc = c * vec2(aspect, 1.0);
    float edge = length(cc) * 1.5;
    float tendrils = fbm(normalize(cc + 1e-5) * 3.0 + vec2(t * 0.07, -t * 0.05)) * 0.6
                   + fbm(cc * 5.0 - t * 0.05) * 0.4;
    // Never reaches the middle of the screen: at most the outer edge band in the deepest dark.
    float creep = smoothstep(1.2 - 0.30 * dread - 0.05 * hb, 1.6 - 0.10 * dread,
                             edge + (tendrils - 0.5) * 0.30 * (0.3 + dread));
    float sideX = abs(c.x) + (tendrils - 0.5) * 0.025;
    float sides = smoothstep(0.46, 0.5, sideX) * 0.6;
    float shade = max(creep * 0.85, sides);
    col *= 1.0 - clamp(shade * VIGNETTE_STRENGTH, 0.0, 1.0);
    col = mix(col, col * vec3(1.0, 0.75, 0.75), hb * 0.25);

    // Rare flicker - something is wrong
    col *= 1.0 - 0.05 * dread * step(0.985, hash12(vec2(floor(t * 14.0), 3.1)));

    // Film grain, heavier in the dark
    float g = hash12(gl_FragCoord.xy + fract(t * 13.1) * 1000.0) - 0.5;
    col += g * GRAIN * (0.025 + 0.045 * dread) * (1.0 - 0.5 * luma(col));

    outColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
