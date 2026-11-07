// Spider/enderman eyes, beacon beams: pure light.
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
uniform sampler2D gtexture;
in vec2 texcoord;
in vec4 glcolor;
/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 outAlbedo;
layout(location = 1) out vec4 outMat;
void main() {
    vec4 c = texture(gtexture, texcoord) * glcolor;
    if (c.a < 0.1) discard;
    outAlbedo = vec4(srgbToLinear(c.rgb), c.a);
    outMat = vec4(encodeMat(MAT_LAVA), 0.0, 0.0, 1.0);
}
