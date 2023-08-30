import websockets.*;
import java.util.Map;
WebsocketClient socket;
float[][][] sentPixels;
PFont myfont;
import gifAnimation.*;
Gif loopingGif;
int rndScl = 10;
PImage[] animation;


void setup() {
  initFontb();
  String[] fontList = PFont.list();
  printArray(fontList);
  myfont = createFont("Roboto-Regular", 64);
  frameRate(24);
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
  loopingGif.loop();
  animation = Gif.getPImages(this, "https://meteo.arso.gov.si/uploads/probase/www/observ/radar/si0-rm-anim.gif");
  println(animation.length);
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

      r = cr/3;
      g = cg/3;
      b = cb/3;

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

      jsonmessage = append(jsonmessage, strmessage);
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



void draw() {
  weatherGif();
  drawClock();

  if (frameCount % 1 == 0) {
    emitPixels();
  }
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
  ljBr-=5;
  if (ljBr <= -150) {
    ljBr = 150;
  }


  if (minute() != weatherPrevMinutes) {
    loopingGif = new Gif(this, "https://meteo.arso.gov.si/uploads/probase/www/observ/radar/si0-rm-anim.gif");
    loopingGif.loop();

    animation = Gif.getPImages(this, "https://meteo.arso.gov.si/uploads/probase/www/observ/radar/si0-rm-anim.gif");

    weatherPrevMinutes = minute();
    println("UPDATED");
  }
}

void drawClock() {
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
  drawString(prt, 0, 24, color(0));
  //drawString("bla.bla.blablalbal.balbalalb.labla", 1, 1, color(0));
  //drawString(str(millis()), 1, 10, color(0));
}
