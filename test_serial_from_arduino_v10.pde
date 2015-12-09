/*==============================================================================
  test_serial_from_arduino_v10.pde
  Marc Miller,  April 2015

  *** Note: You need to run this with the older Processing 2.2.1 ***
================================================================================
  This Processing program receives pixel data from an Arduino sketch running
  FastLED.  An Arduino demo sketch can be used to test it out:
    arduino_to_processing_v10.ino

  There are several user changeable variables to allow Processing to draw
  a pixel setup similar to what your physical pixel arrangement looks like,
  including drawing the pixels as a horizontal or verical strip, circular
  arrangement, or as a matrix of pixels.
  
  To use, first upload the Arduino sketch to your controler board.  Then
  enter the number of pixels in your LED strip and run.  Processing will
  connect to the Arduino and receive the pixel data, drawing a simulated
  LED strip.

  Note: Besides the user variables, another variable that might need to be
  changed is the port number for the serial connection.  Change the number
  in [brackets] as needed on line 92.
 
 
================================================================================
------------------------------------------------------------------------------*/
import processing.serial.*;


//------------------------------------------------------------------------------
//==============================================================================
// *** User variables.  Change as needed to match your setup. ***
int      NUM_LEDS = 12;     // Number of pixels in strip.
String     layout = "H";    // Pixel layout: [H]orizontal, [V]ertical, [M]atrix, or [C]ircular.
String  direction = "F";    // Numbering direction: [F]orward or [R]everse.

// *** Additional variables for Matrix layout only. ***
int numberColumns = 4;      // Number of pixels across.
int    numberRows = 3;      // Number of pixels vertically.
String  scanStart = "T";    // Matrix scan starts from: [T]op or [B]ottom.
String       path = "Z";    // Path type: [Z]igzag or [S]erpintine.


boolean testing = false;  // Testing mode, shows pixelNumber and color data. [default: false]
boolean testing_verbose = false;  // Verbose detail. Shows incoming data.  [default: false]
boolean checkNUM_LEDS = true;  // Force check of NUM_LEDS vs pixels from MCU. [default: true]

// End of user variables.
//==============================================================================
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
Serial myPort;                 // The serial port.
int[] serialArray = new int[65535*4];  // To store the data we receive.  [Limited to max 65,535 pixels.]
// The above number is max pixels x 4, to save the position and R, G, B color data for each pixel. 
int inByte;                    // For storing incoming serial data.
int serialCount = 0;           // A count of how many bytes we receive.
int receivedNUM_LEDS;          // Number of pixels sent to Processing from MCU.  Used for sanity check.
int pixelCount = 0;            // Count our pixels.
int pixelNumber = -1;          // Pixel number from serial data.  Initally -1 to act as trigger.
boolean firstContact = false;  // Whether we've heard from the microcontroller.  Initially false.
int stageMin = 140;            // Minimum stage size.
int stageW = stageMin;         // Initial stage width for draw area.
int stageH = stageMin;         // Initial stage height for draw area.
int pixelSize = 20;            // Width and height of a pixel.
int offset = 30;               // Pixel spacing (measured from pixel center to center).
float xpos, ypos;              // X and Y pixel position in the draw area.
float dx,dy = 0;               // X and Y delta from the stage center in circular layouts.
int cCount = 0;                // Used to keep track of column while drawing pixel matrix.
int rCount = 0;                // Used to keep track of row while drawing pixel matrix.
float r = 1;                   // Radius for circular layout.  Size is calculated elsewhere.
float degrees = 0;             // Degrees to rotate pixel boarder when drawing circular layout.
int dir = 1;                   // Assigns draw direction a value.  [1=Forward, -1=Reverse]
int dirM = 1;                  // Assigns value to matrix scan start position.  [1=Top, -1=Bottom]
int bgcolor = 42;              // Stage background color.
int redChan;                   // Pixel's red value (0-255) 
int greenChan;                 // Pixel's green value (0-255)
int blueChan;                  // Pixel's blue value (0-255)
//==============================================================================


