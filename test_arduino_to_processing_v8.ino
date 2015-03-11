/*===============================================================
 test_arduino_to_processing_v8
 ================================================================
 This program sends an ASCII leter A (byte of value 65) on startup
 and repeats that until it gets a response (a letter back) from Processing.
 Then it sends bytes continuously to Processing, a pixel number and
 it's HSV values, then the next.

 Please use the Processing sketch test_serial_from_arduino_v8.pde in
 conjunction with this sketch for testing things out.

 For the time beeing the code is limited to only being able to send
 data for 255 pixels (ie. NUM_LEDS should not be more then 255).
 For larger values of NUM_LEDS a lot of data is sent to Processing.
 You might want to leave it set to the current 12 pixels until you
 follow what's going on.

 I've tried to mark all the things below I think would need to be
 copied to another Arduino sketch to be able to send it's data to
 Processing.  You can search for '****' (no quotes) to find each bit.

 In the sketch, anywhere FastLED.show() is called, then you should also
 call the function SendToProcessing() right after it.  For example:

    leds[0] = CRGB::Red;
    FastLED.show();
    SendToProcessing();  // Send all the pixel data to Processing.


 Marc Miller
 Feb. 11, 2015
================================================================*/

#include "FastLED.h"
#define LED_TYPE NEOPIXEL  // *Update to your strip type.  NEOPIXEL, APA102, LPD8806, etc..
#define DATA_PIN 6  // *Remember to set this to your data pin.
//#define CLOCK_PIN 13  // *Remember to set this to your clock pin.
#define NUM_LEDS 12  // *Remember to update.  [***PLEASE LIMIT TO 256 PIXELS FOR NOW***]
                     // You might want to leave this number smallish to start with
                     // until you see how this works on the Processing side.
//#define COLOR_ORDER BGR
#define MASTER_BRIGHTNESS 255 // Master brightness range is 0-255.
CRGB leds[NUM_LEDS];

//****
//****Variables needed for sending to Processing
uint16_t holdTime = 50;  // [Milliseconds] To slow stuff down if needed. Try zero!
boolean linkedUp = false;  // Initially set linkup status false. [Do Not change.] 
boolean testing = false;  // Default is false. [Ok to change for testing.]
  // Can temporarily change to true to check output in serial monitor.
  // Must set back to false to allow Processing to get data.
//****End of variables needed for sending Processing
//****


uint8_t pixelNumber = 0;  // Stores pixel number. 
int pick = 0;  // Stores switch case pick. 


//---------------------------------------------------------------
void setup() {
  delay(1000);  // Startup delay
  FastLED.addLeds<LED_TYPE,DATA_PIN>(leds, NUM_LEDS);  // ***For Clock-less strips.
  //FastLED.addLeds<LED_TYPE,DATA_PIN,CLOCK_PIN,COLOR_ORDER>(leds, NUM_LEDS);  // ***For strips using Clock.
  FastLED.setBrightness(MASTER_BRIGHTNESS);

  //****
  //****Stuff needed in setup() section for sending to Processing
  Serial.begin(115200);  // Allows serial output (check baud rate)
  while (!Serial) {
    ;  // Wait for serial port to connect. Only needed for Leonardo board.
  }
  firstContact();  // Attemp to contact Processing. Hello, is anyone out there?

  if (testing == true){
    linkedUp = true;  // Pretend we've connected with Processing while testing.
    Serial.print("NUM_LEDS = "); Serial.print(NUM_LEDS);  // Number of pixels in our LED strip. 
    //Serial.print(",  Binary: "); Serial.print(NUM_LEDS,BIN);  // Number of pixels in our LED strip. 
    Serial.println(" ");
  }
  //****End of stuff to put in your setup() section for Processing
  //****

} //End of setup


