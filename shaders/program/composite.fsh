// Deferred lighting: sun/ambient/torch/held light, SSAO, water, emissives, fog, ash.
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/noise.glsl"
#include "/lib/dims.glsl"
#include "/lib/water.glsl"
#include "/lib/ash.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex1;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;
uniform float far;
uniform float frameTimeCounter;
uniform int isEyeInWater;
uniform float blindness;
uniform float darknessFactor;
uniform float nightVision;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform ivec2 eyeBrightnessSmooth;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

vec3 viewPos(vec2 uv, float depth) {
    vec4 v = gbufferProjectionInverse * (vec4(uv, depth, 1.0) * 2.0 - 1.0);
    return v.xyz / v.w;
}

float shadowFactor(vec3 viewP, vec3 nView, float lift) {
    vec3 feet = (gbufferModelViewInverse * vec4(viewP, 1.0)).xyz;
    feet += mat3(gbufferModelViewInverse) * nView * (0.04 + lift);
    vec4 sp = shadowProjection * (shadowModelView * vec4(feet, 1.0));
    sp.xy /= (0.9 * length(sp.xy) + 0.1);
    vec3 coord = sp.xyz * 0.5 + 0.5;
    if (any(lessThan(coord.xy, vec2(0.0))) || any(greaterThan(coord.xy, vec2(1.0)))) return 1.0;
    float texel = SHADOW_SOFTNESS / float(shadowMapResolution);
    float rot = hash12(gl_FragCoord.xy) * 6.2832;
    mat2 R = mat2(cos(rot), sin(rot), -sin(rot), cos(rot));
    float s = 0.0;
    for (int i = 0; i < 8; i++) { // rotated Vogel disk: soft edges without banding
        float r = sqrt((float(i) + 0.5) / 8.0);
        float a = float(i) * 2.39996;
        vec2 o = R * vec2(cos(a), sin(a)) * r * 1.6;
        s += step(coord.z - 0.0005, texture(shadowtex1, coord.xy + o * texel).r);
    }
    return s / 8.0;
}

