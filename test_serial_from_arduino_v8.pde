/****************************************************************
 test_serial_from_arduino_v8
 ****************************************************************
 This program receives data from the Arduino sketch:
   test_arduino_to_processing_v8.ino

 It listens for an ASCII letter A over serial and then responds with
 a letter A to confirm the connection.  Once connected then it
 receives NUM_LEDS so it knows how many pixels are in the LED strip.
 
 Then it continues receiving the serial data as it's sent.  Whenever
 it has accumulated **ALL the bytes for the LED strip it displays it
 on the simulated strip. It then goes back to receving data again.

 **ALL the data for a strip is 4 x NUM_LEDS worth of bytes, since for
 each pixel the Arduino is sending pixel number, red, green, blue
 values.  This could get large if there are a lot of pixels!

 To run this Processing sketch, first upload the Arduino sketch onto
 your controller.  Then you can play this Processing sketch.

 I've left the variable testing = true below.  It will display a lot
 of data in the Processing monitor if NUM_LEDS is large.  For testing
 things out and understanding how things work you might  want to
 limit NUM_LEDS in your Arduino sketch to a smallish number.
 
 Every once in awhile while I've been testing this when I run the
 sketch I'll get an error (serial connection error?), but stopping
 and restarting it has always made it run fine again.
 
 Marc Miller
 Feb. 11, 2015
*****************************************************************/
 
import processing.serial.*;

Serial myPort;                         // The serial port.
int[] serialInArray = new int[256*4];  // Where we'll put the data we receive.  [***LIMITING TO 255 PIXELS FOR NOW***]
                                       //   It's the number of pixels x 4 since we store _position and color_ data for pixel. 
int serialCount = 0;                   // A count of how many bytes we receive.
int pixelCount = 0;                    // Count our pixels.
boolean firstContact = false;          // Whether we've heard from the microcontroller.  Initially false.

int stageWidth = 1100;                  // Width of stage draw area.
int stageHeight = 128;                 // Height of stage draw area.
int bgcolor = 42;                      // Stage background color.
int pixelSize = 20;                    // Width and height of pixel.
int pixelOffset = 30;                  // Pixel spacing (measured from center to center).
int xstart = 40;                       // Position from left edge to center of first pixel.
int xpos;                              // Stores a horizontal position.
int xTemp;
int ypos = 40;                         // Vertial position of pixel row (measured from top down).
int pixelNumber = -1;                  // Pixel number from serial data.  Initally set as -1 as a flag to trigger drawing of blank pixels.
int redChan;                           // Red value (0-255) 
int greenChan;                         // Green value (0-255)
int blueChan;                          // Blue value (0-255)
int NUM_LEDS;                          // Number of pixels in strip. [***CURRENTLY BEING LIMITED TO 255 FOR NOW***]

boolean testing = true;  // Turn on/off testing mode.  Shows pixelNumber and color data. [Ok to change.]
boolean testing_verbose = false;  // Verbose detail of incoming data.  Default is false. [Ok to change.]


//---------------------------------------------------------------
void setup() {
  size(stageWidth, stageHeight);       // Stage size.
  noStroke();                          // No border when drawing.
  //colorMode(RGB, 255);                 // Use Red, Green, Blue mode, using range from 0-255.
  colorMode(HSB, 255);                 // Use Hue, Saturation, Brightness(Value) mode, using range from 0-255.
  background(bgcolor);                 // Set stage bg color. 
  rectMode(CENTER);                    // Rectangles are positioned based on their center.
  ellipseMode(CENTER);                 // Ellipses are positioned based on their center.
  
  // Print a list of the serial ports available (Useful for debugging).
  printArray(Serial.list());

  // Open the port you're using by changing the number in brackets [n].
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 115200);  // Create the serial port.
  myPort.clear();   // Clear the serial port buffer.
}


//---------------------------------------------------------------
void draw() {
  // Nothing needed here since we only draw pixels as needed below
}


