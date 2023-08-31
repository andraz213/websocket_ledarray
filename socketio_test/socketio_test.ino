/*
 * WebSocketClientSocketIOack.ino
 *
 *  Created on: 20.07.2019
 *
 */

#include <Arduino.h>

#include <WiFi.h>
#include <WiFiMulti.h>
#include <WiFiClientSecure.h>
#include <Adafruit_Protomatter.h>

#include <ArduinoJson.h>

#include <WebSocketsClient.h>
#include <SocketIOclient.h>

WiFiMulti WiFiMulti;
SocketIOclient socketIO;

uint8_t current_image[2048];
uint8_t pixels[64][32][3];

#define HEIGHT 32   // Matrix height (pixels) - SET TO 64 FOR 64x64 MATRIX!
#define WIDTH 64    // Matrix width (pixels)
#define MAX_FPS 45  // Maximum redraw rate, frames/second

#if defined(_VARIANT_MATRIXPORTAL_M4_)  // MatrixPortal M4
uint8_t rgbPins[] = { 7, 8, 9, 10, 11, 12 };
uint8_t addrPins[] = { 17, 18, 19, 20, 21 };
uint8_t clockPin = 14;
uint8_t latchPin = 15;
uint8_t oePin = 16;
#else  // MatrixPortal ESP32-S3
uint8_t rgbPins[] = { 42, 41, 40, 38, 39, 37 };
uint8_t addrPins[] = { 45, 36, 48, 35, 21 };
uint8_t clockPin = 2;
uint8_t latchPin = 47;
uint8_t oePin = 14;
#endif

#if HEIGHT == 16
#define NUM_ADDR_PINS 3
#elif HEIGHT == 32
#define NUM_ADDR_PINS 4
#elif HEIGHT == 64
#define NUM_ADDR_PINS 5
#endif

#define USE_SERIAL Serial

Adafruit_Protomatter matrix(
  WIDTH, 4, 1, rgbPins, NUM_ADDR_PINS, addrPins,
  clockPin, latchPin, oePin, true);


void socketIOEvent(socketIOmessageType_t type, uint8_t *payload, size_t length) {
  switch (type) {
    case sIOtype_DISCONNECT:
      USE_SERIAL.printf("[IOc] Disconnected!\n");
      break;
    case sIOtype_CONNECT:
      USE_SERIAL.printf("[IOc] Connected to url: %s\n", payload);

      // join default namespace (no auto join in Socket.IO V3)
      socketIO.send(sIOtype_CONNECT, "/");
      break;
    case sIOtype_EVENT:
      {
        long start = micros();
        char *sptr = NULL;
        int id = strtol((char *)payload, &sptr, 10);
        //USE_SERIAL.printf("[IOc] get event: %s id: %d\n", payload, id);
        if (id) {
          payload = (uint8_t *)sptr;
        }
        /*
        long starts = micros();
        DynamicJsonDocument doc(1024);
        DeserializationError error = deserializeJson(doc, payload, length);
        long stops = micros();
        Serial.print("serialization: ");
        Serial.println(stops - starts);
        if (error) {
          USE_SERIAL.print(F("deserializeJson() failed: "));
          USE_SERIAL.println(error.c_str());
          return;
        }

       
        for (int ri = 0; ri < doc[1].size(); ri++) {
          long startsd = micros();
          String pay = doc[1][ri];
          long stopsd = micros();
                  Serial.print("get row: ");
        Serial.println(stopsd - startsd);
          int row = strtol(pay.substring(0, 2).c_str(), NULL, 16);
          int start = strtol(pay.substring(2, 4).c_str(), NULL, 16);
          int c = start;
          for (int i = 4; i < pay.length(); i += 6) {
            int k = i;
            int pixel_r = strtol(pay.substring(k, k + 2).c_str(), NULL, 16);
            int pixel_g = strtol(pay.substring(k + 2, k + 4).c_str(), NULL, 16);
            int pixel_b = strtol(pay.substring(k + 4, k + 6).c_str(), NULL, 16);

            int x = c % 64;
            int y = row;
            int s = i - 2;
            c++;
            pixels[x][y][0] = pixel_r;
            pixels[x][y][1] = pixel_g;
            pixels[x][y][2] = pixel_b;
          }
        }*/
        int ps = 5;
        if (ps > length) {
          return;
        }

        while ((char)payload[ps] != '[') {
          ps = incrementPS(ps, payload);
          if (ps > length) {
            return;
          }
        }

        while ((char)payload[ps] != ']') {
          if (ps > length) {
            return;
          }
          if ((char)payload[ps] == '"') {
            ps = incrementPS(ps, payload);
            int row = charToInt((char)payload[ps]);
            row *= 16;
            ps = incrementPS(ps, payload);
            row += charToInt((char)payload[ps]);
            ps = incrementPS(ps, payload);

            int start = charToInt((char)payload[ps]);
            start *= 16;
            ps = incrementPS(ps, payload);
            start += charToInt((char)payload[ps]);
            ps = incrementPS(ps, payload);

            int c = start;
            while ((char)payload[ps] != '"') {
              int pixel_r = charToInt((char)payload[ps]) * 16 + charToInt((char)payload[ps + 1]);
              int pixel_g = charToInt((char)payload[ps + 2]) * 16 + charToInt((char)payload[ps + 3]);
              int pixel_b = charToInt((char)payload[ps + 4]) * 16 + charToInt((char)payload[ps + 5]);

              int x = c % 64;
              int y = row;
              c++;
              pixels[x][y][0] = pixel_r;
              pixels[x][y][1] = pixel_g;
              pixels[x][y][2] = pixel_b;
              for (int i = 0; i < 6; i++) {
                ps = incrementPS(ps, payload);
              }
            }
            while (payload[ps] != ',') {
              ps = incrementPS(ps, payload);
            }
          } else {
            ps = incrementPS(ps, payload);
          }
        }





        // Message Includes a ID for a ACK (callback)
        if (id) {
          // creat JSON message for Socket.IO (ack)
          DynamicJsonDocument docOut(1024);
          JsonArray array = docOut.to<JsonArray>();

          // add payload (parameters) for the ack (callback function)
          JsonObject param1 = array.createNestedObject();
          param1["now"] = millis();

          // JSON to String (serializion)
          String output;
          output += id;
          serializeJson(docOut, output);

          // Send event
          socketIO.send(sIOtype_ACK, output);
        }
        long stop = micros();
        Serial.println(stop - start);
      }
      break;
    case sIOtype_ACK:
      USE_SERIAL.printf("[IOc] get ack: %u\n", length);
      break;
    case sIOtype_ERROR:
      USE_SERIAL.printf("[IOc] get error: %u\n", length);
      break;
    case sIOtype_BINARY_EVENT:
      USE_SERIAL.printf("[IOc] get binary: %u\n", length);
      break;
    case sIOtype_BINARY_ACK:
      USE_SERIAL.printf("[IOc] get binary ack: %u\n", length);
      break;
  }
}