//------------------------------------------------------------------------------
void setup() {

  // - - - - - - - - - - - - - - - - - -  - - - - - - - - - - - -
  // Print list of available serial ports (Useful for debugging).
  println ("Available serial ports:  ");
  printArray(Serial.list());
  println (" ");

  // Serial port to be used.  Change number in [brackets] as needed.
  String portName = Serial.list()[0]; // <--- *port number*
  // - - - - - - - - - - - - - - - - - -  - - - - - - - - - - - -


  myPort = new Serial(this, portName, 115200);  // Create the serial port.
  myPort.clear();   // Clear the serial port buffer.

  // Figure out how large to make the stage based on the layout and number of pixels.
  if (layout == "C") {
    // This seems to give a decent size based on the number of pixels in a circle.
    stageW = int(float((210 * NUM_LEDS)/19) + float(1800/19));  // width of stage draw area.
    stageH = stageW;  // Make the stage square for circles.
  }
  if (layout == "H") {
    stageW  = (NUM_LEDS + 1) * offset;  // width of stage draw area.
  }
  if (layout == "V") {        
    stageH  = (NUM_LEDS + 1) * offset;  // height of stage draw area.
  }
  if (layout == "M") {
    stageW  = (numberColumns + 1) * offset;  // width of stage draw area.
    stageH = (numberRows + 1) * offset;  // height of stage draw area.
  }
  if (stageW < stageMin) { stageW = stageMin; }  // Force at least a minimum stage width.
  if (stageH < stageMin) { stageH = stageMin; }  // Force at least a minimum stage height.

  size(stageW,stageH);    // Set the stage size.
  background(bgcolor);    // Set stage bg color. 
  smooth();               // Use anti-aliasing.
  noStroke();             // No border when drawing shapes.
  //colorMode(RGB, 255);  // Use Red, Green, Blue color mode.  Range from 0-255.
  colorMode(HSB, 255);    // Use Hue, Saturation, Brightness color mode.  Range from 0-255.
  rectMode(CENTER);       // Rectangles are positioned based on their center.
  ellipseMode(CENTER);    // Ellipses are positioned based on their center.

  if (direction == "R") {  // If direction is Reverse, make dir variable negitive.
    dir = -1;
  }
  if (scanStart == "B") {  //
    dirM = -1; 
  }
  if (layout == "C" || layout == "V") {  // Special case for circular layout.
    dir = dir * -1;  // Make circular "forward" travel clockwise.
  }
}//end setup()


