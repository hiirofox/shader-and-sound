//shining finger by gy314

#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;
uniform sampler2D backbuffer;
uniform float ftime;
uniform int frame;
vec4 uvgen(vec2 uv)
{
	//return (abs(uv.x)<0.001||abs(uv.y)<0.001)?vec4(1.):vec4(0.)
	return (abs(uv.x*uv.y*2.)<0.001)?vec4(1.):vec4(0.);
}
vec2 uvmap(float k,vec2 uv)
{
	float t = time*k*.05;
	mat2 rot=mat2(cos(t),sin(t),-sin(t),cos(t));
	return uv+rot*uv*.2;
}
vec4 colmorph(vec4 c)
{
	vec4 d=vec4(c.y*c.z,c.z,c.x*1.,c.w);
	return c*.5+d*.5;
}
void main(void) {
	vec2 uv = gl_FragCoord.xy/resolution.xy-mouse;
	//uv.x/=resolution.x/resolution.y;
	vec4 a = uvgen(uv);
	vec4 b1 = texture2D(backbuffer,uvmap(1.,uv+vec2(.5,.5)));
	vec4 b2 = texture2D(backbuffer,uvmap(2.,uv+vec2(.25,.75)));
	vec4 b3 = texture2D(backbuffer,uvmap(3.,uv+vec2(.45,.15)));
	gl_FragColor = colmorph(a+(b1+b2+b3)/3.*0.995);
}
