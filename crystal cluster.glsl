// Shader Editor disabled this shader because it caused a crash while loading.
// Fix the shader and remove the #if 0 wrapper to re-enable it.

#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

mat3 rotx(float w){return mat3(1.,0.,0.,0.,cos(w),sin(w),0.,-sin(w),cos(w));}
mat3 roty(float w){return mat3(cos(w),0.,-sin(w),0.,1.,0.,sin(w),0.,cos(w));}
mat3 rotz(float w){return mat3(cos(w),sin(w),0.,-sin(w),cos(w),0.,0.,0.,1.);}

vec3 r0,rd;//test ray
float nt;//near
vec3 np,nr;
vec4 gcol,ncol;

bool tritest(vec3 o,vec3 d,vec3 a,vec3 b,vec3 c,out float t,out vec3 p,out vec3 r)
{
    t=999.;
    vec3 e1=b-a,e2=c-a,n=cross(e1,e2);
    float nn=dot(n,n);
    if(nn<1e-12)return false;
    float det=-dot(d,n),ad=abs(det);
    if(det*det<1e-8*nn)return false;
    vec3 s=o-a;
    float sg=sign(det);
    float u=dot(s,cross(d,e2))*sg;
    if(u<0.||u>ad)return false;
    vec3 q=cross(s,e1);
    float v=dot(d,q)*sg;
    if(v<0.||u+v>ad)return false;
    float x=dot(e2,q)/det;
    if(x<=1e-4||x>=999.)return false;
    t=x;
    p=o+x*d;
    r=d+(2.*det/nn)*n;
    return true;
}
void addtri(vec3 a,vec3 b,vec3 c)
{
	float t;
	vec3 p,r;
	bool hit=tritest(r0,rd,a,b,c,t,p,r);
	if(hit&&t<nt){nt=t;np=p;nr=r;ncol=gcol;}
}
bool crystalhittest(vec3 r0,vec3 rd,vec3 pos,vec3 up,float sz,float len){
    vec3 z=normalize(up),v=r0-pos;
    float h=len+1.270335113*sz,a=dot(v,z),b=dot(rd,z),t0=0.,t1=1e30;
    if(b==0.){if(a<0.||a>h)return false;}
    else{float k=1./b,u=-a*k,w=(h-a)*k;t0=max(0.,min(u,w));t1=max(u,w);if(t0>t1)return false;}
    vec3 p=v-z*a,d=rd-z*b;
    float dd=dot(d,d),t=dd>0.?clamp(-dot(p,d)/dd,t0,t1):t0;
    p+=d*t;
    return dot(p,p)<=1.333333333*sz*sz;
}
void addcrystal(vec3 pos,vec3 up,float rot,float sz,float len){
    if(!crystalhittest(r0,rd,pos,up,sz,len))return;
    vec3 Z=normalize(up),X,Y;
    float c=cos(rot),s=sin(rot),m=sz*.577350269189626;
    if(Z.z>-.999999){
        float k=1./(1.+Z.z),a=Z.x*c+Z.y*s,b=Z.y*c-Z.x*s;
        X=sz*vec3(c-Z.x*k*a,s-Z.y*k*a,-a);
        Y=m*vec3(-s-Z.x*k*b,c-Z.y*k*b,-b);
    }else{
        X=sz*vec3(c,-s,0.);
        Y=m*vec3(-s,-c,0.);
    }
    vec3 P=pos+Z*len,V=Z*sz,D=P+V*.211722519,E=P+V*1.058612594,T=P+V*1.270335113;
    vec3 o0=X-Y,o1=X+Y,b0=pos+o0,b1=pos+o1,c0=P+o0,c1=P+o1;
    addtri(b0,b1,c1);
    addtri(b0,c1,c0);
    vec3 d0=D+X*.833333333333333+Y*1.166666666666667;
    addtri(c0,c1,d0);
    vec3 e0=E+X*.166666666666667+Y*.5;
    addtri(c0,d0,e0);
    addtri(c0,e0,T);
    vec3 e2=E+X*.166666666666667-Y*.5;
    addtri(c0,T,e2);
    vec3 d5=D+X*.833333333333333-Y*1.166666666666667;
    addtri(c0,e2,d5);
    vec3 o2=2.*Y,b2=pos+o2,c2=P+o2;
    addtri(b1,b2,c2);
    vec3 d1=D+X*.166666666666667+Y*1.833333333333333;
    addtri(b1,c2,d1);
    addtri(b1,d1,d0);
    addtri(b1,d0,c1);
    addtri(d0,d1,e0);
    vec3 o3=Y-X,b3=pos+o3,c3=P+o3;
    addtri(b2,b3,c3);
    addtri(b2,c3,c2);
    vec3 d2=D-X+Y*.666666666666667;
    addtri(c2,c3,d2);
    vec3 e1=E-X*.333333333333333;
    addtri(c2,d2,e1);
    addtri(c2,e1,T);
    addtri(c2,T,e0);
    addtri(c2,e0,d1);
    vec3 o4=-X-Y,b4=pos+o4,c4=P+o4;
    addtri(b3,b4,c4);
    vec3 d3=D-X-Y*.666666666666667;
    addtri(b3,c4,d3);
    addtri(b3,d3,d2);
    addtri(b3,d2,c3);
    addtri(d2,d3,e1);
    vec3 o5=-2.*Y,b5=pos+o5,c5=P+o5;
    addtri(b4,b5,c5);
    addtri(b4,c5,c4);
    vec3 d4=D+X*.166666666666667-Y*1.833333333333333;
    addtri(c4,c5,d4);
    e2=E+X*.166666666666667-Y*.5;
    addtri(c4,d4,e2);
    addtri(c4,e2,T);
    addtri(c4,T,e1);
    addtri(c4,e1,d3);
    o0=X-Y;
    b0=pos+o0;
    c0=P+o0;
    addtri(b5,b0,c0);
    d5=D+X*.833333333333333-Y*1.166666666666667;
    addtri(b5,c0,d5);
    addtri(b5,d5,d4);
    addtri(b5,d4,c5);
    addtri(d4,d5,e2);
}
void scene1()
{
	gcol=vec4(.5,1.,1.,1.);
       addcrystal(vec3(0.,-.8,0.),vec3(0.,1.,0.),0.,.25,1.6);
       gcol=vec4(.1,.5,1.,1.);
       addcrystal(vec3(.3,-.8,.1),vec3(.3,1.,.15),.4,.18,1.1);
       gcol=vec4(.5,.1,1.,1.);
       addcrystal(vec3(-.3,-.8,0.),vec3(-.4,1.,0.),.7,.2,1.2);
       gcol=vec4(1.,1.,.5,1.);
       addcrystal(vec3(0.,-.8,-.3),vec3(.1,1.,-.4),1.2,.15,.9);
}
void scene2()
{
//scene start
gcol=vec4(.66,.90,1.,1.);
addcrystal(vec3( 0.00,-.90, 0.00),vec3( .02,1.00, .01),0.18,.24,1.85);
addcrystal(vec3(-0.13,-.89,-0.05),vec3(-.16,1.00,-.08),0.82,.20,1.45);
addcrystal(vec3( 0.14,-.89,-0.06),vec3( .18,1.00,-.10),1.36,.19,1.36);
addcrystal(vec3( 0.05,-.89, 0.13),vec3( .08,1.00, .18),0.56,.18,1.22);
gcol=vec4(.42,.74,.98,1.);
addcrystal(vec3(-0.16,-.88, 0.11),vec3(-.24,1.00, .18),1.14,.17,1.10);
addcrystal(vec3( 0.17,-.88, 0.10),vec3( .28,1.00, .16),0.34,.16,1.04);
addcrystal(vec3(-0.04,-.88,-0.17),vec3(-.05,1.00,-.28),2.08,.16,1.12);
addcrystal(vec3( 0.09,-.88,-0.18),vec3( .14,1.00,-.30),0.94,.15,1.00);
gcol=vec4(.24,.50,.84,1.);
addcrystal(vec3(-0.25,-.87,-0.10),vec3(-.36,1.00,-.14),0.70,.15,.92);
addcrystal(vec3( 0.25,-.87,-0.09),vec3( .38,1.00,-.12),1.62,.14,.88);
addcrystal(vec3(-0.22,-.87, 0.19),vec3(-.34,1.00, .28),1.84,.14,.84);
addcrystal(vec3( 0.23,-.87, 0.18),vec3( .36,1.00, .26),2.42,.14,.82);
gcol=vec4(.74,.68,1.,1.);
addcrystal(vec3(-0.29,-.86, 0.03),vec3(-.48,1.00, .04),0.28,.13,.70);
addcrystal(vec3( 0.30,-.86, 0.04),vec3( .50,1.00, .06),1.22,.13,.72);
addcrystal(vec3(-0.12,-.86, 0.27),vec3(-.18,1.00, .42),2.22,.12,.68);
addcrystal(vec3( 0.13,-.86, 0.27),vec3( .20,1.00, .44),0.78,.12,.66);
gcol=vec4(.36,.82,.90,1.);
addcrystal(vec3(-0.31,-.85,-0.18),vec3(-.52,1.00,-.30),1.04,.11,.58);
addcrystal(vec3( 0.31,-.85,-0.17),vec3( .54,1.00,-.28),2.00,.11,.60);
addcrystal(vec3(-0.02,-.85,-0.29),vec3( .00,1.00,-.50),2.62,.11,.56);
addcrystal(vec3( 0.00,-.85, 0.31),vec3( .02,1.00, .52),0.48,.11,.58);
//scene end
}
bool maptest(vec3 o,vec3 d,out float t,out vec3 p,out vec3 r,out vec4 c)
{
	r0=o;rd=d;
	nt=9999999.;
	//scene start
	//addtri(vec3(0.,0.,0.),vec3(1.,1.,0.),vec3(0.,1.,0.));
	scene1();
	//scene end
	if(nt<9999999.)
	{
		t=nt;
		p=np;
		r=nr;
		c=ncol;
		return true;
	}
	return false;
}
vec4 maprender(vec3 o,vec3 d){
    d=normalize(d);
    const float IOR=1.52,DISPERSION=0.15,EPS=0.001;
    const bool USE_ALPHA_BLEND=false;
    vec3 L1=normalize(vec3(0.4,0.8,0.5));
    vec3 L2=normalize(vec3(-0.7,0.3,0.6));
    float f0=(IOR-1.)/(IOR+1.);
    f0*=f0;
    vec3 sum=vec3(0.);
    float remain=1.;
    for(int k=0;k<24;k++){
        float t;
        vec3 p,r;
        vec4 c;
        if(!maptest(o,d,t,p,r,c))break;
        vec3 N=normalize(r-d),R=normalize(r),glass=clamp(c.rgb,0.,1.);
        float nv=clamp(-dot(d,N),0.,1.);
        float F=f0+(1.-f0)*pow(1.-nv,5.);
        float rim=pow(1.-nv,3.);
        float s1=pow(max(dot(R,L1),0.),96.);
        float s2=pow(max(dot(R,L2),0.),128.);
        float shine=clamp(s1+s2*0.7,0.,1.);
        float coatA=clamp(0.025+0.38*F+0.22*rim+0.85*shine,0.,0.98);
        vec3 coat=mix(vec3(0.9,0.95,1.),glass,0.16);
        float tr;
        vec3 pr,rr;
        vec4 cr;
        if(maptest(p+R*EPS,R,tr,pr,rr,cr))coat=mix(coat,clamp(cr.rgb,0.,1.),0.35);

        float iorR=IOR-DISPERSION,iorG=IOR,iorB=IOR+DISPERSION;
        vec3 bodyColor0=mix(vec3(1.),glass,0.6);
        vec3 trans=bodyColor0*0.02;
        float bodyAr=0.02,bodyAg=0.02,bodyAb=0.02;
        float innerAr=0.,innerAg=0.,innerAb=0.;
        bool crossed=false;
        vec3 nextO=o,nextD=d;

        vec3 inR=refract(d,N,1./iorR);
        if(dot(inR,inR)>0.000001){
            float ti;
            vec3 pi,ri;
            vec4 ci;
            if(maptest(p+inR*EPS,inR,ti,pi,ri,ci)){
                vec3 Ni=normalize(ri-inR);
                float h=max(ti,0.)/(max(ti,0.)+2.);
                bodyAr=0.025+0.17*h;
                float tintR=mix(glass.r,clamp(ci.r,0.,1.),0.4);
                float bodyColorR=mix(1.,tintR,0.6);
                float fold=pow(1.-abs(dot(N,Ni)),2.);
                float b1=pow(max(dot(normalize(ri),L1),0.),52.);
                float b2=pow(max(dot(normalize(ri),L2),0.),76.);
                innerAr=clamp(0.18*fold+0.65*b1+0.45*b2,0.,0.75);
                float innerColorR=mix(1.,tintR,0.3);
                trans.r=innerColorR*innerAr+(1.-innerAr)*bodyColorR*bodyAr;
            }
        }

        vec3 inG=refract(d,N,1./iorG);
        if(dot(inG,inG)>0.000001){
            float ti;
            vec3 pi,ri;
            vec4 ci;
            if(maptest(p+inG*EPS,inG,ti,pi,ri,ci)){
                crossed=true;
                vec3 Ni=normalize(ri-inG);
                vec3 outG=refract(inG,Ni,iorG);
                if(dot(outG,outG)<0.000001)outG=inG;
                nextD=normalize(outG);
                nextO=pi+nextD*EPS;
                float h=max(ti,0.)/(max(ti,0.)+2.);
                bodyAg=0.025+0.17*h;
                float tintG=mix(glass.g,clamp(ci.g,0.,1.),0.4);
                float bodyColorG=mix(1.,tintG,0.6);
                float fold=pow(1.-abs(dot(N,Ni)),2.);
                float b1=pow(max(dot(normalize(ri),L1),0.),52.);
                float b2=pow(max(dot(normalize(ri),L2),0.),76.);
                innerAg=clamp(0.18*fold+0.65*b1+0.45*b2,0.,0.75);
                float innerColorG=mix(1.,tintG,0.3);
                trans.g=innerColorG*innerAg+(1.-innerAg)*bodyColorG*bodyAg;
            }
        }

        vec3 inB=refract(d,N,1./iorB);
        if(dot(inB,inB)>0.000001){
            float ti;
            vec3 pi,ri;
            vec4 ci;
            if(maptest(p+inB*EPS,inB,ti,pi,ri,ci)){
                vec3 Ni=normalize(ri-inB);
                float h=max(ti,0.)/(max(ti,0.)+2.);
                bodyAb=0.025+0.17*h;
                float tintB=mix(glass.b,clamp(ci.b,0.,1.),0.4);
                float bodyColorB=mix(1.,tintB,0.6);
                float fold=pow(1.-abs(dot(N,Ni)),2.);
                float b1=pow(max(dot(normalize(ri),L1),0.),52.);
                float b2=pow(max(dot(normalize(ri),L2),0.),76.);
                innerAb=clamp(0.18*fold+0.65*b1+0.45*b2,0.,0.75);
                float innerColorB=mix(1.,tintB,0.3);
                trans.b=innerColorB*innerAb+(1.-innerAb)*bodyColorB*bodyAb;
            }
        }

        float bodyA=(bodyAr+bodyAg+bodyAb)/3.;
        float innerA=(innerAr+innerAg+innerAb)/3.;
        float a=coatA+(1.-coatA)*(innerA+(1.-innerA)*bodyA);
        vec3 layer=coat*coatA+(1.-coatA)*trans;
        sum+=remain*layer;
        remain*=1.-a;
        if(!crossed||remain<0.01)break;
        o=nextO;
        d=nextD;
    }
    float alpha=clamp(1.-remain,0.,1.);
    return vec4(clamp(USE_ALPHA_BLEND?sum/max(alpha,0.0001):sum,0.,1.),alpha);
}
void main(void) {
    vec2 uv=gl_FragCoord.xy/resolution;
    vec2 m=mouse;
    vec2 bbuv=uv;
    uv-=vec2(.5);
    m-=vec2(.5);
    uv.x*=resolution.x/resolution.y;
    m.x*=resolution.x/resolution.y;
    const float fov=100.;
    const vec3 rup=vec3(0.,1.,0.);
    const vec3 forward=vec3(0.,0.,1.);
    const vec3 right=vec3(1.,0.,0.);
    const vec3 ray0=vec3(0.,0.,-2.);
    vec3 rayd=normalize(forward+2.*tan(radians(fov)*.5)*(uv.x*right+uv.y*rup));

    float w=time*.05;
    mat3 rm=roty(w+m.x*16.)*rotx(-m.y*8.);
    vec3 o=rm*ray0,d=rm*rayd;
    gl_FragColor=maprender(o,d);
}
