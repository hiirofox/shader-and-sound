#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform float time;
float wave(vec2 uv,float t){
    vec2 p=uv*6.2831853;
    vec2 w1=vec2(sin(dot(p,vec2(1,2))+t*.21),sin(dot(p,vec2(-2,1))-t*.17));
    vec2 w2=vec2(sin(dot(p,vec2(3,-1))-t*.11),sin(dot(p,vec2(2,3))+t*.09));
    p+=w1*.38+w2*.14;
    float h=0.0;
    h+=.42*exp(sin(dot(p,vec2(1,2))+t*.80)-1.0);
    h+=.24*exp(sin(dot(p,vec2(-2,1))-t*.67)-1.0);
    h+=.17*exp(sin(dot(p,vec2(2,-3))+t*1.07)-1.0);
    h+=.10*exp(sin(dot(p,vec2(5,3))-t*1.31)-1.0);
    h+=.07*exp(sin(dot(p,vec2(-4,6))+t*1.73)-1.0);
    h+=.04*exp(sin(dot(p,vec2(7,-5))-t*2.10)-1.0);
    return h;
}
void main(void){
    vec2 uv=gl_FragCoord.xy/resolution.xy;
    vec2 e=vec2(1.0/1024.0,0.0);
    float hx=wave(uv+e.xy,time)-wave(uv-e.xy,time);
    float hy=wave(uv+e.yx,time)-wave(uv-e.yx,time);
    vec3 n=normalize(vec3(-hx*18.0,-hy*18.0,1.0));
    gl_FragColor=vec4(n*0.5+0.5,1.0);
}