//------------------------------------------------------------------------------
void draw() {
  // Inital draw of pixel boarders (the white part) and "off" (dark) pixels.
  // This first conditional check will only be true once, thus the pixel
  // boarders are only drawn one time at start and not over and over again.
  if (pixelNumber == 0 && firstContact == false){

    int boarderColor = 255;  // Pixel board color for first pixel.
    if (layout == "C") {  // Draw circular layout.
      degrees = 0;  // Angle to rotate pixel while drawing around the circular layout.
      r = NUM_LEDS * 5;  // Seems like a good ratio for scaling cirlce size based on number of pixels.
      translate(stageW/2, stageH/2);  // Temporarily move grid 0,0 to center of stage draw area.
      for (int i=0; i<NUM_LEDS; i++){
        dx = r * cos(radians(degrees));
        dy = dir * r * sin(radians(degrees));
        translate(dx,dy);  // Move to where we want to draw our pixel, relative from stage center.
        pushMatrix();  // "Push" so we can rotate the drawing grid.
        rotate(radians(dir * degrees));  // Rotate the pixel.
        colorMode(HSB, 255);  // Specify color mode, using range from 0-255.
        fill(0,0,boarderColor);  // HSB mode.  This is the outer boarder part of pixel.
        rect(0,0,pixelSize+3,pixelSize+3,3);  // center x, center y, width, height, corner radius
        fill(0,0,25);  // HSB mode.  This initally fills each pixel black (ie. pixel is "off").
        ellipse(0,0,pixelSize,pixelSize);  // center x, center y, width, height
        popMatrix();  // "Pop" drawing grid back to normal.
        translate(-1*dx,-1*dy);  // Move back to stage center.
        degrees = degrees - (360.0 / NUM_LEDS);  // Advance around circle. Minus gives counter clockwise.
        boarderColor -= 10;  // Darken pixel boarder color
        if (boarderColor < 200) {boarderColor = 180;}  // Clamp minimum boarder color
      }
    }//end cicular layout

    if (layout == "H" || layout == "V") {  // Draw horizontal or vertical layout.
      for (int i=0; i<NUM_LEDS; i++){
        if (layout == "H") {  // horizontal.
          xpos = float((stageW/2) - (dir*((NUM_LEDS-1) * offset)/2) + (i * offset * dir)); 
          ypos = float(stageH/2);
        }
        else {  // vertical.
          xpos = stageW/2;
          ypos = (stageH/2) - (dir*((NUM_LEDS-1) * offset)/2) + (i * offset * dir);
        }
        colorMode(HSB, 255);  // Specify color mode, using range from 0-255.
        fill(0,0,boarderColor);  // HSB mode = White part of pixel
        rect(xpos,ypos,pixelSize+3,pixelSize+3,3);  // center x, center y, width, height, corner radius
        fill(0,255,25);  // HSB mode
        ellipse(xpos,ypos,pixelSize,pixelSize);  // center x, center y, width, height
        boarderColor -= 10;  // Darken pixel boarder color
        if (boarderColor < 200) {boarderColor = 180;}  // Clamp minimum boarder color
      }
    }//end horizontal and vertical layout

    if (layout == "M") {  // Draw Matrix layout.
      //if (path == "S") {  // Path type serpentine.
      //}
      for (int j=0; j<numberRows; j++){  // rows
        ypos = (float(stageH)/2.0) - (dirM*float((numberRows-1))/2.0*offset) + (dirM * offset * j);
        for (int i=0; i<numberColumns; i++){  // columns
          xpos = (float(stageW)/2.0) - (dir*float((numberColumns-1))/2.0*offset) + (dir * offset * i);
          //print("i: " + i + " j:" + j + "    " + (i+1 + (j*numberColumns)));
          //println("    xpos: " + xpos + "    ypos: " + ypos);
          if ((i+1+(j*numberColumns)) <= NUM_LEDS) {  // If matrix is larger then NUM_LEDS, only draw actual pixels.
            colorMode(HSB, 255);  // Specify color mode, using range from 0-255.
            fill(0,0,boarderColor);  // HSB mode = White part of pixel
            rect(xpos,ypos,pixelSize+3,pixelSize+3,3);  // center x, center y, width, height, corner radius
            fill(0,255,25);  // HSB mode
            ellipse(xpos,ypos,pixelSize,pixelSize);  // center x, center y, width, height
            boarderColor -= 10;  // Darken pixel boarder color
            if (boarderColor < 200) {boarderColor = 180;}  // Clamp minimum boarder color
          }
        }
      }
    }//end matrix layout

  }//end conditional check
}//end draw() section


