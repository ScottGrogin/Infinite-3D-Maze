import com.jogamp.newt.opengl.GLWindow;
GLWindow r;
PShader shader;
PGraphics pg;
int pgW = 640;
int pgH = 480;
float px = 141, py = -0., pz = -49.5, camXDelta = 90, speed = 0.15, pi = 3.14, collisionRadius = 0.2;

boolean up = false, down = false, left = false, right = false, w = false, a = false, s = false, d = false, sh = false;


float posX = 100;
float posY = 100;
boolean Lock = false;
int offsetX = 0;
int offsetY = 0;

float Sensitivity = 0.2;

//Basic math functions designed to function like in GLSL
//so that we can get map collision working correctly.
float maxi(float x, float y) {
  if (y>x) {
    return y;
  } else {
    return x;
  }
}
float mini(float x, float y) {
  if (y<x) {
    return y;
  } else {
    return x;
  }
}
float fracti(float num) {
  return num-floor(num);
}
float clampi(float x, float minVal, float maxVal) {
  return  mini(maxi(x, minVal), maxVal);
}
float smoothstepi(float edge0, float edge1, float x) {
  float t = clampi((x - edge0) / (edge1 - edge0), 0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}


//Hash 2-1 function for pseudo random values that match those
//in GLSL
float hash(float x, float y) {
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

//Define the bounds of the maze
float maze(float x, float y) {
  float x1 = x, y1 = y;
  x = x1*0.707 - y1*0.707;
  y = x1*0.707 + y1*0.707;

  x *= 0.1;
  y *= 0.1;

  float idx = floor(x);
  float idy = floor(y);


  x = fracti(x)-0.5;
  y = fracti(y)-0.5;

  float rnd = hash(idx, idy);


  if (rnd < 0.5) {

    x *= -1.;
  }

  float preT = 0.38;
  float thickness = 0.39;

  float col = mini(smoothstepi(preT, thickness, abs((x+y)-0.5)), 
    smoothstepi(preT, thickness, abs((x+y)+0.5)));
  return col;
}

void setup() {
  r = (GLWindow)surface.getNative(); 
  size(800, 600, P2D);
  pg = createGraphics(pgW, pgH, P2D);
  surface.setResizable(true); 
  shader = loadShader("frag.glsl");
}

void draw() {
  if (Lock) {
    posX += (mouseX-offsetX-width/2)*Sensitivity; 
    posY += (mouseY-offsetY-height/2)*Sensitivity;
  } 
  camXDelta=-posX;
  if (w) {
    px += cos((camXDelta+90)*pi/180.0)*speed;
    pz += sin((camXDelta+90)*pi/180.0)*speed;
  }

  if (s) {
    px -=cos ((camXDelta+90)*pi/180.0)*speed;
    pz -=sin ((camXDelta+90)*pi/180.0)*speed;
  }
  if (a) {
    px -= cos((camXDelta)*pi/180.0)*speed;
    pz -= sin((camXDelta)*pi/180.0)*speed;
  }
  if (d) {
    px += cos((camXDelta)*pi/180.0)*speed; 
    pz += sin((camXDelta)*pi/180.0)*speed;
  }

  float largestCollision= 1.- maze(px, pz);
  float cpX = 0, cpZ = 0;
  for (float i = 0; i<360; i+=0.2) {
    float ang = (i)*pi/180.;
    float pos = 1.-maze(px+cos(ang)*collisionRadius, pz+sin(ang)*collisionRadius);
    if (pos>largestCollision) {
      cpX = px+cos(ang)*collisionRadius;
      cpZ = pz+sin(ang)*collisionRadius;
      largestCollision = pos;
    }
  }

  while (largestCollision>0.01) {
    px += ((px-cpX))*(speed*largestCollision);
    pz += ((pz-cpZ))*(speed*largestCollision);
    largestCollision= 0.;
    for (float i = 0; i<360; i+=0.2) {
      float ang = (i)*pi/180.;
      float pos = 1.-maze(px+cos(ang)*collisionRadius, pz+sin(ang)*collisionRadius);
      if (pos>largestCollision) {
        cpX = px+cos(ang)*collisionRadius;
        cpZ = pz+sin(ang)*collisionRadius;
        largestCollision = pos;
      }
    }
  }
  if (right)camXDelta--;
  if (left)camXDelta++;
  shader.set("iResolution", float(width), float(height));
  shader.set("iTime", millis() / 1000.0);
  shader.set("PX", px);
  shader.set("PY", py);
  shader.set("PZ", pz);
  shader.set("camX", camXDelta);
  pg.shader(shader);
  pg.rect(0, 0, width, height);
  image(pg, 0, 0, width, height);

  //Center Pointer
  if (Lock) {
    offsetX=offsetY=0;
    r.setPointerVisible(false); 
    r.warpPointer(width/2, height/2); 
    r.confinePointer(true);
  } else {
    r.confinePointer(false); 
    r.setPointerVisible(true);
  }
}


void keyPressed() {
  if (key =='w') {
    w = true;
  }
  if (key =='s') {
    s = true;
  }
  if (key =='a') {
    a = true;
  }
  if (key =='d') {
    d = true;
  }
  if (key == CODED) {
    if (keyCode == SHIFT) {
      sh=true;
    }
    if (keyCode == UP) {
      up = true;
    } 
    if (keyCode == DOWN) {
      down = true;
    } 
    if (keyCode == LEFT) {
      left = true;
    } 
    if (keyCode == RIGHT) {
      right = true;
    }
  }
}

void keyReleased() {
  if (key =='w') {
    w = false;
  }
  if (key =='s') {
    s = false;
  }
  if (key =='a') {
    a = false;
  }
  if (key =='d') {
    d = false;
  }
  if (key == CODED) {
    if (keyCode == SHIFT) {
      sh=false;
    }
    if (keyCode == UP) {
      up = false;
    } 

    if (keyCode == DOWN) {
      down = false;
    } 
    if (keyCode == LEFT) {
      left = false;
    } 
    if (keyCode == RIGHT) {
      right = false;
    }
  }
}
void mousePressed() {
  Lock =! Lock;
  if (Lock) {
    offsetX = mouseX-width/2; 
    offsetY = mouseY-height/2;
  } else {
    r.warpPointer(round(posX), round(posY));
  }
}
