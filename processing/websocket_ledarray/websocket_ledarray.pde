import websockets.*;
import java.util.Map;
WebsocketClient socket;
float[][][] sentPixels;
PFont myfont;
import gifAnimation.*;
Gif loopingGif;
Gif nyanGif;
int rndScl = 10;
PImage[] animation;
import http.requests.*;
JSONObject json;

void setup() {
  PostRequest post = new PostRequest("https://www.strava.com/api/v3/oauth/token");
  post.addData("client_id", "93677");
  post.addData("client_secret", "97e1deaece2d915d09f7e6fc5a1380e8359300f2");
  post.addData("refresh_token", "c2d3ad2b56d75e5a3df956872a886502cd568f8b");
  post.addData("grant_type", "refresh_token");
  post.send();
  String ji = post.getContent();
  println(ji);
  json = parseJSONObject(ji);
  
  println(json);
  initFontb();
  myfont = createFont("Roboto-Regular", 64);
  frameRate(50);
  size(64, 32);
  rndScl = width / 64;
  background(0);
  try {
    socket = new WebsocketClient(this, "ws://localhost:4000/socket.io/?EIO=3&transport=websocket");
  }
  catch (Exception e) {
    println(e);
  }

  sentPixels = new float[64][32][3];
  for (int i = 0; i<64; i++) {
    for (int j = 0; j<32; j++) {
      sentPixels[i][j][0] = 1.0;
      sentPixels[i][j][1] = 1.0;
      sentPixels[i][j][2] = 1.0;
    }
  }

  loopingGif = new Gif(this, "https://meteo.arso.gov.si/uploads/probase/www/observ/radar/si0-rm-anim.gif");
  
  //nyanGif = new Gif(this, "https://i0.wp.com/www.printmag.com/wp-content/uploads/2021/02/4cbe8d_f1ed2800a49649848102c68fc5a66e53mv2.gif");
  nyanGif = new Gif(this, "./loop.gif");
  loopingGif.loop();
  
 nyanGif.loop();
  animation = Gif.getPImages(this, "https://meteo.arso.gov.si/uploads/probase/www/observ/radar/si0-rm-anim.gif");
  println(animation.length);
}

void draw() {
  weatherGif();
  nyanGif();
  //background(140);
  int delim = 1;
  if(mousePressed == true){
    delim = 5;
  }
  if (frameCount % delim == 0) {
    emitPixels();
  }
}

float maxDiff = 0;

float[][][] writeToSend() {
  float [][][]toSend = new float[32][64][3];
  for (int j = 0; j < 32; j++) {
    for (int i = 0; i<64; i++) {

      float r = 0;
      float g = 0;
      float b = 0;

      color c = get(i * rndScl, j * rndScl);
      float cr = red(c);
      float cg = green(c);
      float cb = blue(c);

      r = cr/1;
      g = cg/1;
      b = cb/1;

      toSend[j][i][0] = r;
      toSend[j][i][1] = g;
      toSend[j][i][2] = b;
    }
  }
  return toSend;
}

void emitPixels() {
  loadPixels();
  float[][][] toSend;
  toSend = writeToSend();


  String[] jsonmessage = {};
  for (int j = 0; j<32; j++) {
    int lastDiff = -1;
    int firstDiff = -1;
    for (int i = 0; i<64; i++) {
      boolean diff = false;
      float r = toSend[j][i][0];
      float g = toSend[j][i][1];
      float b = toSend[j][i][2];

      if ( sentPixels[i][j][0] != r ||
        sentPixels[i][j][1] != g ||
        sentPixels[i][j][2] != b ) {
        diff = true;
      }
      if (diff) {
        lastDiff = i;
        if (firstDiff == -1) {
          firstDiff = i;
        }
      }
    }
    
    if(j == 31 && jsonmessage.length == 0){
    firstDiff = 0;
    lastDiff = 1;
    }

    if (firstDiff >= 0) {
      String strmessage = "";
      strmessage += hex(j, 2);
      strmessage += hex(firstDiff, 2);
      for (int i = firstDiff; i<=lastDiff; i++) {
        float r = toSend[j][i][0];
        float g = toSend[j][i][1];
        float b = toSend[j][i][2];
        strmessage += hex(int(r), 2) + hex(int(g), 2)+ hex(int(b), 2);
        sentPixels[i][j][0] = r;
        sentPixels[i][j][1] = g;
        sentPixels[i][j][2] = b;
      }
      if(strmessage.length() > 0){
        jsonmessage = append(jsonmessage, strmessage);
      }
      
    }
  }
  if (jsonmessage.length > 0) {
    String sendBuff = arraytoJson(jsonmessage);
    sendPixels(sendBuff);
  }
}

