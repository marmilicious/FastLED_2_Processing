/*===============================================================
 arduino_to_processing_v10.ino
 Marc Miller,  April 2015
 
 ================================================================
  This program is setup to send FastLED pixel data a Processing
  sketch.  Processing can then display that data and simlulate a
  pixel strip.
  To test, upload this sketch to your arduino, and then run the
  Processing sketch:
    test_serial_from_arduino_v10.pde
  
  Simulating a pixel display in Processing could be useful when
  creating patterns but a LED strip is not available or hooked up.
  An Arduino is still required to run your arduino code and send
  it to Processing though.

  Note:  The way colored dots are displayed on a computer monitor
  is visually very different then looking at actual LEDs.  This
  setup is probably not great for trying to dial in specific
  colors, but it does allow varifing if the pixels are receiving a
  red vs blue color for example.

  Note: You can not use the serial monitor while using Processing
  to display the pixel data since it connects to the Arduino over
  a serial connection.  This could make debugging a pixel pattern
  more difficult if you like to use the serial monitor to print
  out feed back while creating patterns.  (This might still be
  possible with an Arduino Mega which has more then one serial
  monitor but I have not been able to test this.)

  --------------------------------------------------------------- 
  I have marked all the code bits below that are needed to send
  the pixel data to Processing.  Search for '****' (no quotes) to
  find each needed section to copy to another arduino sketch.
 
  Anywhere FastLED.show() is called you'll also need to add the
  function call that sends the pixel data to Processing.  An easy
  way to add this is to use find and replace.
            Find:  FastLED.show();
    Replace with:  FastLED.show(); SendToProcessing();

  The FastLED library is by Daniel Garcia and Mark Kriegsman and
  can be found at http://fastled.io/ 
  
    
================================================================*/

#include "FastLED.h"
#define LED_TYPE NEOPIXEL  // *Update to your strip type.  NEOPIXEL, APA102, LPD8806, etc..
#define DATA_PIN 6  // *Set this to your data pin.
//#define CLOCK_PIN 13  // *Set this to your clock pin if needed.
#define NUM_LEDS 12  // *Update to the number of pixels in your strip.
//#define COLOR_ORDER BGR
#define MASTER_BRIGHTNESS 255 // Master brightness range is 0-255.
CRGB leds[NUM_LEDS];


/****Variables needed for sending to Processing. */
uint16_t sendDelay = 10;    // [Milliseconds] To slow stuff down if needed.
boolean testing = false;  // Default is false. [Ok to change for testing.]
  // Can temporarily change testing to true to check output in serial monitor.
  // Must set back to false to allow Processing to connect and receive data.

boolean linkedUp = false;  // Initially set linkup status false. [Do Not change.]
/****End of variables needed for sending Processing. */


// This variable only needed for this demo.
int pick = 99;  // Set to 0 to loop demo patterns, or 99 to only run default choice.


//---------------------------------------------------------------
void setup() {
  delay(1500);  // Startup delay
  FastLED.addLeds<LED_TYPE,DATA_PIN>(leds, NUM_LEDS);  // ***For Clock-less strips.
  //FastLED.addLeds<LED_TYPE,DATA_PIN,CLOCK_PIN,COLOR_ORDER>(leds, NUM_LEDS);  // ***For strips using Clock.
  FastLED.setBrightness(MASTER_BRIGHTNESS);


  /****Stuff needed in setup() section for sending to Processing. */
  Serial.begin(115200);  // Allows serial output.
  while (!Serial){ ; }  // Wait for serial connection. Only needed for Leonardo board.
  firstContact();  // Connect with Processing. Hello, is anyone out there?
  /****End of stuff to put in your setup() section for Processing. */


}//end of setup