//---------------------------------------------------------------
void serialEvent(Serial myPort) {

  // Read a byte from the serial port.
  int inByte = myPort.read();  // Read the incoming data.  Nom nom nom.
  if (testing_verbose == true) {
    print("inByte = " + inByte + "  \t ");  // Show what was nommed.
  }

  // If this is the first byte received, and will be an A.  If true,
  // clear buffer, update firstContact, and draw empty(off) pixels.
  // Otherwise, start collecting the incoming bytes of pixel data.
  if (firstContact == false) {

    if (inByte == 'A') { 
      myPort.write('A');  // Tell the arduino you're connect and want more.
      println("Contact established... ");

    } else {
      NUM_LEDS = inByte;
      println("NUM_LEDS = " + NUM_LEDS);

      myPort.clear();       // Clear the serial port buffer.
      firstContact = true;  // First contact from the microcontroller established!

      if (pixelNumber == -1){  // Draw initial row of pixels (only happens once).
        for (int i=0; i<NUM_LEDS; i++){
          colorMode(HSB, 255);  // Use Hue, Saturation, Brightness(Value) mode, using range from 0-255.
          fill(0,0,255);  // HSB mode = White part of pixel
          rect(xstart+(i*pixelOffset),ypos,pixelSize+3,pixelSize+3,3);  // center x, center y, width, height, corner radius
          fill(0,255,25);  // HSB mode
          ellipse(xstart+(i*pixelOffset),ypos,pixelSize,pixelSize);  // center x, center y, width, height
        }

      myPort.clear();   // Clear the serial port buffer.
      pixelNumber = 0;  // Zero out pixel number counter.

      }
    }

  } else {  // Start adding the byte data from the serial port to serial storage array.
    serialInArray[serialCount] = inByte;  //  Nom nom nom!

    if (testing_verbose == true) {  // Print a bunch of values for debugging
      if (serialCount % 4 == 0) {  // Test if number is divisible by 4, aka a pixel numbers.
        println("  >> serialInArray[" + serialCount + "] = " + serialInArray[serialCount] + "      <-- pixel number");
      }
      if (serialCount % 4 != 0) {  // Test if number not divisible by 4, aka the color data.
        println("     serialInArray[" + serialCount + "] = " + serialInArray[serialCount] + " ");
      }
    }
    
    serialCount++;  // Increment count of the number of bytes stored in the array.
 
    if (serialCount == (NUM_LEDS*4)) {  // True when we have all the data for the LED strip.

      if (testing == true) { println("--------------------------------------------------------------------------------"); }  // Print when debugging

      for (int p=0; p < NUM_LEDS; p++) {
        xpos = xstart + (pixelOffset * serialInArray[4*p]);  // Find pixel's horizontal draw position.
        redChan   = serialInArray[(4*p)+1];  // Red value. 
        greenChan = serialInArray[(4*p)+2];  // Green value.
        blueChan  = serialInArray[(4*p)+3];  // Blue value.
        
        if (testing == true) {  // Print values for debugging
          println("  pixelNumber " + p + "\t\t redChan " + redChan + "\t greenChan " + greenChan + "\t blueChan " + blueChan);
        }

        colorMode(RGB, 255);            // Use Red, Green, Blue mode, using range from 0-255.
        fill(redChan,greenChan,blueChan);  // Set fill color based on the RGB data we received.

        ellipse(xpos,ypos,pixelSize,pixelSize);  // center x, center y, width, height
      }
      
      serialCount = 0;  // Reset serial count before starting to receive data again.
      myPort.clear();   // Clear the serial port buffer.
    } 
  }
} //end serialEvent loop


/*---------------------------------------------------------------


TODO ideas:
  - Double check that pixel color data is being correctly transfers and interpreted.
      Lit up LEDs look _SO_ different (glowing!) then colored dots on a monitor,
      it sometimes appears incorrect. 

  - Update to allow pixel strip length greater then 255.

  - Wrap drawing of pixel row to multiple rows if there are more pixels then fit on monitor width.
  - Maybe auto scale size of pixels (and stage drawing area?) based on NUM_LEDS.

  - Add some info text to stage draw area?  Maybe the pixel numbers?
      Probably something needed if multiple rows get drawn to help clarify pixel numbers.

  - Investigate drawing continuously by using the draw() section? Process a pixel imadiately once 4 bytes arive?

  - Add some sort of error checking if needed.  Maybe send a response back to Arduino telling
    it to send next string of data (A continuous back and forth sort of talk).

  - Add a "glow" effect to lit pixels for extra fancyness!

  - FastLED's MASTER_BRIGHTNESS does not effect brightness in Processing.  Maybe not really needed?
 
  - 
  
----------------------------------------------------------------*/


