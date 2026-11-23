#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
uniform vec2 resolution;
uniform float time;
float hash(float p){p=fract(p*.1031);p*=p+33.33;return fract(p*(p+p));}
bool leaf(vec2 p,vec2 a,vec2 b,float m){
    m=clamp(m,0.,1.);
    vec2 d=b-a,v=p-(a+b)*.5;
    vec2 h=.5*abs(d.yx)+.41421356*m*abs(d);
    if(any(greaterThan(abs(v),h)))return false;
    float z=dot(d,d),x=dot(v,vec2(-d.y,d.x))/z,y=abs(dot(v,d))/z/max(2.*m,.001)+.5;
    return x*x+y*y<.5;
}
void main(void){
    vec2 uv=gl_FragCoord.xy/resolution.xy;
    vec4 col=vec4(0.0);
    float count=6.0;
    float size=0.205;
    vec2 base=floor(uv*count);
    for(int j=-1;j<=1;j++){
        for(int i=-1;i<=1;i++){
            vec2 id=base+vec2(float(i),float(j));
            if(any(lessThan(id,vec2(0.0)))||any(greaterThanEqual(id,vec2(count))))continue;
            float seed=dot(id,vec2(127.1,311.7));
            vec2 jitter=vec2(hash(seed+1.37),hash(seed+4.11))-0.5;
            vec2 c=(id+0.5+jitter*0.3)/count;
            float center=1.0-smoothstep(0.1,0.65,length(c-0.5));
            float density=mix(0.9,1.0,center);
            if(hash(seed+9.62)>density)continue;
            if(length(uv-c)>size*0.95+0.025)continue;
            float angle=hash(seed+6.19)*6.2831853;
            float len=size*(0.82+0.26*hash(seed+12.71));
            float m=0.42+0.14*hash(seed+15.31);
            vec2 d=vec2(cos(angle),sin(angle))*len;
            vec2 h=0.5*abs(d.yx)+0.41421356*m*abs(d);
            c=clamp(c,h+0.002,1.0-h-0.002);
            if(any(greaterThan(abs(uv-c),h)))continue;
            if(leaf(uv,c-d*0.5,c+d*0.5,m)){
                float v=hash(seed+18.7);
                vec3 color=mix(vec3(0.23,0.68,0.28),vec3(0.38,0.79,0.25),v);
                col=vec4(color,1.0);
            }
        }
    }
    gl_FragColor=col;
}