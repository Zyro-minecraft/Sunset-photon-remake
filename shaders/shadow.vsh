#version 330 compatibility
out vec2 texcoord;
out vec4 glcolor;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
    vec4 pos = ftransform();
    float d = length(pos.xy);
    pos.xy /= (0.9 * d + 0.1);   // shadow distortion: more resolution near the player
    gl_Position = pos;
}
