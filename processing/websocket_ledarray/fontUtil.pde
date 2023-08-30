void drawString(String strg, int x, int y, color c) {

  int startX = x;

  for (int i = 0; i < strg.length(); i++) {
    char character = strg.charAt(i);
    if (x+checkWidth(str(character))> 64) {
      y += 8;
      x = startX;
    }
    int wid = drawChar(str(character), x, y*rndScl, c);
    x += wid;
  }
}

int drawChar(String st, int x, int y, color c) {
  int [][] bitmap = font.get(st);
  for (int i = 0; i< bitmap.length; i++) {

    for (int j = 0; j< bitmap[i].length; j++) {
      if (bitmap[i][j] == 1) {
        drawScaledPixel(x + j*rndScl, y + i*rndScl, c);
      }
    }
  }

  return bitmap[0].length*rndScl;
}


int checkWidth(String st) {
  int [][] bitmap = font.get(st);
  return bitmap[0].length*rndScl;
}



void drawScaledPixel(int x, int y, color c) {
  for (int i = 0; i<rndScl; i++) {
    for (int j = 0; j<rndScl; j++) {
      set(x + i, y + j, c);
    }
  }
}