void process_row(String pay, int row) {
}


void setup() {
  //USE_SERIAL.begin(921600);
  USE_SERIAL.begin(115200);

  //Serial.setDebugOutput(true);
  USE_SERIAL.setDebugOutput(true);

  USE_SERIAL.println();
  USE_SERIAL.println();
  USE_SERIAL.println();

  for (uint8_t t = 4; t > 0; t--) {
    USE_SERIAL.printf("[SETUP] BOOT WAIT %d...\n", t);
    USE_SERIAL.flush();
    delay(1000);
  }
  int r = 0;
  long start1 = micros();
  for (int i = 0; i < 100000; i++) {
    r = charToInt('8');
  }
  long stop1 = micros();
  char os = '8';
  long start2 = micros();
  for (int i = 0; i < 100000; i++) {
    r = atoi(&os);
  }
  long stop2 = micros();

  Serial.print("my function: ");
  Serial.print(stop1 - start1);
  Serial.print("  atoi: ");
  Serial.print(stop2 - start2);
  Serial.println();



  WiFiMulti.addAP("rolika", "nandrazzz");

  //WiFi.disconnect();
  while (WiFiMulti.run() != WL_CONNECTED) {
    delay(100);
  }

  String ip = WiFi.localIP().toString();
  USE_SERIAL.printf("[SETUP] WiFi Connected %s\n", ip.c_str());

  // server address, port and URL
  socketIO.begin("192.168.40.232", 4000, "/socket.io/?EIO=4");

  // event handler
  socketIO.onEvent(socketIOEvent);
  ProtomatterStatus status = matrix.begin();
  Serial.printf("Protomatter begin() status: %d\n", status);
  matrix.drawPixel(10, 10, matrix.color565(50, 0, 0));
  matrix.show();
}


long prev_disp = 0;
unsigned long messageTimestamp = 0;
void loop() {
  socketIO.loop();

  uint64_t now = millis();

  if (now - messageTimestamp > 200000) {
    messageTimestamp = now;

    // creat JSON message for Socket.IO (event)
    DynamicJsonDocument doc(1024);
    JsonArray array = doc.to<JsonArray>();

    // add evnet name
    // Hint: socket.on('event_name', ....
    array.add("event_name");

    // add payload (parameters) for the event
    JsonObject param1 = array.createNestedObject();
    param1["now"] = (uint32_t)now;

    // JSON to String (serializion)
    String output;
    serializeJson(doc, output);

    // Send event
    socketIO.sendEVENT(output);

    // Print JSON for debugging
    USE_SERIAL.println(output);
  }

  if (millis() - prev_disp > 19) {
    prev_disp = millis();
    long start = micros();
    for (int i = 0; i < 64; i++) {
      for (int j = 0; j < 32; j++) {

        matrix.drawPixel(i, j, matrix.color565(pixels[i][j][0], pixels[i][j][1], pixels[i][j][2]));
      }
    }
    matrix.show();
  }
}




int charToInt(char c) {
  if (c == '0')
    return 0;
  if (c == '1')
    return 1;
  if (c == '2')
    return 2;
  if (c == '3')
    return 3;
  if (c == '4')
    return 4;
  if (c == '5')
    return 5;
  if (c == '6')
    return 6;
  if (c == '7')
    return 7;
  if (c == '8')
    return 8;
  if (c == '9')
    return 9;
  if (c == 'A')
    return 10;
  if (c == 'B')
    return 11;
  if (c == 'C')
    return 12;
  if (c == 'D')
    return 13;
  if (c == 'E')
    return 14;
  if (c == 'F')
    return 15;
}



int incrementPS(int ps, uint8_t *payload) {
  ps++;
  //Serial.print((char)payload[ps]);
  return ps;
}
