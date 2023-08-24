let socket;
let img;
let sentPixels = [];
let pixels = [];

function preload(){
  img = loadImage('fuji.jpg');
}
function setup(){
  frameRate(60);
  createCanvas(640, 320);
  background(0);
  console.log(getURL());
  socket = io.connect(getURL());

  for(let i = 0; i<64; i++){
    sentPixels.push([]);
    pixels.push([]);
    for(let j = 0; j<32; j++){
      sentPixels[i].push({r: 0, g: 0, b: 0});
      pixels[i].push({r: 0, g: 0, b: 0});
    }
  }

}


function checkMouse(){
  let x = floor(mouseX/10);
  let y = floor(mouseY/10);

  if(x >= 0 && x < 64 && y >= 0 && y < 32){
    pixels[x][y] = {r: random(255), g: random(255), b: random(255)};
  }
}

function updatePixel(v){
  v = v - max(v*0.05, 3);
  if(v < 0){
    v = 0;
  }
  return v;

}

function drawPixels(){
  for(let i = 0; i<64; i++){
    for(let j = 0; j<32; j++){
      let pixel = pixels[i][j];
      if(pixel.r + pixel.g + pixel.b >= 1) {

      fill(pixels[i][j].r,pixels[i][j].g,pixels[i][j].b);
      noStroke();
      rect(i * 10, j * 10, 10, 10);
      pixels[i][j].r = updatePixel(pixels[i][j].r);
      pixels[i][j].g = updatePixel(pixels[i][j].g);
      pixels[i][j].b = updatePixel(pixels[i][j].b);
      }
    }
  }
}

let maxDiff = 0;

function emitPixels(limit){
  let sendedLen = 0;
  let toSend = [];
  let message = [];
  let start = millis();
  let strmessage = "";
  for (let j = 0; j < 32; j++) {
    toSend.push([]);
    for(let i = 0; i<64; i++) {

      let r = 0;
      let g = 0;
      let b = 0;
      let max = 0;
      for(let k = 0; k < 10; k+=5){
        for(let m = 0; m < 10; m+=5){
          let x = i * 10 + k;
          let y = j * 10 + m;
          let c = get(x,y);
          /*r += c[0];
          g += c[1];
          b += c[2];*/

          if(c[0] + c[1] + c[2] > max){
            max = c[0] + c[1] + c[2];
            r = c[0];
            g = c[1];
            b = c[2];
          }
        }
      }
      r = floor(r/4);
      g = floor(g/4);
      b = floor(b/4);

      toSend[j].push({r: r, g: g, b: b});
    }
  }


  let toSendLen =0;
  let jsonmessage = [];
  for(let j = 0; j<32; j++){
    let diff = 0;
    let lastDiff = -1;
    let firstDiff = -1;
    for(let i = 0; i<64; i++){
      let r = toSend[j][i].r;
      let g = toSend[j][i].g;
      let b = toSend[j][i].b;

      diff = abs(sentPixels[i][j].r - r) + abs(sentPixels[i][j].g - g) + abs(sentPixels[i][j].b - b);
      if(diff > 0){
        lastDiff = i;
        if(firstDiff < 0){
          firstDiff = i;
        }
      }
    }


    if(firstDiff >= 0){
      let strmessage = "";
      strmessage += hex(j, 2);
      strmessage += hex(firstDiff, 2);
      for(let i = firstDiff; i<=lastDiff; i++){
        let r = toSend[j][i].r;
        let g = toSend[j][i].g;
        let b = toSend[j][i].b;
        strmessage += hex(int(r), 2) + hex(int(g), 2)+ hex(int(b), 2);
        sentPixels[i][j].r = r;
        sentPixels[i][j].g = g;
        sentPixels[i][j].b = b;
      }

      jsonmessage.push(strmessage);

      if(jsonmessage.toString().length > limit) {
        console.log(jsonmessage.toString().length);
        sendedLen += jsonmessage.toString().length;
        socket.emit('pixels', jsonmessage);
        jsonmessage = [];
        if(sendedLen > limit){
          return sendedLen;
        }

      }
    }
  }

  if(jsonmessage.toString().length > 0) {
    console.log(jsonmessage.toString().length);
    sendedLen += jsonmessage.toString().length;
    socket.emit('pixels', jsonmessage);
    jsonmessage = [];

  }
  let stop = millis();
  console.log("time", stop - start);
  return sendedLen;

}


let prevSend = 0;
function draw(){
  fill(125);
  textSize(128);
  //text('ljubim te', 50, 200);

  image(img, 0, 0, 640, 320);
  //console.log(frameRate());
  checkMouse();
  drawPixels();
  if(frameCount % 2 == 0){
    let start = millis();
    prevSend *= 0.9;
    prevSend += emitPixels(2000 - prevSend);
    let stop = millis();
    console.log("time emitting:", stop - start);
  }

  socket.on('pixels', (data) => {
    let start = millis();
    //console.log("got data", data.length);
    for(let i = 0; i<data.length; i++){

      let currentData = data[i];

      let row = unhex(currentData[i] + currentData[i+1]);
      let start = unhex(currentData[i+2] + currentData[i+3]);

      let y = 0;
      for(let j = 4; j<currentData.length; j+=6){


        let r = unhex(currentData[j] + currentData[j+1]);
        let g = unhex(currentData[j+2] + currentData[j+3]);
        let b = unhex(currentData[j+4] + currentData[j+5]);
        //console.log("color", pixel);

        fill(r,g,b);
        noStroke();
        rect(y*10, row * 10, 10, 10);
        y++;
      }
      }

    let stop = millis();
    console.log("time", stop - start);
    console.log("datalen", data.length);
    console.log("data", data);
    console.log("....................................................");
  });

}