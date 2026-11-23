
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
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
const int VOLUME_STEPS=40;
const int SHADOW_STEPS=48;
float deDist(vec3 p){
    p.xz=abs(.5-mod(p.xz,1.))+.01;
    float DEfactor=1.;
    for(int i=0;i<15;i++){
        p=abs(p)-vec3(.0,1.5,0.);
        float r2=dot(p,p);
        float sc=2./clamp(r2,0.4,1.);
        p*=sc;
        DEfactor*=sc;
        p-=vec3(0.5,1.,0.5);
    }
    return length(p)/DEfactor-.001;
}
float lightVisibility(vec3 p,vec3 light){
    vec3 toLight=light-p;
    float maxDist=length(toLight);
    if(maxDist<0.03)return 1.0;
    vec3 dir=toLight/maxDist;
    float t=0.02;
    for(int i=0;i<SHADOW_STEPS;i++){
        vec3 q=p+dir*t;
        if(dot(toLight,light-q)<=0.0)return 1.0;
        float d=deDist(q);
        if(d<0.0015)return 0.0;
        t+=clamp(d*0.95,0.015,1.2);
    }
    return 1.0;
}
void main(void){
    vec2 texUV=gl_FragCoord.xy/resolution;
    vec4 surface=texture2D(iChannel0,texUV);
    vec2 uv=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 forward=normalize(iCameraDir);
    vec3 right=normalize(cross(forward,iCameraUp));
    vec3 up=normalize(cross(right,forward));
    float scale=tan(radians(clamp(iFov,0.001,179.999))*0.5);
    vec3 ro=iCameraPos;
    vec3 rd=normalize(forward+scale*(uv.x*right+uv.y*up));
    vec3 light=vec3(0.0,2.5,0.0);
    float tEnd=30.0;
    if(surface.a>0.0&&surface.a<0.9999)tEnd=surface.a*30.0;
    if(surface.a<=0.0)tEnd=min(length(light-ro),30.0);
    float ds=tEnd/float(VOLUME_STEPS);
    float sigmaT=0.025;
    float volumeStrength=0.655;
    float volumeAccum=0.0;
    for(int i=0;i<VOLUME_STEPS;i++){
        float t=(float(i)+0.5)*ds;
        vec3 p=ro+rd*t;
        vec3 L=light-p;
        float r2=dot(L,L);
        float visibility=lightVisibility(p,light);
        float lightDamp=1.0/(1.0+0.018*r2);
        float distanceDamp=mix(1.0,1.0/(1.0+0.08*t*t),smoothstep(22.0,30.0,t));
        volumeAccum+=visibility*lightDamp*exp(-sigmaT*t)*distanceDamp*volumeStrength*ds;
    }
    vec3 volume=vec3(1.0,0.92,0.8)*volumeAccum;
    gl_FragColor=vec4(volume/(vec3(1.0)+volume),1.0);
}
