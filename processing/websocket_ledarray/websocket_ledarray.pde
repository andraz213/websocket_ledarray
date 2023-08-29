import websockets.*;
WebsocketClient socket;
PImage img; 
float[][][] sentPixels;
float[][][] cur_pixels;
PFont myfont;
import gifAnimation.*;
Gif loopingGif;
int rndScl = 1;
int w = 64;
int h = 32;


void setup(){
  String[] fontList = PFont.list();
  printArray(fontList);
  myfont = createFont("Roboto-Regular", 64);
  img = loadImage("back.png");
  frameRate(60);
  size(64, 32);
  background(0);
  socket = new WebsocketClient(this, "ws://localhost:4000/socket.io/?EIO=3&transport=websocket");
  
  sentPixels = new float[64][32][3];
  cur_pixels = new float[64][32][3];
  for(int i = 0; i<64; i++){
    for(int j = 0; j<32; j++){
      sentPixels[i][j][0] = 1.0;
      sentPixels[i][j][1] = 1.0;
      sentPixels[i][j][2] = 1.0;
      
      cur_pixels[i][j][0] = 0.0;
      cur_pixels[i][j][1] = 0.0;
      cur_pixels[i][j][2] = 0.0;
    }
  }
  
  loopingGif = new Gif(this, "https://meteo.arso.gov.si/uploads/probase/www/observ/radar/si0-rm-anim.gif");
  loopingGif.loop();
}


void checkMouse(){
  int x = floor(mouseX/10);
  int y = floor(mouseY/10);

  if(x >= 0.0 && x < 64.0 && y >= 0.0 && y < 32.0){
    
    cur_pixels[x][y][0] = random(5);
    cur_pixels[x][y][1] = random(5);
    cur_pixels[x][y][2] = random(5);
  }
}

float updatePixel(float v){
  v = v - max(v*0.05, 3);
  if(v < 0){
    v = 0;
  }
  return v;

}

void drawPixels(){
  for(int i = 0; i<64; i++){
    for(int j = 0; j<32; j++){
      float r = cur_pixels[i][j][0];
      float g = cur_pixels[i][j][1];
      float b = cur_pixels[i][j][2];
      
      
      if(r + g + b >= 1) {

      fill(r, g, b);
      noStroke();
      rect(i * 10, j * 10, 10, 10);
      cur_pixels[i][j][0] = updatePixel(cur_pixels[i][j][0]);
      cur_pixels[i][j][1] = updatePixel(cur_pixels[i][j][1]);
      cur_pixels[i][j][2] = updatePixel(cur_pixels[i][j][2]);
      }
    }
  }
}

float maxDiff = 0;

