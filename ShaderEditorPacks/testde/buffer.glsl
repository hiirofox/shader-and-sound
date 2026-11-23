#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;

float srand = 123.45678;
float hash(float p) {
    p = fract(p * .1031);
    p *= p + 33.33;
    return fract(p * (p + p));
}
float rf() { return hash(srand++); }

mat3 rotx(float w){return mat3(1.,0.,0.,0.,cos(w),sin(w),0.,-sin(w),cos(w));}
mat3 roty(float w){return mat3(cos(w),0.,-sin(w),0.,1.,0.,sin(w),0.,cos(w));}
mat3 rotz(float w){return mat3(cos(w),sin(w),0.,-sin(w),cos(w),0.,0.,0.,1.);}

float d;
vec3 fTranslate(vec3 p){return p+vec3(1.0);} //平移
vec3 fScale(vec3 p){d*=2.0;return p*2.0;} //统一缩放
vec3 fStretch(vec3 p){d*=3.0;return p*vec3(2.0,3.0,0.5);} //非均匀缩放
vec3 fMirror(vec3 p){return vec3(-p.x,p.yz);} //镜像
vec3 fAbs(vec3 p){return abs(p);} //绝对值折叠
vec3 fAbsOffset(vec3 p){return abs(p-vec3(1.0));} //偏移镜像折叠
vec3 fBoxFold(vec3 p){return 2.0*clamp(p,-1.0,1.0)-p;} //盒折叠
vec3 fSort(vec3 p){if(p.x<p.y)p.xy=p.yx;if(p.x<p.z)p.xz=p.zx;if(p.y<p.z)p.yz=p.zy;return p;} //坐标排序折叠
vec3 fRepeat(vec3 p){return mod(p+2.0,4.0)-2.0;} //周期重复
vec3 fTriFold(vec3 p){return 1.0-abs(mod(p,2.0)-1.0);} //三角波折叠
vec3 fRotate(vec3 p){float a=0.5,c=cos(a),s=sin(a);return vec3(c*p.x-s*p.y,s*p.x+c*p.y,p.z);} //绕Z轴旋转
vec3 fSphereInvert(vec3 p){float k=1.0/max(dot(p,p),1e-6);d*=k;return p*k;} //球面反演
vec3 fSphereFold(vec3 p){float r=dot(p,p),k=r<0.25?4.0:r<1.0?1.0/r:1.0;d*=k;return p*k;} //球形折叠
vec3 fRadialPower(vec3 p){float r=max(length(p),1e-6),a=2.0,k=pow(r,a-1.0);d*=k*max(1.0,abs(a));return p*k;} //径向幂变换
vec3 fNormalize(vec3 p){float r=max(length(p),1e-6);d*=1.0/r;return p/r;} //球面归一化
vec3 fRadialCompress(vec3 p){float r=length(p),k=1.0/(1.0+r);d*=k;return p*k;} //径向压缩
vec3 fSquare(vec3 p){d*=2.0*max(max(abs(p.x),abs(p.y)),abs(p.z));return p*p;} //坐标平方
vec3 fTwist(vec3 p){float a=2.0,t=a*p.z,c=cos(t),s=sin(t),h=abs(a)*length(p.xy);d*=(sqrt(4.0+h*h)+h)*0.5;return vec3(c*p.x-s*p.y,s*p.x+c*p.y,p.z);} //绕Z轴扭曲
vec3 fWave(vec3 p){float a=0.5,b=3.0,h=abs(a*b*cos(b*p.y));d*=(sqrt(4.0+h*h)+h)*0.5;return p+vec3(a*sin(b*p.y),0.0,0.0);} //正弦剪切

float de1(vec3 p){
    vec3 z=p;
    float dr=1.,r=0.;
    for(int i=0;i<16;i++){
        r=length(z);
        if(r>2.)break;
        float a=acos(z.z/r)*8.;
        float b=atan(z.y,z.x)*8.;
        dr=8.*pow(r,7.)*dr+1.;
        z=pow(r,8.)*vec3(sin(a)*cos(b),sin(a)*sin(b),cos(a))+p;
    }
    return .5*log(r)*r/dr;
}
float de2(vec3 p){
    vec3 z=p;
    float s=1.;
    for(int i=0;i<10;i++){
        z=clamp(z,-1.,1.)*2.-z;
        float r=dot(z,z);
        float k=clamp(1./r,1.,4.);
        z=z*k*2.+p;
        s=s*k*2.+1.;
    }
    return length(z)/abs(s);
}
float de3(vec3 p){
    float s=1.;
    for(int i=0;i<8;i++){
        if(p.x+p.y<0.)p.xy=-p.yx;
        if(p.x+p.z<0.)p.xz=-p.zx;
        if(p.y+p.z<0.)p.zy=-p.yz;
        p=p*2.-1.;
        s*=2.;
    }
    return (length(p)-1.)/s;
}
#define fold45(p)(p.y>p.x)?p.yx:p
  float de4(vec3 p) {
    float scale = 2.1, off0 = .8, off1 = .3, off2 = .83;
    vec3 off =vec3(2.,.2,.1);
    float s=1.0;
    for(int i = 0;++i<20;) {
      p.xy = abs(p.xy);
      p.xy = fold45(p.xy);
      p.y -= off0;
      p.y = -abs(p.y);
      p.y += off0;
      p.x += off1;
      p.xz = fold45(p.xz);
      p.x -= off2;
      p.xz = fold45(p.xz);
      p.x += off1;
      p -= off;
      p *= scale;
      p += off;
      s *= scale;
    }
    return length(p)/s;
  }
  vec3 rotate(vec3 p,vec3 axis,float theta){
    vec3 v = cross(axis,p), u = cross(v, axis);
    return u * cos(theta) + v * sin(theta) + axis * dot(p, axis);
  }
