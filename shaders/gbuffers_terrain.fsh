#version 330 compatibility
#include "/lib/common.glsl"

uniform sampler2D gtexture;
uniform float alphaTestRef;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;

/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 outAlbedo;
layout(location = 1) out vec4 outData;

void main() {
    vec4 c = texture(gtexture, texcoord) * glcolor;
    if (c.a < alphaTestRef) discard;
    outAlbedo = vec4(srgbToLinear(c.rgb), c.a);
    // xy: view-space normal, z: block light, w: sky light
    outData = vec4(encodeNormal(normalize(normal)), lmcoord.x, lmcoord.y);
}