void sendPixels(String sendBuff) {
  try {
    String msg = "42[\"pixelsp\",{\"msg\":\""+sendBuff+"\"}]";
    socket.sendMessage(msg);
  }
  catch (Exception e) {
    println(e);
    try {
      socket = new WebsocketClient(this, "ws://localhost:4000/socket.io/?EIO=3&transport=websocket");
    }
    catch (Exception ee) {
      println(ee);
    }
  }
}


String arraytoJson(String[] in) {
  String res = "";
  if (in.length == 0) {
    return res;
  }
  res += "[";
  for (int i = 0; i<in.length; i++) {
    res += "'";
    res += in[i];
    res += "'";
    if ( i + 1 < in.length) {
      res += ",";
    }
  }
  res += "]";
  return res;
}





void webSocketEvent(String msg) {
  println("- " + msg);
}

int weatherPrevMinutes = 0;
int ljBr = 150;
int ind = 0;
void weatherGif() {
  image(loopingGif, -19*rndScl, -19*rndScl, 111*rndScl, 65*rndScl);
  stroke(255, 255, 255);
  stroke(255, 255, 255, 255);
  ljBr = abs(millis()%10200 - 5100);
  ljBr /= 20;


  for (int i = 0; i<rndScl; i++) {
    for (int j = 0; j<rndScl; j++) {
      int x = 31 * rndScl;
      x+= i;
      int y = 15 * rndScl;
      y += j;
      color d = color(abs(ljBr));
      set(x, y, d);
    }
  }
  
  drawClock(0);


  if (minute() != weatherPrevMinutes) {
    loopingGif = new Gif(this, "https://meteo.arso.gov.si/uploads/probase/www/observ/radar/si0-rm-anim.gif");
    
    loopingGif.loop();

    animation = Gif.getPImages(this, "https://meteo.arso.gov.si/uploads/probase/www/observ/radar/si0-rm-anim.gif");

    weatherPrevMinutes = minute();
    println("UPDATED");
  }
}

void nyanGif() {
  float hn = 60;
  float wn = hn * 1.7;
  float xn = (32 - hn) / 2;
  float yn = (64- wn) / 2;
  
  image(nyanGif, yn, xn,  wn, hn);
  drawClock(255);
}

void drawClock(int br) {
  String prt = hour() +"";
  if (second()%2 == 0) {
    prt+=":";
  } else {
    prt+=":";
  }
  if (minute() < 10) {
    prt += "0";
  }
  prt += minute();
  stroke(255);
  fill(255);
  //rect(0,24,21,32);
  //background(0);
  drawString(prt, 0, 24, color(br));
  //drawString(str(ljBr), 1, 1, color(50));
  /*for (int i = 0; i<ljBr; i++) {
   if (i> 31) {
   set(46, 63 - i, color(200,200-i,i));
   }
   if (i > 63) {
   set(47, i - 64, color(200,200-i,i));
   }
   if (i> 95) {
   set(48, 128 - i, color(200,200-i,i));
   }
   if (i> 127) {
   set(49, i-128, color(200,200-i,i));
   }
   set(45, i, color(200,200-i,i));
   }*/


  /*for (int i = 0; i<32; i++) {
    for (int j = 0; j<32; j++) {
      int x = j * 2;
      int y = i * 2;
      set(x,y, color(i * 8, j * 8, ljBr));
    }
  }*/






  //drawString(str(millis()), 1, 10, color(0));
}