//---------------------------------------------------------------
void loop() {

/****This tests if serial is connected.  Needed for sending to Processing. */
if (linkedUp == true) {  /****Check to see if connected with Processing. */

  // Run through various color data examples and display.
  switch(pick){
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
      FastLED.show(); SendToProcessing();  // Show and send pixel data to Processing.
      delay(3000);
      FastLED.clear();  // Clear the strip (set to Black).
      FastLED.show(); SendToProcessing();  // Show and send pixel data to Processing.
      delay(500);
      break;
      }
    case 1:{  // Test RGB colors.
      uint8_t pixelNumber = 0;  // Stores pixel number.
      for (int i=0; i < 9; i++){
        leds[(pixelNumber+0) % NUM_LEDS] = CRGB(255,255,255);  // RGB White
        leds[(pixelNumber+1) % NUM_LEDS] = CRGB(255,  0,  0);  // RGB Red
        leds[(pixelNumber+2) % NUM_LEDS] = CRGB(  0,255,  0);  // RGB Green  
        leds[(pixelNumber+3) % NUM_LEDS] = CRGB(  0,  0,255);  // RGB Blue
        leds[(pixelNumber+4) % NUM_LEDS] = CRGB(255,255,255);  // RGB White
        leds[(pixelNumber+5) % NUM_LEDS] = CRGB(255,255,  0);  // RGB Yellow
        leds[(pixelNumber+6) % NUM_LEDS] = CRGB(255,  0,255);  // RGB Purple
        leds[(pixelNumber+7) % NUM_LEDS] = CRGB(  0,255,255);  // RGB Cyan
        FastLED.show(); SendToProcessing();  // Show and send pixel data to Processing.
        delay(800);
        leds[pixelNumber   % NUM_LEDS] = CRGB(  0,  0,  0);  // RGB Black
        pixelNumber++;
        if (pixelNumber >= NUM_LEDS){ pixelNumber = 0; }
      }
      fill_solid(leds, NUM_LEDS, CRGB::Black);  // Black out strip.
      FastLED.show(); SendToProcessing();  // Show and send pixel data to Processing.
      delay(300);
      break;
      }
    case 2:{  // Random pixels and random colors.
      unsigned long currentMillis = millis();  // Used to store current sketch run time.
      unsigned long startMillis = currentMillis;  // Used to store a start time.
      while ((currentMillis - startMillis) < 4000) {  // Check if enough time has passed
        currentMillis = millis();
        for (int x=0; x < NUM_LEDS; x++){
          leds[random16(NUM_LEDS)] = CRGB::Black;  // Randomly turn one off.
          leds[random16(NUM_LEDS)] = CRGB(random8(), random8(), random8());
          FastLED.show(); SendToProcessing();  // Show and send pixel data to Processing.
          delay(120);
        }
      }
      break;
      }
    case 3:{  // Moving dots with limited range random colors.
      uint16_t i,j,k;
      unsigned long currentMillis = millis();  // Used to store current sketch run time.
      unsigned long startMillis = currentMillis;  // Used to store a start time.
      while ((currentMillis - startMillis) < 5000) {  // Check if enough time has passed
        currentMillis = millis();
        for (i=0; i < NUM_LEDS; i++){
          j = (i + (NUM_LEDS/3)) % NUM_LEDS;
          k = (i + (2*NUM_LEDS/3)) % NUM_LEDS;
          leds[i] = CRGB(random8(80,255), random8(90,200), random8(0,80));
          leds[j] = CRGB(random8(80,255), random8(90,200), random8(0,80));
          leds[k] = CRGB(random8(80,255), random8(90,200), random8(0,80));
          FastLED.show(); SendToProcessing();  // Show and send pixel data to Processing.
          leds[i] = CRGB::Black;
          leds[j] = CRGB::Black;
          leds[k] = CRGB::Black;
          delay(150);
        }
      }
      break;
      }
    case 4:{  // Rainbowygoodness.  Then fades out half the pixels.
      unsigned long currentMillis = millis();  // Used to store current sketch run time.
      unsigned long startMillis = currentMillis;  // Used to store a start time.
      while ((currentMillis - startMillis) < random16(4000,8000)) {  // Check if enough time has passed
        currentMillis = millis();
        fill_rainbow( leds, NUM_LEDS, millis()/20);
        FastLED.show(); SendToProcessing();  // Show and send pixel data to Processing.
        delay(100);
      }
      for (int i=0; i<120; i++) {  // Fade out half the pixels.
        fadeToBlackBy( leds, NUM_LEDS/2, 5); delay(40);
        FastLED.show(); SendToProcessing();  // Show and send pixel data to Processing.
      }
      fill_solid(leds, NUM_LEDS, CRGB::Black);  // Black out strip.
      FastLED.show(); SendToProcessing();  // Show and send pixel data to Processing.
      delay(500);
      break;
      }
    default:{  // Sequentially fill pixel strip over and over.
      int hueStart = random8();
      for (uint16_t i=0; i <= NUM_LEDS; i++){
        fill_rainbow( leds, i, hueStart);
        FastLED.show(); SendToProcessing();  // Show and send pixel data to Processing.
        delay(25);
      }
      delay(500);
      FastLED.clear();  // Clear the strip (set to Black).
      FastLED.show(); SendToProcessing();  // Show and send pixel data to Processing.
      delay(50);
      pick = 99;
      break;
      }
  }//end of switch(pick)

  pick++;
  if (pick == 5){ pick = 0; }  // Reset to go through picks again.


} //****End of Processing 'linkedUp' check. */


}//end of main loop
//---------------------------------------------------------------