//---------------------------------------------------------------
void loop() {

  //****
  //****This tests if serial is connected.  Needed for sending to Processing
  if (linkedUp == true) {  // Check to see if connected with Processing.
  //****
  //****

    switch(pick){  // Run through various color data examples and display it.
      case 0:{  // Test HSV 'rainbow' colors.
        FastLED.clear();
        delay(300);
        leds[0] = CHSV(  0,255,255);  // HSV Red
        leds[1] = CHSV( 32,255,255);
        leds[2] = CHSV( 64,255,255);
        leds[3] = CHSV( 96,255,255);  // HSV Green
        leds[4] = CHSV(128,255,255);
        leds[5] = CHSV(160,255,255);  // HSV Blue
        leds[6] = CHSV(192,255,255);
        leds[7] = CHSV(224,255,255);
        leds[8] = CHSV(  0,  0,255);  // HSV White
        FastLED.show();
        SendToProcessing();  // Send all the pixel data to Processing.
        delay(4000);
        FastLED.clear();
        delay(500);
        break;
        }
      case 1:{  // Test RGB colors.
        for (int i=0; i < 5; i++){
          leds[pixelNumber   % NUM_LEDS] = CRGB(255,  0,  0);  // RGB Red
          leds[pixelNumber+1 % NUM_LEDS] = CRGB(  0,255,  0);  // RGB Green  
          leds[pixelNumber+2 % NUM_LEDS] = CRGB(  0,  0,255);  // RGB Blue
          leds[pixelNumber+3 % NUM_LEDS] = CRGB(255,  0,255);
          leds[pixelNumber+4 % NUM_LEDS] = CRGB(  0,255,255);
          leds[pixelNumber+5 % NUM_LEDS] = CRGB(255,255,  0);
          leds[pixelNumber+6 % NUM_LEDS] = CRGB(255,255,255);  // RGB White
          FastLED.show();
          SendToProcessing();  // Send all the pixel data to Processing.
          delay(1500);
          leds[pixelNumber   % NUM_LEDS] = CRGB(  0,  0,  0);  // RGB Black
          pixelNumber++;
          if (pixelNumber > NUM_LEDS){ pixelNumber = 0; }
        }
        fill_solid(leds, NUM_LEDS, CRGB::Black);  // Black out strip.
        FastLED.show();
        SendToProcessing();  // Send all the pixel data to Processing.
        break;
        }
      case 2:{  // Random colors.
        for (int i=0; i < 2; i++){
          for (int x=0; x < NUM_LEDS; x++){
            leds[random(NUM_LEDS)] = CRGB::Black;  // Randomly turn on off.
            leds[random(NUM_LEDS)] = CRGB(random8(), random8(), random8());
            FastLED.show();
            SendToProcessing();  // Send all the pixel data to Processing.
          }
          delay(400);
        }
        break;
        }
      case 3:{  // Moving dots.
        for (int j=0; j < 2; j++){
          for (int i=0; i < NUM_LEDS; i++){
            int j = (i + (NUM_LEDS/3)) % NUM_LEDS;
            int k = (i + (2*NUM_LEDS/3)) % NUM_LEDS;
            leds[i] = CRGB(random8(80,255), random8(90,200), random8(0,80));
            leds[j] = CRGB(random8(80,255), random8(90,200), random8(0,80));
            leds[k] = CRGB(random8(80,255), random8(90,200), random8(0,80));
            FastLED.show();
            SendToProcessing();  // Send all the pixel data to Processing.
            leds[i] = CRGB::Black;
            leds[j] = CRGB::Black;
            leds[k] = CRGB::Black;
            delay(120);
            }
          }
        break;
        }
      case 4:{  // Rainbowygoodness.
        for (int i=0; i < 70; i++){
          fill_rainbow( leds, NUM_LEDS, millis()/20);
          FastLED.show();
          SendToProcessing();  // Send all the pixel data to Processing.
          delay(100);
        }
        fill_solid(leds, NUM_LEDS, CRGB::Black);  // Black out strip.
        FastLED.show();
        SendToProcessing();  // Send all the pixel data to Processing.
        delay(200);
        break;
        }
      default:
        pick = 0;
    }
    pick++;
    if (pick > 4){ pick = 0; }
    pixelNumber = 0;

  //****
  } //****End of Processing 'linkedUp' check.
  //****

} //End of main loop
//---------------------------------------------------------------


//****
//****The below two functions are needed for sending to Processing
//--------------------
void firstContact() {
  if (testing == true){
    linkedUp = true;  // If testing, pretenct we've connected with Processing.
  } else {
    while (Serial.available() <= 0) {  // Repeats until Processing responds. Hello?
      Serial.print('A');   // send an ASCII A (byte of value 65) 
      delay(100);
    }
    // Once Processing responds send the number of pixels in our strip.
    Serial.write(NUM_LEDS);  // Send then number of pixels in our LED strip. 
    linkedUp = true;  // Once connected with Processing set linkedUp to true.
    delay(500);
  }
}

//--------------------
// Whenever this function is called it sends ALL the pixel data to Processing.
void SendToProcessing() {
  // Output verbose details when testing is true.
  // If NUM_LEDS is large this will be a lot of data!
  if (testing == true){
    Serial.println("-------------------------------------------------------");
    for (uint16_t d=0; d < NUM_LEDS; d++){
      Serial.print("p: "); Serial.print(d);
      Serial.print("\tr: "); Serial.print(leds[d].r);
      Serial.print("\tg: "); Serial.print(leds[d].g);
      Serial.print("\tb: "); Serial.print(leds[d].b);
      Serial.println(" ");
    }
    Serial.println(" ");
    delay(50);  // Add some extra delay when testing here.

  } else {
    // SEND ALL THE PIXEL DATA TO PROCESSING.
    for (uint16_t d=0; d < NUM_LEDS; d++){
      Serial.write(d);  // Pixel number
      Serial.write(leds[d].r);  // Red channel data
      Serial.write(leds[d].g);  // Green channel data
      Serial.write(leds[d].b);  // Blue channel data
    }
    delay(holdTime);  // Delay to slow things down if needed.
  }
}

//--------------------
//****End of the functions needed for sending to Processing
//****