int emitPixels(int limit){
  loadPixels();
  int sendedLen = 0;
  float[][][] toSend;
  toSend = new float[32][64][3];
  long start = millis();
  for (int j = 0; j < 32; j++) {
    for(int i = 0; i<64; i++) {

      float r = 0;
      float g = 0;
      float b = 0;
      float max = 0;
      /*for(int k = 0; k < 10; k++){
        for(int m = 0; m < 10; m++){
          int x = i * 10 + k;
          int y = j * 10 + m;
          color c = get(x,y);
          float cr = red(c);
          float cg = green(c);
          float cb = blue(c);
           
  
           r += cr;
           g += cg;
           b += cb;
        }
      }*/
      
      color c = get(i * rndScl,j * rndScl);
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


  int toSendLen =0;
  String[] jsonmessage = {};
  for(int j = 0; j<32; j++){
    int lastDiff = -1;
    int firstDiff = -1;
    for(int i = 0; i<64; i++){
      boolean diff = false;
      float r = toSend[j][i][0];
      float g = toSend[j][i][1];
      float b = toSend[j][i][2];
      
      if(sentPixels[i][j][0] != r){
        diff = true;
      }
      
            if(sentPixels[i][j][1] != g){
        diff = true;
      }
      
            if(sentPixels[i][j][2] != b){
        diff = true;
      }
      

      if(diff){
        lastDiff = i;
        if(firstDiff == -1){
          firstDiff = i;
        }
      }
    }
   


    if(firstDiff >= 0){
          //println("firstDiff", firstDiff);
      //println("lastDiff", lastDiff);
      String strmessage = "";
      strmessage += hex(j, 2);
      strmessage += hex(firstDiff, 2);
      for(int i = firstDiff; i<=lastDiff; i++){
      float r = toSend[j][i][0];
      float g = toSend[j][i][1];
      float b = toSend[j][i][2];
        strmessage += hex(int(r), 2) + hex(int(g), 2)+ hex(int(b), 2);
        sentPixels[i][j][0] = r;
        sentPixels[i][j][1] = g;
        sentPixels[i][j][2] = b;
      }

      jsonmessage = append(jsonmessage, strmessage);
      
      String sendBuff = arraytoJson(jsonmessage);
      if(sendBuff.length() > limit) {
        //println(sendBuff.length());
        sendedLen += sendBuff.length();
      try{
        String msg = "42[\"pixelsp\",{\"msg\":\""+sendBuff+"\"}]";
        //println("sending: ",msg.length());
        socket.sendMessage(msg);
        }catch (Exception e){
      println(e);
    }
        //socket.emit('pixels', jsonmessage);
        while(jsonmessage.length > 0){
          jsonmessage = shorten(jsonmessage);
        }
        if(sendedLen > limit){
          return sendedLen;
        }

      }
    }
  }
  
  String sendBuff = arraytoJson(jsonmessage);
      if(sendBuff.length() > 0) {
        //println(sendBuff.length());
        sendedLen += sendBuff.length();
      try{
        String msg = "42[\"pixelsp\",{\"msg\":\""+sendBuff+"\"}]";
        //println("sending: ",msg.length());
        socket.sendMessage(msg);
        }catch (Exception e){
      println(e);
    }
        //socket.emit('pixels', jsonmessage);
        while(jsonmessage.length > 0){
          jsonmessage = shorten(jsonmessage);
        }
        if(sendedLen > limit){
          return sendedLen;
        }

  }
  long stop = millis();
  //println("time", stop - start);
  //println("sendedLen", sendedLen);
  return sendedLen;

}


String arraytoJson(String[] in){
  String res = "";
   if(in.length == 0){
     return res;
   }
    
    res += "[";
  
  for(int i = 0; i<in.length;i++){
    res += "'";
    res += in[i];
    res += "'";
    if( i + 1 < in.length){
      res += ",";
    }
  }
  
  res += "]";
return res;


}


int prevSend = 0;
void draw(){
    weatherGif();
  fill(50,20,50);
  textFont(myfont, 128);
  textSize(11*rndScl);
  //background(0);
  String prt = hour() +"";
  if(second()%2 == 0){
  prt+=":";
  } else{
    prt+=":";
  }
  if(minute() < 10){
  prt += "0";
  }
  prt += minute();
  
  text(prt, 1*rndScl, 30*rndScl);


  //image(img, 0, 0, 64, 32);
  //console.log(frameRate());
  //checkMouse();
  //drawPixels();
  if(frameCount % 1 == 0){
    long start = millis();
    prevSend *= 0.9;
    prevSend += emitPixels(20000 - prevSend);
    long stop = millis();
    //println("time emitting:", stop - start);
  }

  /*socket.on('pixels', (data) => {
    let start = millis();
    //console.log("got data", data.length);
    for(let i = 0; i<data.length; i+= 9){

      let index = unhex(data[i] + data[i+1] + data[i+2]);
      let x = floor(index/32);
      let y = index % 32;
      let r = unhex(data[i+3] + data[i+4]);
      let g = unhex(data[i+5] + data[i+6]);
      let b = unhex(data[i+7] + data[i+8]);
      //console.log("color", pixel);

        fill(r,g,b);
        noStroke();
        ellipse(x * 10 + 5, y * 10 + 5, 8, 8);
      //console.log("drawing", pixel.x, pixel.y, pixel.color);
      }

    let stop = millis();
    console.log("time", stop - start);
    console.log("data", data.length);
    console.log("....................................................");
  });*/

}

void webSocketEvent(String msg){
 println("- " + msg);
  if(msg.length() >= 3){
    String numKey = msg.substring(0,2);
    String stringJson = msg.substring(2,msg.length());
    if(numKey.equals("42") ){
      String[] result = stringJson.split("\"");
      String[] result2 = stringJson.split(",");
      String method = result[1];
      
      String allValues = "";
      for(int i = 1; i < result2.length ; i++){
        if(allValues.equals(""))
          allValues = result2[i];
        else
          allValues = allValues +","+ result2[i];
      }
      allValues = allValues.substring(0,allValues.length()-1); //remove the ] at the end
      stringJson = "{\"method\":\""+method+"\",\"value\":"+allValues+"}";
      
      JSONObject json = parseJSONObject(stringJson);
      println(json);
      //processJson(json); //Process the JSON object somewhere else to do some magic with it
    }
  }
}





int weatherPrevMinutes = 0;
int ljBr = 255;
void weatherGif(){
  image(loopingGif, -19*rndScl, -17*rndScl, 110*rndScl, 62*rndScl);
  stroke(255,255,255);
  stroke(255,255,255, 255);
      for(int i = 0;i<rndScl; i++){
        for(int j = 0;j<rndScl; j++){
          int x = 31 * rndScl;
            x+= i;
              int y = 15 * rndScl;
                y += j; 
                  
                  float cr = abs(ljBr);
                  float cb = abs(ljBr);
                  float cg = abs(ljBr);
     
          color d = color(cr,cg,cb);
      set(x, y, d);
    }
  }
  ljBr-=5;
  if(ljBr <= -255){
   ljBr = 255;
  }
  

  if(minute() != weatherPrevMinutes){
      loopingGif = new Gif(this, "https://meteo.arso.gov.si/uploads/probase/www/observ/radar/si0-rm-anim.gif");
  loopingGif.loop();
  weatherPrevMinutes = minute();
  println("UPDATED");
  }


}