/****The below two functions are needed for sending to Processing. */
// Copy from here to the bottom.
//--------------------
// Waits for Processing to respond and then sends the number of pixels.
void firstContact() {
  uint16_t nLEDS = NUM_LEDS;  // Number to send to Processing.  (Allows up to 65,535 pixels)
  if (testing == true){
    linkedUp = true;  // If testing, pretend we are already connected to Processing.
    Serial.print("NUM_LEDS: "); Serial.println(nLEDS);  // Number of pixels in our LED strip. 
    Serial.print("  High Byte = "); Serial.print(highByte(nLEDS));  // The high byte.
    Serial.print(" x 256 = "); Serial.println(highByte(nLEDS) * 256);
    Serial.print("  Low Byte  = "); Serial.println(lowByte(nLEDS));  // The low byte.
    delay(3000);
  }
  else {
    while (Serial.available() <= 0) {  // Repeats until Processing responds. Hello?
      Serial.print('A');  // send an ASCII A (byte of value 65)
      delay(100);
    }
    // Once Processing responds send the number of pixels as two bytes.
    Serial.write(highByte(nLEDS));  // Send the high byte to Processing.
    Serial.write(lowByte(nLEDS));  // Send the low byte to Processing.
    Serial.print('#');  // send an ASCII # (byte of value 35) as a flag for Processing.
    linkedUp = true;  // Now that Processing knows number of pixels set linkedUp to true.
    delay(500);
  }
}

//--------------------
// This function sends ALL the pixel data to Processing.
void SendToProcessing() {
  if (testing == true){  // Print pixel data. If NUM_LEDS is large this will be a lot of data!
    Serial.println("-------------------------------------------------------");
    for (uint16_t d=0; d < NUM_LEDS; d++){
      Serial.print("p: "); Serial.print(d);
      Serial.print("\tr: "); Serial.print(leds[d].r);
      Serial.print("\tg: "); Serial.print(leds[d].g);
      Serial.print("\tb: "); Serial.println(leds[d].b);
    }
    Serial.println(" ");
    delay(500);  // Add some extra delay while testing.
  }
  else {  // Send ALL the pixel data to Processing!
    for (uint16_t d=0; d < NUM_LEDS; d++){
      Serial.write(d);          // Pixel number
      Serial.write(leds[d].r);  // Red channel data
      Serial.write(leds[d].g);  // Green channel data
      Serial.write(leds[d].b);  // Blue channel data
    }
    delay(sendDelay);  // Delay to slow things down if needed.
  }
}

//--------------------
/****End of the functions needed for sending to Processing.*/
