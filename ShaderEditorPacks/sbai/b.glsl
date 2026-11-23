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
float de(vec3 p,out vec3 pmap){
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
vec3 orbitcol(vec3 p){
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
    return col;
}
void main(void){
    vec2 uv=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 forward=normalize(iCameraDir);
    vec3 right=normalize(cross(forward,iCameraUp));
    vec3 up=normalize(cross(right,forward));
    float scale=tan(radians(clamp(iFov,0.001,179.999))*0.5);
    vec3 ro=iCameraPos;
    vec3 rd=normalize(forward+scale*(uv.x*right+uv.y*up));
    vec3 light=vec3(0.,2.5,0.);
    float far=0.01;
    bool hitScene=false;
    bool hitLight=false;
    for(int i=0;i<100;i++){
        vec3 p=ro+rd*far;
        float d=deDist(p);
        float dl=length(p-light)-0.01;
        if(d<0.0001){
            hitScene=true;
            break;
        }
        if(dl<0.0001){
            hitLight=true;
            break;
        }
        far+=max(min(d,dl),0.0001);
        if(far>=30.0)break;
    }
    if(hitLight){
        gl_FragColor=vec4(1.0,1.0,1.0,0.0);
        return;
    }
    if(!hitScene||far>=30.0){
        gl_FragColor=vec4(0.005,0.008,0.02,1.0);
        return;
    }
    vec3 pmap;
    de(ro+rd*far,pmap);
    vec3 albedo=orbitcol(pmap*0.005+vec3(0.1,0.5,0.2));
    gl_FragColor=vec4(albedo,far/30.0);
}
