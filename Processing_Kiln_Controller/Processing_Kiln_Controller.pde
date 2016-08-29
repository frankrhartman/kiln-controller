=====================================================================
Copyright (C) 2016  Frank R. Hartman

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>
=====================================================================

import processing.serial.*;
import java.nio.ByteBuffer;
import controlP5.*;

ControlP5 cp5;

Serial myPort;      // Create object from Serial class
int lf = 10;        // ASCII linefeed
String inBuffer;    // input buffer to hold serial data
PrintWriter output; // output file stream
String filename;    // our filename

ArrayList temp_hist;   // ArrayList to hold temp history
ArrayList time_hist;   // ArrayList to hold time history
ArrayList set_hist;   // ArrayList to hold setpoint history
ArrayList controller_hist;   // ArrayList to hold controller history

// current values from arduino
float ctemp;
float setpoint;
float controller_out;
float ftemp;
float time;

// setpoint override
boolean override = false;
public float override_value = 1000;

// the ramp controller
FH_ramp_hold my_controller;

// ramps for the controller
float ramp_980_hold[][] = {
  {180, 550, 0}, 
  {90, 1102, 0}, 
  {60, 1185, 0}, 
  {-250, 980, 60}, 
  {0, 0, 0}
};

float ramp_ron_roy[][] = {
  {55, 105, 0}, 
  {200, 1080, 0}, 
  {85, 1200, 15}, 
  {-275, 1000, 0}, 
  {-70, 760, 0}, 
  {0, 0, 0}
};

float ramp_creepy_mattes[][] = {
  {180, 550, 0}, 
  {90, 1102, 0}, 
  {60, 1185, 15}, 
  {-500, 1000, 0}, 
  {-50, 700, 0}, 
  {0, 0, 0}
};

float ramp_creepy_mattes_cool[][] = {
  {60, 1170, 15}, 
  {-500, 1000, 0}, 
  {-50, 700, 0}, 
  {0, 0, 0}
};

float ramp_creepy_gloss[][] = {
  {180, 1185, 15}, 
  {0, 0, 0}
};

float ramp_test[][] = {
  {600, 50, 5}, 
  {-1, 45, 0}, 
  {0, 0, 0}
};

float current_ramp[][] = ramp_test;

// max temperature reached
float max_temp = 0.0;

// did we get a START message from arduino yet
// else get rid of junk on the serial bus
boolean clean_start = false;

// for the running plot
FH_plot my_plot;
FH_kiln_data data;

// when to redraw screen
int last_draw = 0;
int draw_interval = 1000;

// colors for the display
color bg_color = color(200, 200, 200);
color fg_color = color(240, 240, 240);
color line_color = color(129, 129, 129);
color text_color = color(80, 80, 80);
color plot_color = color(255, 0, 0);

PFont font;

void setup() { 
  size(1150, 850);

  font = createFont("arial", 12);

  // ramp / hold controller
  my_controller = new FH_ramp_hold(current_ramp);

  setup_UI();

  // List all the available serial ports:
  println("Available serial ports:");
  println(Serial.list());

  // Open whatever serial port you are using
  // Add UI to select serial port form list instead of printing
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);
  // buffer until a linefeed character
  // then trigger serialEvent callback
  myPort.bufferUntil(lf);

  // open a log file for writing e.g. "07-14-2012-1038.log"
  filename = month() + "-" + day() + "-" + year() + "-" + hour() + minute() + ".log";
  output = createWriter(filename);

  // create space to store time, temp, setpoint, and controller history data
  temp_hist = new ArrayList();
  time_hist = new ArrayList();
  set_hist = new ArrayList();
  controller_hist = new ArrayList();

  data = new FH_kiln_data();

  smooth();

  my_plot = new FH_plot(50, 50, 950, 650);
  my_plot.set_data(data);
  my_plot.title = "Kiln Temperature";
  my_plot.plot_color = color(128, 128, 128);
  my_plot.bg_color = bg_color;
  my_plot.fg_color = fg_color;
  my_plot.text_color = text_color;
  my_plot.plot_color = plot_color;
}

void draw() {
  // time to redraw screen
  if (millis() - last_draw > draw_interval) {
    background(220);
    // draw everything
    my_plot.draw_plot();
    draw_text();
    last_draw = millis();
  }
}

void setup_UI() {

  cp5 = new ControlP5(this);

  cp5.addBang("START")
    .setPosition(1000, 50)
    .setSize(100, 40)
    .setColorActive(fg_color)
    .setColorBackground(bg_color)
    .setColorForeground(bg_color)
    .setColorCaptionLabel(text_color)
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;   

  cp5.addBang("STOP")
    .setPosition(1000, 100)
    .setSize(100, 40)
    .setColorActive(fg_color)
    .setColorBackground(bg_color)
    .setColorForeground(bg_color)
    .setColorCaptionLabel(text_color)
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;      
  cp5.addBang("QUIT")
    .setPosition(1000, 750)
    .setSize(100, 40)
    .setColorActive(fg_color)
    .setColorBackground(bg_color)
    .setColorForeground(bg_color)
    .setColorCaptionLabel(text_color)
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;

  cp5.addToggle("override")
    .setPosition(1000, 650)
    .setSize(100, 40)
    .setColorActive(fg_color)
    .setColorBackground(bg_color)
    .setColorForeground(bg_color)
    .setColorCaptionLabel(text_color)
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;
  cp5.addNumberbox("override_value")
    .setPosition(1000, 700)
    .setSize(100, 20)
    .setRange(0, 1500)
    .setMultiplier(1) // set the sensitifity of the numberbox
    .setDirection(Controller.HORIZONTAL) // change the control direction to left/right
    .setValue(1000)
    .setColorActive(text_color)
    .setColorBackground(bg_color)
    .setColorForeground(bg_color)
    .setColorCaptionLabel(text_color)
    .setColorValueLabel(text_color)
    .setCaptionLabel("")
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;
}

