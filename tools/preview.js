// Renders a preview of the sky + grading using the pack's real lib/*.glsl in headless Chromium (WebGL2).
// Usage: node tools/preview.js out.png [dread 0..1] [yawDegrees]
const fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const lib = f => fs.readFileSync(path.join(__dirname, '../shaders/lib', f), 'utf8');
const [out = 'preview.png', dread = '0.6', yaw = '0'] = process.argv.slice(2);

const frag = `#version 300 es
precision highp float;
#define RGBA16F 1
#define RGB16 2
${lib('settings.glsl')}
${lib('common.glsl')}
${lib('noise.glsl')}
${lib('sky.glsl').replace(/#include.*\n/g, '')}
uniform vec2 res; uniform float t; uniform float dread; uniform float yaw;
out vec4 o;
vec3 aces(vec3 x){return clamp((x*(2.51*x+.03))/(x*(2.43*x+.59)+.14),0.,1.);}
void main(){
  vec2 uv = gl_FragCoord.xy/res; vec2 c = uv-.5; float aspect=res.x/res.y;
  vec3 sun = getSunDirWorld(normalize(vec3(1.,0.,0.)));
  float pitch = 0.08;
  vec3 fw = normalize(vec3(cos(yaw)*cos(pitch), sin(pitch), sin(yaw)*cos(pitch)));
  vec3 rt = normalize(cross(fw, vec3(0,1,0))); vec3 up = cross(rt, fw);
  vec3 d = normalize(fw + (c.x*aspect)*rt*1.1 + c.y*up*1.1);
  // fake terrain: ridged hills and dead trees as silhouettes
  float az = atan(d.z, d.x);
  float ridge = 0.02 + 0.05*fbm(vec2(az*3.0, 1.0)) + 0.03*fbm(vec2(az*11.0, 4.0));
  float tree = step(0.93, vnoise(vec2(az*60.0, 2.0))) * 0.06 * vnoise(vec2(az*200.0,5.0));
  vec3 col;
  if (d.y < ridge + tree) {
    float dist = 40.0 + 300.0*clamp((ridge - d.y)*-1.0+0.3,0.0,1.0);
    float ndl = max(dot(normalize(vec3(sun.x,0.6,sun.z)), sun),0.)*0.15;
    col = vec3(0.12,0.09,0.08)*(sunLightColor()*ndl*smoothstep(-0.1,0.05,d.y-ridge+0.05)+MIN_LIGHT);
    float fog = 1.0-exp(-dist*0.012*FOG_DENSITY*0.6);
    col = mix(col, skyBase(normalize(vec3(d.x,clamp(d.y,0.,.1),d.z)),sun)*0.45, fog);
  } else col = skyFull(d, sun, t);
  // cheap bloom stand-in around the sun
  col += vec3(1.,.15,.03)*pow(max(dot(d,sun),0.),200.)*0.4 + vec3(1.,.12,.02)*pow(max(dot(d,sun),0.),12.)*.08;
  col = aces(col*EXPOSURE);
  float l=luma(col); float red=clamp((col.r-max(col.g,col.b))*3.,0.,1.);
  col = mix(vec3(l),col,mix(.30,1.15,red)); col=max(col-.004,0.)/.996; col=pow(col,vec3(1.12));
  col = linearToSrgb(col);
  vec2 cc=c*vec2(aspect,1.); float edge=length(cc)*1.5;
  float tend=fbm(normalize(cc+1e-5)*3.+vec2(t*.07,-t*.05))*.6+fbm(cc*5.-t*.05)*.4;
  float creep=smoothstep(.75-.3*dread,1.25,edge+(tend-.5)*.45*dread);
  col*=1.-clamp(creep*VIGNETTE_STRENGTH,0.,1.);
  float g=hash12(gl_FragCoord.xy+7.)-.5; col+=g*GRAIN*(.025+.045*dread)*(1.-.5*luma(col));
  o=vec4(clamp(col,0.,1.),1.);
}`;
(async () => {
  const b = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const p = await b.newPage({ viewport: { width: 1280, height: 720 } });
  await p.setContent('<canvas id=c width=1280 height=720 style="display:block"></canvas>');
  const err = await p.evaluate(([fs, dread, yaw]) => {
    const gl = document.getElementById('c').getContext('webgl2');
    const sh = (type, src) => { const s = gl.createShader(type); gl.shaderSource(s, src); gl.compileShader(s);
      if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) throw gl.getShaderInfoLog(s); return s; };
    try {
      const pr = gl.createProgram();
      gl.attachShader(pr, sh(gl.VERTEX_SHADER, '#version 300 es\nin vec2 p;void main(){gl_Position=vec4(p,0,1);}'));
      gl.attachShader(pr, sh(gl.FRAGMENT_SHADER, fs)); gl.linkProgram(pr); gl.useProgram(pr);
      gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer());
      gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1,3,-1,-1,3]), gl.STATIC_DRAW);
      gl.enableVertexAttribArray(0); gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);
      gl.uniform2f(gl.getUniformLocation(pr, 'res'), 1280, 720);
      gl.uniform1f(gl.getUniformLocation(pr, 't'), 37.0);
      gl.uniform1f(gl.getUniformLocation(pr, 'dread'), dread);
      gl.uniform1f(gl.getUniformLocation(pr, 'yaw'), yaw * Math.PI / 180);
      gl.drawArrays(gl.TRIANGLES, 0, 3); gl.finish(); return null;
    } catch (e) { return String(e); }
  }, [frag, parseFloat(dread), parseFloat(yaw)]);
  if (err) { console.error(err); process.exit(1); }
  await p.locator('#c').screenshot({ path: out });
  await b.close(); console.log('wrote', out);
})();