#define M_PI 3.14159265
  vec2 pmod(vec2 p, float r){
    float a = mod(atan(p.y, p.x), (M_PI*2.) / r) - 0.5 * (M_PI*2.) / r;
    return length(p) * vec2(-sin(a), cos(a));
  }

  float de5(vec3 p){
    for(int i=0;i<5;i++){
      p.xy = pmod(p.xy,12.0); p.y-=4.0;
      p.yz = pmod(p.yz,16.0); p.z-=6.8;
    }
    return dot(abs(p),rotate(normalize(vec3(2,1,3)),
        normalize(vec3(7.,1.,2.)),1.8))-0.3;
  }
  float de6(vec3 p){
    float k=time*0.01;
    p.xz=abs(.5-mod(p.xz,1.))+.01;
    float DEfactor=1.;
    for (int i=0; i<15; i++) {
      p = abs(p)-vec3(.0,1.5,0);
      float r2 = dot(p, p);
      float sc=2./clamp(r2,0.4,1.);
      p*=sc;
      DEfactor*=sc;
      p = p - vec3(0.5,1.,0.5);
    }
    return length(p)/DEfactor-.002;
  }
  float de7(vec3 p){
    const float mr=0.25, mxr=1.0;
    const vec4 scale=vec4(-3.12,-3.12,-3.12,3.12),p0=vec4(0.0,1.59,-1.0,0.0);
    vec4 z = vec4(p,1.0);
    for (int n = 0; n < 4; n++) {
      z.xyz=clamp(z.xyz, -0.94, 0.94)*2.0-z.xyz;
      z*=scale/clamp(dot(z.xyz,z.xyz),mr,mxr);
      z+=p0;
    }
    z.y-=3.0*sin(3.0+floor(p.x+0.5)+floor(p.z+0.5));
    float dS=(length(max(abs(z.xyz)-vec3(1.2,49.0,1.4),0.0))-0.06)/z.w;
    return dS;
  }
float hash13(vec3 p3){
  p3 = fract((p3)*0.1031);
  p3 += dot(p3, p3.yzx  + 19.19);
  return fract((p3.x + p3.y) * p3.z);
}
float de( vec3 p ){
  vec3 po = p;
  p = -p;

  float k=1.;
  for(int i = 0; i < 6; ++i) {
    vec3 ss = vec3(-.54,0.84,1.22);
    p = 2.0*clamp(p,-ss,ss)-p;
    float f = max(0.7/dot(p,p),0.75);
    p *= f;
    k *= f*1.05;
    //p=rotz(time*.0125)*rotx(time*.013)*p;
  }

  float res = max(length(p.xz)-.9,length(p.xz)*abs(p.y)/length(p))/k;
  p = -p;

  // crumbly
  //res += (-1.0+2.0*hash13( floor(p*10.0) ))*0.005 * (1.0-step(0.01, po.y));

  // blast
  const float ang = 0.04;
  const mat2 rot = mat2(cos(ang),sin(ang),-sin(ang),cos(ang));
  vec3 tpo = po-vec3(0,0.12,-1.5);
  tpo.xy *= rot;
  float blast = pow(smoothstep(-1.6, 0.35,po.x)-smoothstep(0.4,0.48,po.x), 3.0);
  res = min(res, length( (tpo).yz )-0.02*blast);
  return res-0.0000002;
}
vec3 denorm(vec3 p)
{
    float e = 0.00008;
    return normalize(vec3(
        de(p + vec3(e,0,0)) - de(p - vec3(e,0,0)),
        de(p + vec3(0,e,0)) - de(p - vec3(0,e,0)),
        de(p + vec3(0,0,e)) - de(p - vec3(0,0,e))
    ));
}

bool raymap(vec3 r0, vec3 rd, out float t, out vec3 n)
{
    bool hit = true;
    float t0 = 0.00002, pk = 0., pt = 0.;
    int i;
    for(i = 0; i < 200; ++i)
    {
        float k = de(r0 + rd*t0);
        if(k < 0.00003){hit = true; break;}
	t0+=k;continue;
    }
    if(i<2)//场景太近了
    {
    	n=normalize(-rd);
    }
    else if(hit)n = denorm(r0 + rd*t0);
    t = t0;

    return hit;
}

uniform vec3 iCameraPos;
uniform vec3 iCameraDir;
uniform vec3 iCameraUp;
uniform float iFov;
void main(void) {

vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
vec3 right = normalize(cross(iCameraDir, iCameraUp));
float scale = tan(radians(clamp(iFov, .001, 179.999)) * .5);

vec3 ray0 = iCameraPos;
vec3 rayd = normalize(iCameraDir + scale *
    (uv.x * right + uv.y * iCameraUp));

    vec3 o=ray0,d=rayd;

    float t;
    vec3 n;
    bool hit=raymap(o,d,t,n);
    //vec4 col=vec4(0.);
    //col=tncol(t,n,d,hit);
    //if(!hit)t=9999.;
    gl_FragColor = vec4(n*.3+vec3(.5),t/300.);
}
