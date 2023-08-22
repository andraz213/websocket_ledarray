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

function emitPixels(){

  let message = [];
  for(let i = 0; i<64; i++) {
    for (let j = 0; j < 32; j++) {
      let pixel = pixels[i][j];
      if(pixel.r + pixel.g + pixel.b  >= 1) {

        message.push({
          x: i,
          y: j,
          color: {r: int(pixels[i][j].r),g:int(pixels[i][j].g),b:int(pixels[i][j].b)}
        });
      }


    }
  }
  if(message.length > 0){
    socket.emit('pixels', message);
    //console.log(JSON.stringify(message).length);
  }

}



function draw(){
  console.log(frameRate());
  checkMouse();
  drawPixels();
  if(frameCount % 2 == 0){
    emitPixels();
  }

  socket.on('pixels', (data) => {
    //console.log("got data", data.length);
    for(let i = 0; i<data.length; i++){

      let pixel = data[i];
      //console.log("color", pixel.color);

        fill(pixel.color.r,pixel.color.g,pixel.color.b);
        noStroke();
        ellipse(pixel.x * 10 + 5, pixel.y * 10 + 5, 8, 8);
      //console.log("drawing", pixel.x, pixel.y, pixel.color);
      }
  });

}