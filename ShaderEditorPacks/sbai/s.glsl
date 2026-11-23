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
const int SHADOW_STEPS=64;
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
float hardShadow(vec3 p,vec3 lightPos){
    vec3 L=lightPos-p;
    float maxDist=length(L);
    if(maxDist<0.04)return 1.0;
    vec3 dir=L/maxDist;
    float t=0.02;
    for(int i=0;i<SHADOW_STEPS;i++){
        if(dot(L,lightPos-(p+dir*t))<=0.0)return 1.0;
        float h=deDist(p+dir*t);
        if(h<0.0015)return 0.0;
        t+=clamp(h*0.95,0.015,1.8);
    }
    return 1.0;
}
void main(void){
    vec2 texUV=gl_FragCoord.xy/resolution;
    vec4 surface=texture2D(iChannel0,texUV);
    if(surface.a<=0.0||surface.a>=0.9999){
        gl_FragColor=vec4(0.0,0.0,0.0,1.0);
        return;
    }
    vec2 uv=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 forward=normalize(iCameraDir);
    vec3 right=normalize(cross(forward,iCameraUp));
    vec3 up=normalize(cross(right,forward));
    float scale=tan(radians(clamp(iFov,0.001,179.999))*0.5);
    vec3 rd=normalize(forward+scale*(uv.x*right+uv.y*up));
    vec3 p=iCameraPos+rd*(surface.a*30.0);
    vec3 light=vec3(0.,2.5,0.);
    vec3 L=light-p;
    float visible=hardShadow(p+normalize(L)*0.025,light);
    gl_FragColor=vec4(visible,visible,visible,1.0);
}
