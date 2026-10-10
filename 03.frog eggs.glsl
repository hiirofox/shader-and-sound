#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;

float seed = 12345.6789;
float randf()
{
    seed = fract(seed * 1.23456789 + 0.3141592653);
    seed = fract(seed * (seed + 19.19));
    return seed * 2.0 - 1.0;
}
float hat(float x,float r)
{
	return 1./(1.+x*x/r);
}
float cirsdf(vec3 ray0,vec3 pix,float r)
{
    return length(ray0-pix)-r;
}
mat3 rotx(float w)
{
	return mat3(1.,0.,0., 0.,cos(w),sin(w), 0.,-sin(w),cos(w));
}
mat3 roty(float w)
{
    return mat3(cos(w),0.,-sin(w), 0.,1.,0., sin(w),0.,cos(w));
}
mat3 rotz(float w)
{
    return mat3(cos(w),sin(w),0., -sin(w),cos(w),0., 0.,0.,1.);
}
void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    vec3 ray0 = vec3(-0.,-0., -5.);
    vec2 m = mouse * 2.0 - 1.0;
    //float yaw   = -(mouse.x - 0.5) * (resolution.x / resolution.y) * 12.0;
    //float pitch =  (mouse.y - 0.5) * 6.0;
    float yaw=0.,pitch=0.;
    vec3 forward = normalize(vec3(sin(yaw) * cos(pitch),sin(pitch), cos(yaw) * cos(pitch)));
    vec3 worldUp = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(forward, worldUp));
    vec3 up = cross(right, forward);
    float fov = radians(100.0);
    float tanHalfFov = tan(fov * 0.5);
    vec3 rayd = normalize(forward + right * uv.x * tanHalfFov    + up    * uv.y * tanHalfFov);

#define cirs 12
    float w = time*0.025;

    vec3 cps[cirs];
    vec4 ccol[cirs];
    float rs[cirs];
    for (int i = 0;i < cirs;++i)
    {
        cps[i] = rotx(m.y*6.)*rotz(m.x*6.)*
        	vec3(randf()*1.,randf()*1.,randf())*1.6;
        //ccol[i] = vec4(abs(randf()),abs(randf())*.8,abs(randf()),1.)*1.5;
        ccol[i]=vec4(abs(randf())*.5+.5);
        rs[i]=abs(randf())*.6+.2;
    }
    vec3 r0=ray0;
    vec3 rp = ray0;
    vec3 rd = rayd;
    int mi = -1,lastmi=-1;
    vec4 col= vec4(0.,0.,0.,1.);
    for (int  k = 0;k < 3;++k)
    {
    for (int i = 0;i < 8;++i)
    {
    	float minsdf=999.;
    	for (int j = 0;j < cirs;++j)
    	{
    		float sdf = cirsdf(rp,cps[j],rs[j]);
    		if (sdf<minsdf)
    		{
    			minsdf=sdf;
    			mi = j;
    		}
    	}
    	rp += minsdf*rd;
    }
    vec3 n = normalize(rp-cps[mi]);
    vec3 v = normalize(ray0 - rp);
    if (abs(length(rp-cps[mi])-rs[mi])<0.02&&lastmi != mi)
    {
        col += ccol[mi]*hat(-dot(normalize(r0-rp),n),.17)/(float(k+1));
        lastmi = mi;
    }
        r0=rp;
        rd = n;
    }
    gl_FragColor = vec4(col);
}
