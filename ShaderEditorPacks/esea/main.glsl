#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform vec3 iCameraPos;
uniform vec3 iCameraDir;
uniform vec3 iCameraUp;
uniform float iFov;

uniform float time;
float fog(vec3 ray0,vec3 rayd,float scenedist)
{
    float d=clamp(scenedist,0.0,120.0);
    vec3 k0=vec3(0.13,0.08,0.09),k1=vec3(-0.21,0.12,0.07),k2=vec3(0.06,-0.16,0.19);
    vec3 q=0.5*d*vec3(dot(rayd,k0),dot(rayd,k1),dot(rayd,k2));
    vec3 p=vec3(dot(ray0,k0),dot(ray0,k1),dot(ray0,k2))+vec3(0.18,-0.13,0.11)*time+q;
    vec3 s=max(abs(q),vec3(0.001));
    float a=d*(0.04+dot(vec3(0.015,0.011,0.009),sin(p)*sin(s)/s));
    return clamp(1.0-exp(-a*.2),0.0,1.0);
}

void main(void) {
	vec2 uv = gl_FragCoord.xy / resolution.xy;
	vec2 ruv=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
        vec3 right=normalize(cross(iCameraDir,iCameraUp));
        float scale=tan(radians(clamp(iFov,.001,179.999))*.5);
        vec3 ray0=iCameraPos;
        vec3 rayd=normalize(iCameraDir+scale*(ruv.x*right+ruv.y*iCameraUp));

	vec4 seacol=vec4(texture2D(iChannel1,uv).xyz,1.);
	float seadist=1./texture2D(iChannel1,uv).w-1.;
	float fv=fog(ray0,rayd,seadist);
	seacol=mix(seacol,vec4(1.),fv*.75);
	gl_FragColor = seacol;
}