//------------------------------------------------------------------------------
void serialEvent(Serial myPort) {
  // Read a byte from the serial port.
  inByte = myPort.read();  // Read the incoming data.  Nom nom nom.
  if (testing_verbose == true) {
    print("inByte = " + inByte + "  \t ");  // Show what was nommed.
  }

  // If this is the first byte received, it should be an 'A'.  If
  // true, respond to Arduino by sending it a letter 'A' back.
  // Arduino will then send the number of pixels as a highByte and
  // lowByte number followed by a '#' sign to signal it's done.
  // Once we have this info, clear the buffer, update firstContact
  // to be true, and draw empty(off) pixels.  Then loop continuously
  // collecting the incoming bytes of pixel data.

  if (firstContact == false) {
    if (inByte == 'A') {  // Received as ASCII number 65.
      myPort.write('A');  // Respond to the arduino.
      println("Contact established...");
    }

    else {
      if (inByte != '#') {
        //Do this until we read an ASCII '#', received as number 35.
        if (serialCount == 0) {  // If true, receive highByte.
          receivedNUM_LEDS = inByte * 256;  // Multiply highByte by 256.
          if (testing == true) { println("highByte = " + receivedNUM_LEDS); }  // Print when debugging
        }
        else {  // We've already received highByte, so add lowByte now.
          receivedNUM_LEDS = receivedNUM_LEDS + inByte;  // Add lowByte to total. 
        }
        serialCount++;  // Increment count of the number of bytes stored in the array.
      }
      else {  // If true, it means we received '#' character and calculated NUM_LEDS.
        myPort.clear();       // Clear the serial port buffer to be ready for pixel data.
        serialCount = 0;      // Reset serial count before receiving more data.
        pixelNumber = 0;      // This will make the "draw pixel boarders" check in draw() true.
        if (NUM_LEDS != receivedNUM_LEDS) {  // Check if NUM_LEDS matches what the MCU is sending.
          if (checkNUM_LEDS == true) {
            println("**********************************************************************");
            println("  NUM_LEDS variable does not match the number of pixels sent by MCU!");
            println("  NUM_LEDS = " + NUM_LEDS + ", and number of pixels sent by MCU = " + receivedNUM_LEDS + ".");
            println("                          Processing halted.");
            println("**********************************************************************");
            exit();  // Exit the program.
          }
        }
        else {  // NUM_LEDS matches what MCU is sending.  Continue on.
          // Print out some info to confirm user choices.
          println("  NUM_LEDS = " + NUM_LEDS);
          if (layout == "C") {
            print("  layout: [" + layout + "]ircular");
            println("   (Number of degrees per pixel = " + (360.0/NUM_LEDS) + ")");
          }
          if (layout == "H") {
            println("  layout: [" + layout + "]orizontal");
          }
          if (layout == "V") {
            println("  layout: [" + layout + "]ertical");
          }
          if (layout == "M") {
            print("  layout: [" + layout + "]atrix");
            println("    numberColumns = " + numberColumns + ",  numberRows = " + numberRows);
            print("    scanStart: [" + scanStart);
            if (scanStart == "T") {
              println("]op");
            }
            else {
              println("]ottom");
            } 
            print("    Path type: [" + path);
            if (path == "Z") {
              println("]igzag");
            }
            else {
              println("]erpentine.  *** SERPENTINE path is not available yet! *** Processing halted. ***");
              exit();  // Exit the program.
            }
          }

          if (direction == "F") {
            println("    direction: [" + direction + "]orward");
          }
          else {
            println("    direction: [" + direction + "]everse");
          }
          
          if (NUM_LEDS > (numberColumns * numberRows)) { 
            println("**********************************************************************");
            println("  NUM_LEDS is greater then numberColumns * numberRows [ " + (numberColumns * numberRows) + " ]"); 
            println("  Please check the values of these variables.  Processing halted.");
            println("**********************************************************************");
            exit();  // Exit the program.
          }
        }

        delay(200);  // *Required short delay* to guarantee "draw pixel boarders" in draw() becomes true.
        firstContact = true;  // First contact info from the microcontroller finished!
        delay(100);
      }
    }
  }//End of initail first contact and receiving number of pixels.


  else {  // Add the byte data for pixel info to the serial storage array.
    serialArray[serialCount] = inByte;  //  Nom nom nom!

    if (testing_verbose == true) {  // Print a bunch of values for debugging
      if (serialCount % 4 == 0) {  // Test if number is divisible by 4, aka a pixel numbers.
        println(" --> serialArray[" + serialCount + "] = " + serialArray[serialCount] + "    <-- pixel number");
      }
      else {  // number is not divisible by 4, aka pixel color data.
        println("     serialArray[" + serialCount + "] = " + serialArray[serialCount] + " ");
      }
    }//end testing stuff.

    serialCount++;  // Increment count of the number of bytes stored in the array.
    if (serialCount == (NUM_LEDS*4)) {  // True when we have all the data for the LED strip.
      if (testing == true) { println("--------------------------------------------------------------------------------"); }  // Print when debugging

      for (int p=0; p < NUM_LEDS; p++) {  // Loop over pixels
        // Find pixel's R,G,B values.
        redChan   = serialArray[(4*p)+1];  // Red value. 
        greenChan = serialArray[(4*p)+2];  // Green value.
        blueChan  = serialArray[(4*p)+3];  // Blue value.
        if (testing == true) {  // Print values for debugging
          print("  pixelNumber " + p);
          println("\t\t redChan " + redChan + "\t greenChan " + greenChan + "\t blueChan " + blueChan);
        }
        colorMode(RGB, 255);                     // Specify color mode, using range from 0-255.
        fill(redChan,greenChan,blueChan);        // Set fill color based on the RGB data we received.

        if (layout == "C") {  // Draw circular pixels.
          dx = r * cos(radians(degrees));
          dy = dir * r * sin(radians(degrees));
          xpos = (float(stageW)/2.0)+dx;  // x postion from center stage.
          ypos = (float(stageH)/2.0)+dy;  // y postion from center stage.
          degrees = degrees - (360.0 / NUM_LEDS);  // Rotate to next position around the circle.
        }

        if (layout == "H") {
          xpos = (stageW/2) - (dir*((NUM_LEDS-1) * offset)/2) + (serialArray[4*p] * offset * dir);
          ypos = stageH/2;
        }

        if (layout == "V") {
          xpos = stageW/2;
          ypos = (stageH/2) - (dir*((NUM_LEDS-1) * offset)/2) + (serialArray[4*p] * offset * dir);
        }

        if (layout == "M") {
          xpos = (float(stageW)/2.0) - (dir*float((numberColumns-1))/2.0*offset) + (dir*offset*cCount);
          ypos = (float(stageH)/2.0) - (dirM*float((numberRows-1))/2.0*offset) + (dirM*offset*rCount);
          //print("    cCount: " + cCount + "    rCount: " + rCount);
          //print("    "+(cCount+1)+"+"+(rCount*numberColumns)+"="+(cCount+1+(rCount*numberColumns)));
          //println("    xpos: " + xpos + "    ypos: " + ypos);
          cCount++;  // Increment column counter.
          if ((cCount+(rCount*numberColumns)) == NUM_LEDS) {  // If matrix is larger then NUM_LEDS, only draw actual pixels.
            cCount = 0;
            rCount = 0;
          }
          else if (cCount == (numberColumns)) {
            cCount = 0;  // Reset column counter.
            rCount++;  // Increment to move to next row.
            if (rCount == numberRows) { rCount = 0; }  // Reset to zero.
          }
        }

        // Draw the pixel!
        ellipse(xpos,ypos,pixelSize,pixelSize);  // center x, center y, width, height
      
      }//end of looping over pixels
      serialCount = 0;  // Reset serial count before receiving more data.
      myPort.clear();   // Clear the serial port buffer.
    } 
  }
} //end serialEvent loop


//==============================================================================


/*------------------------------------------------------------------------------
TODO/ideas:
  - Impliment "Serpentine" path option.
  - Option for specifying pixel zero location (ie. 90,180,etc, degrees) on circlular layouts.
  - Matrix with vertical strips option?
  - CC colors in Processing to better match LEDs?  Maybe gamma correction option?
  - Add some info text to stage draw area?
      A few pixel numbers or "->" to show layout direciton?
  - Do we need to send NUM_LEDS and pixel number from MCU to Processing?
      Or would just the color data be fine when specify the NUM_LEDS in Processing?
  - Any sort of error checking needed?
  - Check use of casting int to float.  (float)n vs float(n)
  - 
  
------------------------------------------------------------------------------*/
