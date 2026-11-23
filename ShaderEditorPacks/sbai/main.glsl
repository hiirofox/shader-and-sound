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
uniform sampler2D iChannel2;
void main(void){
    vec2 uv=gl_FragCoord.xy/resolution;
    vec4 surface=texture2D(iChannel0,uv);
    vec3 encodedVolume=texture2D(iChannel2,uv).rgb;
    vec3 volume=encodedVolume/max(vec3(0.00001),vec3(1.0)-encodedVolume);
    vec3 color=surface.rgb;
    if(surface.a<=0.0){
        color=vec3(1.0);
    }else if(surface.a<0.9999){
        float far=surface.a*30.0;
        float visibility=texture2D(iChannel1,uv).r;
        vec2 rayUV=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
        vec3 forward=normalize(iCameraDir);
        vec3 right=normalize(cross(forward,iCameraUp));
        vec3 up=normalize(cross(right,forward));
        float scale=tan(radians(clamp(iFov,0.001,179.999))*0.5);
        vec3 rd=normalize(forward+scale*(rayUV.x*right+rayUV.y*up));
        vec3 p=iCameraPos+rd*far;
        vec3 L=vec3(0.,2.5,0.)-p;
        float sceneDamp=1.0/(1.0+far*far*0.08);
        float lightDamp=1.0/(1.0+dot(L,L)*0.0008);
        color*=mix(0.35,lightDamp,step(0.5,visibility))*sceneDamp;
        color+=surface.rgb*visibility*lightDamp*(0.12/(1.0+far*far*0.02));
    }
    vec3 hdrColor=max(color+volume,vec3(0.0));
    vec3 mapped=vec3(1.0)-exp(-hdrColor*1.25);
    gl_FragColor=vec4(pow(mapped,vec3(1.0/2.2)),1.0);
}
