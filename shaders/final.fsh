#version 330 compatibility
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

uniform sampler2D colortex0;
in vec2 texcoord;
layout(location = 0) out vec4 outColor;

// ACES (Narkowicz fit)
vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void main() {
    vec3 c = texture(colortex0, texcoord).rgb * EXPOSURE;
    c = aces(c);
    c = pow(c, vec3(TONEMAP_CONTRAST));
    outColor = vec4(linearToSrgb(c), 1.0);
}
