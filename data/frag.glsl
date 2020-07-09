#ifdef GL_ES
//precision lowp float;
//precision lowp int;
#endif

#define PROCESSING_COLOR_SHADER

uniform vec2 iResolution;
uniform float iTime;
uniform float PX;
uniform float PY;
uniform float PZ;


uniform float camX;

int matId = 0;

float pi = 3.14;

mat2 rot(float a){
    return mat2(cos(a),-sin(a),sin(a),cos(a));
}


float maxi(float x,float y){
  if(y > x){
    return y;
  } else {
    return x;
  }
}
float mini(float x,float y){
  if(y < x){
    return y;
  }else{
    return x;
  }
}
float fracti(float num){
  return num-floor(num);
}
float clampi(float x, float minVal, float maxVal){
  return  mini(maxi(x, minVal), maxVal);
}
float smoothstepi(float edge0,float edge1,float x){
  float t = clampi((x - edge0) / (edge1 - edge0), 0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}


float hash(float x, float y){
  x = fracti(x*125.4);
  y = fracti(y*567.8);
  float x2 = x+91.0;
  float y2 = y+90.0;
  float x3 = x*x2;
  float y3 = y*y2;
  x += x3+y3;
  y += x3+y3;
  return fracti(x*y);
}

float maze(float x,float y){
  float x1 = x,y1 = y;
   x = x1*0.707 - y1*0.707;
   y = x1*0.707 + y1*0.707;
  
  x *= 0.1;
  y *= 0.1;
  
  float idx = floor(x);
  float idy = floor(y);
  
  
  x = fracti(x)-0.5;
  y = fracti(y)-0.5;
  
  float rnd = hash(idx,idy);
  
  if(rnd < 0.5){
    x *= -1.;
  }
   
  float preT = 0.2;
   float thickness = 0.39;
  
  float col = mini(smoothstepi(preT,thickness,abs((x+y)-0.5)),
                   smoothstepi(preT,thickness,abs((x+y)+0.5)));
  return col;
}
float map(vec3 p,vec2 uv){
    return min(p.y-0.3+maze(p.x,p.z),-p.y-0.3+maze(p.x,p.z)); 
}
vec3 normal(vec3 p){
    vec2 e = vec2(0,0.01);
    vec2 uv = vec2(0);
    return normalize(vec3(map(p+e.yxx,uv)-map(p-e.yxx,uv),
                          map(p+e.xyx,uv)-map(p-e.xyx,uv),
                          map(p+e.xxy,uv)-map(p-e.xxy,uv)));
}

float trace(vec3 ro,vec3 rd,vec2 uv){
    float tot = 0.0;
    float dst = 0.;
    for(int i = 0; i < 1000; ++i){
        dst = map(ro+rd*tot,uv);
        tot += dst;
        if(dst<0.001 ){
           tot = float(i)/800.;
            break;
        }
    }
    if(dst > 0.001)matId = 1;
    return tot;
}
void main() {
    vec2 uv = (gl_FragCoord.st-0.5*iResolution)/iResolution.x;
    vec3 ro = vec3(PX,PY,PZ);  
    vec3 rd = normalize(vec3(uv,1));

  
    float colide = 1.-maze(PX,PZ);

    rd.xz *= rot(camX*pi/180.);
    vec3 p = vec3(trace(ro,rd,uv));
    vec3 crsH = step(0.002,vec3(length(uv)));
    vec3 col = vec3(0);
  
    if(crsH == vec3(0)){
       if(colide >0.){col = vec3(1,0,1);}
       else{col = vec3(1,0,0);}
        
    } else{
        col = p*vec3(1,0,0);
    }
    
    //Mini Map
    vec2 st = uv+vec2(-0.3,-0.2);
    st *= rot(camX*pi/180.);
    if(uv.x>0.1 &&uv.y>0.1){
        vec3 mMap = vec3(maze(ro.x+(st.x/0.005),ro.z+(st.y/0.005)));
    	col *= mix(1.-mMap,1.-vec3(1,1,1),0);
        if(col == vec3(0)){
            col = (1.-p)*vec3(1,0.7,0.7);
        }
        col *= step(0.002,vec3(length(st)));
    }
    gl_FragColor = vec4(pow(col, vec3(1./2.2)),1.);
}
