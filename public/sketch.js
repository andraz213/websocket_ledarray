let socket;

let pixels = [];
function setup(){
  frameRate(60);
  createCanvas(640, 320);
  background(0);
  console.log(getURL());
  socket = io.connect(getURL());

  for(let i = 0; i<64; i++){
    pixels.push([]);
    for(let j = 0; j<32; j++){
      pixels[i].push(0);
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
      ellipse(i * 10 + 5, j * 10 + 5, 8, 8);
      pixels[i][j].r = updatePixel(pixels[i][j].r);
      pixels[i][j].g = updatePixel(pixels[i][j].g);
      pixels[i][j].b = updatePixel(pixels[i][j].b);
      }
    }
  }
}

let maxDiff = 0;
function emitPixels(){
  let strmessage = "";
  let message = [];
  for(let i = 0; i<64; i++) {
    for (let j = 0; j < 32; j++) {
      let pixel = pixels[i][j];
      if(pixel.r + pixel.g + pixel.b  >= 0) {

        message.push({
          x: i,
          y: j,
          color: {r: int(pixels[i][j].r),g:int(pixels[i][j].g),b:int(pixels[i][j].b)}
        });

        strmessage += hex(i*32 + j, 3)  + hex(int(pixels[i][j].r), 2) + hex(int(pixels[i][j].g), 2)+ hex(int(pixels[i][j].b), 2);


      }


    }
  }
  if(message.length > 0){
    socket.emit('pixels', strmessage);


    let diff = (JSON.stringify(message).length - strmessage.length) / strmessage.length;

    if(maxDiff < diff){
      maxDiff = diff;
    }
    console.log("maxDiff", maxDiff);
    //console.log(JSON.stringify(message).length  + " - " + strmessage.length + " = " + (JSON.stringify(message).length - strmessage.length));
  }

}



function draw(){
  //console.log(frameRate());
  checkMouse();
  drawPixels();
  if(frameCount % 2 == 0){
    emitPixels();
  }

  socket.on('pixels', (data) => {
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
  });

}