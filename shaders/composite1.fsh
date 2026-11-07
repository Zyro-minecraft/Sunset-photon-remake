#version 330 compatibility
#include "/lib/settings.glsl"
#include "/lib/sun.glsl"

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform vec3 sunPosition;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec3 col = texture(colortex0, texcoord).rgb;
    vec3 ss = sunScreen(sunPosition, gbufferModelViewInverse, gbufferModelView, gbufferProjection);
    if (ss.z > 0.5 && GODRAYS_STRENGTH > 0.0) {
        const int N = 40;
        vec2 delta = (ss.xy - texcoord) / float(N);
        float dither = hash12(gl_FragCoord.xy + fract(frameTimeCounter) * 97.0);
        float sum = 0.0, w = 1.0;
        for (int i = 0; i < N; i++) {
            vec2 uv = texcoord + delta * (float(i) + dither);
            if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) break;
            sum += step(1.0, texture(depthtex0, uv).r) * w;
            w *= 0.97;
        }
        float aspect = viewWidth / viewHeight;
        float distToSun = length((texcoord - ss.xy) * vec2(aspect, 1.0));
        float onScreen = 1.0 - smoothstep(0.6, 1.4, length((ss.xy - 0.5) * vec2(aspect, 1.0)));
        float rays = sum / float(N) * exp(-distToSun * 1.6) * onScreen;
        col += vec3(1.0, 0.16, 0.03) * rays * 0.7 * GODRAYS_STRENGTH;
    }
    outColor = vec4(col, 1.0);
}