float ssao(vec3 vp, vec3 n) {
#ifdef SSAO
    const int N = 8;
    const float R = 0.55;
    vec3 t = normalize(cross(n, abs(n.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
    vec3 b = cross(n, t);
    float rot = hash12(gl_FragCoord.xy + 13.7) * 6.2832;
    float occ = 0.0;
    for (int i = 0; i < N; i++) {
        float a = rot + float(i) * 2.39996;
        float z = (float(i) + 0.5) / float(N);
        float rr = sqrt(1.0 - z * z);
        float scale = mix(0.15, 1.0, (float(i) + 1.0) / float(N));
        vec3 sp = vp + (t * cos(a) * rr + b * sin(a) * rr + n * z) * R * scale;
        vec4 clip = gbufferProjection * vec4(sp, 1.0);
        vec2 suv = clip.xy / clip.w * 0.5 + 0.5;
        if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) continue;
        float sz = viewPos(suv, texture(depthtex0, suv).r).z;
        float range = smoothstep(0.0, 1.0, R / max(abs(vp.z - sz), 1e-3));
        occ += step(sp.z + 0.03, sz) * range;
    }
    return clamp(1.0 - occ / float(N) * 0.9 * AO_STRENGTH, 0.0, 1.0);
#else
    return 1.0;
#endif
}

void main() {
    float t = frameTimeCounter;
    vec4 albedoA = texture(colortex0, texcoord);
    vec4 data = texture(colortex1, texcoord);
    vec4 matTex = texture(colortex2, texcoord);
    int mat = decodeMat(matTex.r);
    float depth = texture(depthtex0, texcoord).r;
    bool isHand = mat == MAT_HAND;

    vec3 vp = viewPos(texcoord, depth);
    vec3 dirView = normalize(vp);
    vec3 dirWorld = normalize(mat3(gbufferModelViewInverse) * dirView);
    vec3 sunW = getSunDirWorld(normalize(mat3(gbufferModelViewInverse) * normalize(sunPosition)));
    float dist = isHand ? 0.4 : length(vp);
    vec3 color;

    if (mat == MAT_WEATHER) {
        // Rain streaks: lit air. Brighter toward the sun, ash-grey elsewhere.
        color = dimFog(dirWorld, sunW) * 1.8 + albedoA.rgb * 0.015;
    } else if (depth >= 1.0) {
        color = dimSky(dirWorld, sunW, t);
    } else {
        vec3 albedo = albedoA.rgb;
        if (mat == MAT_PARTICLE) albedo = mix(albedo, vec3(luma(albedo)), 0.85);
        vec3 n = decodeNormal(data.xy);
        float blockL = data.z, skyL = data.w;

        // Light carried in the player's hands
#ifdef HELD_LIGHT
        float held = float(max(heldBlockLightValue, heldBlockLightValue2));
        float heldL = clamp((held - dist * 1.1) / 15.0, 0.0, 1.0);
        blockL = max(blockL, heldL);
#endif
        float ao = isHand ? 1.0 : ssao(vp, n);

        // --- sun (overworld only) ---
        vec3 direct = vec3(0.0);
        vec3 ambient;
#if defined DIM_OVERWORLD
        vec3 sunV = mat3(gbufferModelView) * sunW;
        float ndl = dot(n, sunV);
        bool foliage = mat == MAT_PLANT || mat == MAT_LEAVES;
        if (foliage) ndl = 0.35 + 0.65 * abs(ndl);     // thin foliage: lit through, glows backlit
        if (mat == MAT_PARTICLE) ndl = 0.6;
        ndl = max(ndl, 0.0);
        // If the game clock is not frozen the shadow map comes from a different sun: fade it out.
        float shadowValid = smoothstep(0.96, 0.995, dot(normalize(shadowLightPosition), sunV));
        float sh = 1.0;
        if (ndl > 0.0 && !isHand) sh = mix(1.0, shadowFactor(vp, n, foliage ? 0.1 : 0.0), shadowValid);
        if (isHand) sh = skyL;
        direct = sunLightColor() * ndl * sh * skyL * (1.0 - 0.8 * rainStrength);
        if (foliage) direct *= mix(vec3(1.0), vec3(1.3, 0.8, 0.7), 0.5); // red translucency
        // Under tree crowns sky light drops only by 1-2 levels in vanilla; exaggerate that so a
        // forest feels starved of light while an open field is unchanged (skyL = 1).
        float canopy = pow(skyL, 2.0 + 10.0 * CANOPY_DARKNESS);
        ambient = (skyBase(normalize(vec3(sunW.x, 0.25, sunW.z)), sunW) * 0.25
                + vec3(0.09, 0.05, 0.05) * (1.0 + 0.5 * rainStrength)) * canopy;
#elif defined DIM_NETHER
        ambient = srgbToLinear(fogColor) * 2.2 + vec3(0.07, 0.025, 0.015);
#else
        ambient = vec3(0.05, 0.035, 0.085);
        vec3 eV = mat3(gbufferModelView) * normalize(END_ECLIPSE_DIR);
        direct = vec3(0.25, 0.15, 0.5) * max(dot(n, eV), 0.0) * 0.4; // corona rim light
#endif
        float flicker = 0.92 + 0.08 * vnoise(vec2(t * 9.0, 0.0));
#ifdef DIM_NETHER
        vec3 blockLight = vec3(1.0, 0.42, 0.14) * pow(blockL, 2.6) * 2.0 * flicker; // lava seas light everything
#else
        vec3 blockLight = vec3(1.0, 0.48, 0.18) * pow(blockL, 4.0) * 2.4 * flicker;
#endif
        vec3 minLight = MIN_LIGHT * vec3(1.0, 0.82, 0.82) * (1.0 - 0.75 * skyL) + nightVision * 0.25;

        color = albedo * (direct + (ambient + minLight) * ao + blockLight * mix(1.0, ao, 0.5));

        // --- emissive surfaces ---
        if (mat == MAT_LAVA) color += albedo * 3.5 * EMISSIVE_STRENGTH;
        if (mat == MAT_GLOW) {
            // only hot, saturated-bright texels glow (flame, lamp core), not pale stone around them
            vec3 sr = linearToSrgb(albedo);
            float sat = maxc(sr) - min(sr.r, min(sr.g, sr.b));
            float m = smoothstep(0.55, 0.85, maxc(sr)) * (0.35 + 0.65 * smoothstep(0.1, 0.45, sat));
            color += albedo * m * 4.0 * EMISSIVE_STRENGTH;
        }

        // --- blood / oil water ---
        if (mat == MAT_WATER && isEyeInWater != 1) {
            vec3 nW = mat3(gbufferModelViewInverse) * n;
            vec3 wp = (gbufferModelViewInverse * vec4(vp, 1.0)).xyz + cameraPosition;
            vec3 wn = nW.y > 0.5 ? waterNormal(wp.xz, t) : nW;
            vec3 r = reflect(dirWorld, wn);
            r.y = abs(r.y);
            float F = 0.03 + 0.97 * pow(1.0 - max(dot(-dirWorld, wn), 0.0), 5.0);
            vec3 refl = dimSky(r, sunW, t) * mix(0.15, 1.0, skyL);
#if WATER_STYLE == 1
            // oil: thin-film sheen
            float film = waterRoughSheen(wp.xz + t * 0.05);
            refl *= 0.8 + 0.4 * (0.5 + 0.5 * cos(6.2832 * (film * 2.0 + vec3(0.0, 0.33, 0.67))));
#endif
            vec3 body = waterBaseColor() * (ambient + direct * 0.4 + blockLight + minLight);
            color = mix(body, refl, F);
        }

        // --- air between eye and surface ---
        if (!isHand) {
            float fog = dimFogAmount(dist, far);
            color = mix(color, dimFog(dirWorld, sunW), fog);
        }
    }

    // --- medium the eye is in ---
    float d2 = (depth >= 1.0 && mat != MAT_WEATHER) ? 1e3 : dist;
    if (isEyeInWater == 1) {
        vec3 deep = waterBaseColor() * 1.5 + vec3(0.01, 0.003, 0.003);
        color = mix(color * vec3(1.0, 0.6, 0.55), deep, 1.0 - exp(-d2 * 0.12));
    } else if (isEyeInWater == 2) {
        color = mix(color, vec3(1.2, 0.25, 0.03), 1.0 - exp(-d2 * 0.9));
    } else if (isEyeInWater == 3) {
        color = mix(color, vec3(0.35, 0.32, 0.33), 1.0 - exp(-d2 * 0.7));
    }
    // blindness / Darkness effect: the world drowns in black
    float blind = max(blindness, darknessFactor * 0.6);
    color *= 1.0 - blind * smoothstep(2.0, 8.0, d2);

    // rain / snow sheets over the lit scene
    float rainMask = texture(colortex3, texcoord).r;
    if (rainMask > 0.0) {
        vec3 rainCol = dimFog(dirWorld, sunW) * 1.7 + vec3(0.012, 0.01, 0.01);
        color = mix(color, rainCol, rainMask * 0.35);
    }

#ifdef ASH_PARTICLES
#ifndef DIM_END
    if (isEyeInWater == 0) {
#ifdef DIM_NETHER
        float ashAmount = 1.0;
#else
        float ashAmount = smoothstep(0.1, 0.6, float(eyeBrightnessSmooth.y) / 240.0); // none indoors / in caves
#endif
        vec4 ash = ashParticles(cameraPosition, dirWorld, min(d2, 30.0), t, ASH_DENSITY) * ashAmount;
#ifdef DIM_NETHER
        vec3 ashCol = srgbToLinear(fogColor) * 0.25;
#else
        vec3 ashCol = vec3(0.025, 0.02, 0.02) + sunLightColor() * 0.03 * pow(max(dot(dirWorld, sunW), 0.0), 4.0);
#endif
        color = mix(color, ashCol, ash.a) + ash.rgb * (1.0 - blind);
    }
#endif
#endif

    outColor = vec4(color, 1.0);
}
