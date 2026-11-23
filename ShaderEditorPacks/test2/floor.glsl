#extension GL_OES_standard_derivatives : enable

precision highp float;
uniform vec2 resolution;
vec2 hash2(vec2 p){
    p=mod(p,8.0);
    p=vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3)));
    return fract(sin(p)*43758.5453);
}
void main(void){
    vec2 uv=gl_FragCoord.xy/resolution.xy;
    vec2 p=uv*8.0;
    vec2 n=floor(p);
    vec2 f=fract(p);
    float f1=8.0;
    float f2=8.0;
    float id=0.0;
    for(int j=-1;j<=1;j++){
        for(int i=-1;i<=1;i++){
            vec2 g=vec2(float(i),float(j));
            vec2 o=hash2(n+g);
            vec2 r=g+o*0.8+0.1-f;
            float d=dot(r,r);
            if(d<f1){
                f2=f1;
                f1=d;
                id=o.y;
            }else if(d<f2){
                f2=d;
            }
        }
    }
    float e=sqrt(f2)-sqrt(f1);
    float t=smoothstep(0.0,0.10+0.15*id,e);
    float h=t*t*(3.0-2.0*t);
    vec3 base=mix(vec3(0.30,0.29,0.28),vec3(0.68,0.65,0.58),id);
    base=mix(base,vec3(0.58,0.50,0.41),0.22);
    vec3 nrm=normalize(vec3(-dFdx(h)*3.0,-dFdy(h)*3.0,0.30));
    float l=max(dot(nrm,normalize(vec3(-0.4,-0.5,0.75))),0.0);
    vec3 col=base*(0.25+0.95*l);
    col=mix(vec3(0.045,0.042,0.040),col,h);
    col*=0.94+0.06*h;
    gl_FragColor=vec4(col,1.0);
}