// Rain/snow streaks go to a separate coverage mask (colortex3) so the scene behind them stays
// intact; composite lays them over the lit image as thin translucent sheets.
uniform sampler2D gtexture;
in vec2 texcoord;
in vec4 glcolor;
/* RENDERTARGETS: 3 */
layout(location = 0) out vec4 outRain;
void main() {
    float a = texture(gtexture, texcoord).a * glcolor.a;
    if (a < 0.05) discard;
    outRain = vec4(1.0, 0.0, 0.0, a);
}
