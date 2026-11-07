#include "/lib/settings.glsl"
#include "/lib/waving.glsl"
in vec4 mc_Entity;
in vec2 mc_midTexCoord;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
out vec2 texcoord;
out vec4 glcolor;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
    vec4 viewP = gl_ModelViewMatrix * gl_Vertex;
#ifdef WAVING_PLANTS
    int id = int(mc_Entity.x + 0.5);
    if (id >= 10010 && id <= 10012) {
        vec3 feet = (shadowModelViewInverse * viewP).xyz;
        feet += waveOffset(feet + cameraPosition, id, texcoord.y < mc_midTexCoord.y, frameTimeCounter, rainStrength);
        viewP = shadowModelView * vec4(feet, 1.0);
    }
#endif
    vec4 pos = gl_ProjectionMatrix * viewP;
    pos.xy /= (0.9 * length(pos.xy) + 0.1); // more resolution near the player
    gl_Position = pos;
}