public void START() {
  my_controller.set_init_temp(ctemp);
  my_controller.start();
}

public void STOP() {
  my_controller.stop();
}

public void QUIT() {
  output.flush(); // Write the remaining data
  output.close(); // Finish the file
  myPort.clear();
  myPort.stop(); // close the serial port
  exit(); // Stop the program
}


void draw_text() {
  // draw all text
  fill(text_color);

  textSize(20);
  textAlign(LEFT);
  text("Temp:  " + ctemp + " \u00B0C", 50, 700);  
  text("Temp:  " + ftemp + " \u00B0F", 270, 700);
  text("Firing Time:  " + nf(time/60, 4, 1) + " Minutes", 500, 700);
  text("Rate:  " + calculate_temp_rate() + " C/hr", 800, 700);
  text("Max:  " + max_temp + " C", 800, 750);
  text("Set:  " + setpoint + " \u00B0C", 50, 750);
  text("Set:  " + (setpoint*(9.0/5.0)+32.0) + " \u00B0F", 270, 750);  
  text("Controller:  " + controller_out*100 + "%", 500, 750);

  textSize(12);
  text("Logging to file:  " + filename, 50, 800);
  text("Serial Data Received:  " + inBuffer, 700, 800);

  textSize(16);
  text("State:  " + my_controller.get_state(), 1000, 200);
  text("Ramp #:  " + my_controller.get_ramp_num(), 1000, 250);
  text("Rate:  " + my_controller.get_current_ramp(), 1000, 300);
  text("Target:  " + my_controller.get_current_target(), 1000, 350);
  text("Hold:  " + my_controller.get_current_hold(), 1000, 400);
  text("Heat_Cool:  " + my_controller.get_heat_cool(), 1000, 450);

  textSize(10);
  for (int i = 0; i < current_ramp.length; i++) {
    for (int j = 0; j < 3; j++) {
      text(current_ramp[i][j], 975+j*60, 500+i*25);
    }
  }
}

void processSerial() {
  // split into tokens and parse
  //println(inBuffer);
  if(inBuffer.substring(0,5).equals("START")) {
    println("Got start message - Begin logging");
    clean_start = true;
    return;
  }

  String[] tokens = splitTokens(inBuffer, ",");

  if (clean_start) {
    if (tokens[1] == "ERROR") ctemp = 0.0;
    else ctemp = float(tokens[1]);
    time = float(tokens[0]);
    setpoint = float(tokens[2]);
    controller_out = float(tokens[3]);
    ftemp = ctemp *(9.0/5.0) + 32.0;

    if (ctemp > max_temp) max_temp = ctemp;

    // Add time and ctemp to ArrayList histories
    temp_hist.add(ctemp);
    time_hist.add(time);
    set_hist.add(setpoint);
    controller_hist.add(controller_out);

    // only log after we had seen a zero time value
    // to eliminate logging of junk on the serial port
    if (time==0) clean_start = true;

    // append string to firing log file
    output.print(inBuffer);

    // add data to running graph
    data.addPoint(time, ctemp, setpoint);
    my_plot.set_data(data);

    // update the ramp controller
    my_controller.setTime(time);
    my_controller.setTemp(ctemp);
    my_controller.calculate();
    setpoint = my_controller.getSetpoint();

    if (override) setpoint = override_value;

    //send new setpoint back to arduino
    Send_To_Arduino();
  }
}

void serialEvent(Serial p) {
  // read from the serial port
  inBuffer = (myPort.readString());
  processSerial();
}

float calculate_temp_rate()
{
  if (temp_hist.size() > 120) {

    float temp_sum = 0.0;
    for (int j = 0; j <= 2; j++) {
      temp_sum += (Float) temp_hist.get(temp_hist.size()-j*30-1);
    }
    float temp_avg1 = temp_sum / 3.0;

    temp_sum = 0.0;
    for (int j = 2; j <= 4; j++) {
      temp_sum += (Float) temp_hist.get(temp_hist.size()-j*30-1);
    }
    float temp_avg2 = temp_sum / 3.0;

    float rate = ((temp_avg1 - temp_avg2) / 60.0) * 3600.0;
    return rate;
  } else { 
    return 0.0;
  }
}

void keyPressed() {
}

// Sending Floating point values to the arduino
// is a huge pain.  if anyone knows an easier
// way please let know.  the way I'm doing it:
// - Take the 6 floats we need to send and
//   put them in a 6 member float array.
// - using the java ByteBuffer class, convert
//   that array to a 24 member byte array
// - send those bytes to the arduino
void Send_To_Arduino()
{
  float[] toSend = new float[1];

  toSend[0] = setpoint;

  myPort.write(floatArrayToByteArray(toSend));
} 


byte[] floatArrayToByteArray(float[] input)
{
  int len = 4*input.length;
  int index=0;
  byte[] b = new byte[4];
  byte[] out = new byte[len];
  ByteBuffer buf = ByteBuffer.wrap(b);
  for (int i=0; i<input.length; i++) 
  {
    buf.position(0);
    buf.putFloat(input[i]);
    for (int j=0; j<4; j++) out[j+i*4]=b[3-j];
  }
  return out;
}
