#if 0
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform vec2 resolution;
void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec4 g = texture2D(iChannel0, uv);
    vec3 col = texture2D(iChannel1, uv).xyz;
    vec3 n=g.xyz;
    float t=g.w;
    bool hit = length(g.xyz)>0.5&&g.w<999.;
}
#endif


#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform vec2 resolution;
vec3 readn(vec2 uv) { return (texture2D(iChannel0,clamp(uv,0.0,1.0)).xyz-0.5)/0.3; }
float readt(vec2 uv) { return texture2D(iChannel0,clamp(uv,0.0,1.0)).w*1000.; }
bool valid(vec2 uv) { return length(readn(uv))>0.5&&readt(uv)<0.999; }
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float calcAO(vec2 uv) {
    if(!valid(uv)) return 1.0;
    vec3 n=normalize(readn(uv));
    float t=readt(uv);
    vec2 px=1.0/resolution;
    float radius=clamp(0.012/max(t,0.05),0.008,0.045);
    float angle=hash(floor(uv*resolution/2.0))*6.2831853;
    float occ=0.0;
    float weight=0.0;
    for(int i=0;i<12;i++) {
        float fi=float(i);
        float r=sqrt((fi+0.5)/24.0);
        float a=angle+fi*2.39996323;
        vec2 dir=vec2(cos(a),sin(a));
        vec2 suv=uv+dir*r*radius;
        if(suv.x<=0.0||suv.x>=1.0||suv.y<=0.0||suv.y>=1.0) continue;
        if(!valid(suv)) continue;
        float st=readt(suv);
        vec3 sn=normalize(readn(suv));
        float dz=t-st;
        float proximity=1.0-smoothstep(0.005,0.085,abs(dz));
        float front=smoothstep(0.0015,0.025,dz);
        float nd=max(dot(n,sn),0.0);
        float crease=1.0-nd;
        float slope=abs(n.x*dir.x+n.y*dir.y);
        float w=proximity*(0.75+0.25*(1.0-r));
        float o=front*(0.55+0.45*crease)*(0.65+0.35*slope);
        occ+=o*w;
        weight+=w;
    }
    return clamp(1.0-occ/max(weight,0.001)*2.0,0.35,1.0);
}
void main() {
    vec2 uv=gl_FragCoord.xy/resolution.xy;
    vec3 col=texture2D(iChannel1,uv).rgb;
    if(!valid(uv)) { gl_FragColor=vec4(col,1.0); return; }
    vec3 n=normalize(readn(uv));
    float t=readt(uv);
    vec2 px=1.0/resolution;
    float ao=calcAO(uv)*4.0;
    float weight=4.0;
    for(int i=0;i<4;i++) {
        vec2 off=i==0?vec2(1.5,0.0):i==1?vec2(-1.5,0.0):i==2?vec2(0.0,1.5):vec2(0.0,-1.5);
        vec2 suv=clamp(uv+off*px,0.0,1.0);
        if(!valid(suv)) continue;
        float dt=abs(readt(suv)-t);
        float dn=max(dot(n,normalize(readn(suv))),0.0);
        float w=exp(-dt*dt*3500.0)*pow(dn,8.0);
        ao+=calcAO(suv)*w;
        weight+=w;
    }
    ao=clamp(ao/weight,0.0,1.0);
    ao=smoothstep(0.0,1.0,ao);
    col*=mix(1.0,ao,0.8);
    gl_FragColor=vec4(col,1.0);
}