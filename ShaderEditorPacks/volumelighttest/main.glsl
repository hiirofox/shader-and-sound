
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;
uniform vec3 iCameraPos;
uniform vec3 iCameraDir;
uniform vec3 iCameraUp;
uniform float iFov;
const int VOLUME_STEPS=128;
const int SHADOW_STEPS=64;

float de1(vec3 p,out vec3 pmap){
    p.xz=abs(.5-mod(p.xz,1.))+.01;
    float DEfactor=1.;
    vec3 sp=vec3(0.);
    for(int i=0;i<15;i++){
        p=abs(p)-vec3(.0,1.5,0.);
        float r2=dot(p,p);
        float sc=2./clamp(r2,0.4,1.);
        p*=sc;
        DEfactor*=sc;
        p-=vec3(0.5,1.,0.5);
        sp+=p;
    }
    pmap=sp;
    return length(p)/DEfactor-.001;
}
float de( vec3 p ,out vec3 pmap){
  vec3 po = p;
  p = -p;

  float k=1.;
  vec3 sp=vec3(0.);
  for(int i = 0; i < 6; ++i) {
    vec3 ss = vec3(-.54,0.84,1.22);
    p = 2.0*clamp(p,-ss,ss)-p;
    float f = max(0.7/dot(p,p),0.75);
    p *= f;
    k *= f*1.05;
    //p=rotz(time*.0125)*rotx(time*.013)*p;
    sp+=p;
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
  pmap=sp*200.;
  return res-0.002;
}
float deDist(vec3 p){
    vec3 pmap;
    return de(p,pmap);
}
vec4 orbitcol(vec3 p){
    vec3 q=log(1.0+abs(p)*vec3(2.0,3.5,1.4));
    vec3 phase=fract(q*vec3(0.37,0.23,0.51));
    phase+=0.06*sin(p.yzx*vec3(2.1,3.7,1.6));
    float cyan=exp(-90.0*pow(phase.x-0.72,2.0));
    float green=exp(-130.0*pow(phase.y-0.43,2.0));
    float gold=exp(-110.0*pow(phase.z-0.81,2.0));
    float red=exp(-180.0*pow(phase.x-0.91,2.0));
    float pink=exp(-150.0*pow(phase.y-0.87,2.0));
    vec3 col=mix(vec3(0.015,0.025,0.12),vec3(0.18,0.08,0.42),0.5+0.5*sin(dot(q,vec3(1.3,0.7,1.9))));
    col=mix(col,vec3(0.0,0.85,0.95),cyan);
    col=mix(col,vec3(0.25,0.9,0.18),green);
    col=mix(col,vec3(1.0,0.65,0.05),gold);
    col=mix(col,vec3(1.0,0.08,0.06),red);
    col=mix(col,vec3(0.95,0.18,0.65),pink);
    return vec4(col,1.0);
}
float hardShadow(vec3 p,vec3 lightPos){
    vec3 L=lightPos-p;
    float maxDist=length(L);
    if(maxDist<0.04)return 1.0;
    vec3 dir=L/maxDist;
    float t=0.025;
    for(int i=0;i<SHADOW_STEPS;i++){
        if(t>=maxDist-0.025)return 1.0;
        float h=deDist(p+dir*t);
        if(h<0.0015)return 0.0;
        t+=clamp(h*0.92,0.015,1.5);
    }
    return 1.0;
}
void main(void){
    vec2 uv=(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 forward=normalize(iCameraDir);
    vec3 right=normalize(cross(forward,iCameraUp));
    vec3 up=normalize(cross(right,forward));
    float scale=tan(radians(clamp(iFov,.001,179.999))*.5);
    vec3 ro=iCameraPos;
    vec3 rd=normalize(forward+scale*(uv.x*right+uv.y*up));
    vec3 light=vec3(0.,2.5,0.);
    float far=0.01;
    float lastT=far;
    bool hitlight=false;
    bool hitscene=false;
    for(int iter=0;iter<100;iter++){
        vec3 p=ro+rd*far;
        lastT=far;
        float t1=deDist(p);
        float t2=length(p-light)-.01;
        if(t1<0.000001){
            hitscene=true;
            break;
        }
        if(t2<0.0001){
            hitlight=true;
            break;
        }
        far+=max(min(t1,t2),0.0001);
        if(far>30.)break;
    }
    far=min(far,30.);
    vec3 hitPos=ro+rd*far;
    vec3 surfaceColor=vec3(0.);
    float scenedamp=1.0/(1.0+far*far*.08);
    if(hitlight){
        surfaceColor=vec3(1.0);
    }else{
        vec3 pmap;
        de(ro+rd*min(lastT,30.0),pmap);
        vec3 albedo=orbitcol(pmap*.005+vec3(.1,.5,.2)).rgb;
        vec3 L=light-hitPos;
        float lightDist2=dot(L,L);
        float lightdamp=1.0/(1.0+lightDist2*.0008);
        float visibility=hardShadow(hitPos+normalize(L)*0.025,light);
        surfaceColor=albedo*mix(0.35,lightdamp,visibility)*scenedamp;
        if(hitscene&&visibility>0.5){
            float contactLight=0.12/(1.0+far*far*.02);
            surfaceColor+=albedo*lightdamp*contactLight;
        }
    }
    float tEnd=far;
    float ds=tEnd/float(VOLUME_STEPS);
    float sigmaT=0.025;
    float volumeStrength=0.655;
    vec3 lightColor=vec3(1.0,0.92,0.8);
    float volumeAccum=0.0;
    float transmittance=1.0;
    float stepTr=exp(-sigmaT*ds);
    for(int i=0;i<VOLUME_STEPS;i++){
        if(i==VOLUME_STEPS-1&&hitscene){
            float subDs=ds*0.25;
            float subTr=exp(-sigmaT*subDs);
            for(int j=0;j<4;j++){
                float t=float(i)*ds+(float(j)+0.5)*subDs;
                vec3 p=ro+rd*t;
                vec3 L=light-p;
                float r2=dot(L,L);
                float visibility=hardShadow(p,light);
                if(visibility>0.5){
                    float attenuation=1.0/(1.0+0.018*r2);
                    float distanceDamp=1.0/(1.0+0.004*t*t);
                    volumeAccum+=transmittance*attenuation*distanceDamp*volumeStrength*subDs;
                }
                transmittance*=subTr;
            }
        }else{
            float t=(float(i)+0.5)*ds;
            vec3 p=ro+rd*t;
            vec3 L=light-p;
            float r2=dot(L,L);
            float visibility=hardShadow(p,light);
            if(visibility>0.5){
                float attenuation=1.0/(1.0+0.018*r2);
                float distanceDamp=1.0/(1.0+0.004*t*t);
                volumeAccum+=transmittance*attenuation*distanceDamp*volumeStrength*ds;
            }
            transmittance*=stepTr;
        }
        if(volumeAccum>=0.8125)break;
    }
    vec3 volume=min(lightColor*volumeAccum,vec3(0.65));
    vec3 color=clamp(surfaceColor+volume,0.0,1.0);
    gl_FragColor=vec4(color,1.0);
}
