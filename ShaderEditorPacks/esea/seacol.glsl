#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform float time;
uniform sampler2D iChannel0;
uniform vec3 iCameraPos;
uniform vec3 iCameraDir;
uniform vec3 iCameraUp;
uniform float iFov;
void main(){
    vec2 ruv=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 right=normalize(cross(iCameraDir,iCameraUp));
    float scale=tan(radians(clamp(iFov,.001,179.999))*.5);
    vec3 ray0=iCameraPos;
    vec3 rayd=normalize(iCameraDir+scale*(ruv.x*right+ruv.y*iCameraUp));
    if(rayd.y>=0.0){
        gl_FragColor=vec4(0.0,0.0,0.0,0.0001);
        return;
    }
    float t=-ray0.y/rayd.y;
    if(t<=0.0){
        gl_FragColor=vec4(0.0,0.0,0.0,1.0);
        return;
    }
    vec3 pos=ray0+rayd*t;
    vec2 tuv=pos.xz*.035+vec2(time*.012,-time*.008);
    vec3 nsea=texture2D(iChannel0,fract(tuv)).xyz*2.0-1.0;
    vec3 n=normalize(vec3(nsea.x*.5,max(nsea.z,.1),nsea.y*.5));
    vec3 v=-rayd;
    float fresnel=pow(1.0-max(dot(n,v),0.0),5.0);
    vec3 light=normalize(vec3(.35,.8,.45));
    float spec=pow(max(dot(reflect(-light,n),v),0.0),96.0);
    float sheen=pow(max(dot(reflect(-light,n),v),0.0),12.0);
    vec3 col=vec3(.01,.01,.01)*3.;
    col+=vec3(.13,.16,.18)*fresnel;
    col+=vec3(.35,.38,.4)*sheen*.25;
    col+=vec3(.85,.9,1.0)*spec*.7;
    gl_FragColor=vec4(col,1.0/(1.+t));
}