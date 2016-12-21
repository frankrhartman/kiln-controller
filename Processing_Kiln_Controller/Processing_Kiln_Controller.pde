/*
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
*/

import processing.serial.*;
import java.nio.ByteBuffer;
import java.util.*;
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
// max temperature reached
float max_temp = 0.0;
// did we get a START message from arduino yet?
// else get rid of junk on the serial bus
boolean clean_start = false;

// setpoint override
boolean override = false;
public float override_value = 1000;

// the ramp controller
FH_ramp_hold my_controller;

List ramp_names = Arrays.asList("980 Hold", "Ron Roy", "creepy mattes", "creepy gloss", "creepy bisque", "test");
float ramps[][][] = {
                      { {55, 105, 0}, {180, 1185, 0}, {-250, 980, 60}, {0, 0, 0} },                                  //980 Hold
                      { {55, 105, 0}, {200, 1080, 0}, {85, 1200, 15}, {-275, 1000, 0}, {-70, 760, 0}, {0, 0, 0} },   //Ron Roy
                      { {55, 105, 0}, {180, 1185, 15}, {-500, 1000, 0}, {-50, 700, 0}, {0, 0, 0} },                  //creepy mattes
                      { {180, 1185, 15}, {-500, 1085, 30}, {0, 0, 0} },                                              //creeoy gloss
                      { {55, 105, 0}, {180, 1070, 15}, {0, 0, 0} },                                                  //creepy bisque
                      { {50, 30, 0}, {100, 50, 2}, {-10, 45, 0}, {0, 0, 0} }                                        //test
                    };

float current_ramp[][] = {{0, 0, 0}};

String cone_names[] = {"022", "021", "020", "019", "018", "017", "016", "015", "014", "013", "012", "011",
                       "010", "09", "08", "07", "06", "05", "04", "03", "02", "01", "1", "2", "3", "4",
                       "5", "6", "7", "8", "9", "10"};
                       
float cones[][] = { {1049,1087,1094},
                    {1076,1112,1143},
                    {1125,1159,1180},
                    {1213,1252,1283},
                    {1267,1319,1353},
                    {1301,1360,1405},
                    {1368,1422,1465},
                    {1382,1456,1504},
                    {1395,1485,1540},
                    {1485,1539,1582},
                    {1549,1582,1620},
                    {1575,1607,1641},
                    {1636,1657,1679},
                    {1665,1688,1706},
                    {1692,1728,1753},
                    {1764,1789,1809},
                    {1798,1828,1855},
                    {1870,1888,1911},
                    {1915,1945,1971},
                    {1960,1987,2019},
                    {1972,2016,2052},
                    {1999,2046,2080},
                    {2028,2079,2109},
                    {2034,2088,2127},
                    {2039,2106,2138},
                    {2086,2124,2161},
                    {2118,2167,2205},
                    {2165,2232,2269},
                    {2194,2262,2295},
                    {2212,2280,2320},
                    {2235,2300,2336},
                    {2284,2345,2381} };

// for the running plot
FH_plot my_plot;
FH_kiln_data data;

// when to redraw screen
int last_draw = 0;
int draw_interval = 1000;

// colors for the display
color bg_color = color(0, 0, 0);
color button_color = color(0,0,255);
color button_active_color = color(0,255,255);
color plot_fg_color = color(0, 0, 0);
color line_color = color(129, 129, 129);
color text_color = color(255, 255, 255);
color plot_color = color(255, 0, 0);
int pad = 5; // border around UI elements

// UI positions
int  right_x = 512;  
int bot_y = 600;
int bot_line = 50;

void setup() { 
  size(1024, 768);
  surface.setTitle("supercreeps");
  //fullScreen();  //doesn't work correctly

  // ramp / hold controller
  my_controller = new FH_ramp_hold(current_ramp);

  setup_UI();

  // List all the available serial ports:
  //println("Available serial ports:");
  //println(Serial.list());

  // Open whatever serial port you are using
  // Add UI to select serial port form list instead of printing
  //String portName = Serial.list()[0];
  String portName = "/dev/pts/11"; //For coding without an Arduino attached see tty0tty.c
  myPort = new Serial(this, portName, 9600);
  // buffer until a linefeed character
  // then trigger serialEvent callback
  myPort.bufferUntil(lf);

  // open a log file for writing e.g. "07-14-2012-1038.csv"
  filename = "/home/frank/kiln_logs/" + month() + "-" + day() + "-" + year() + "-" + hour() + minute() + ".csv";
  output = createWriter(filename);

  // create space to store time, temp, setpoint, and controller history data
  temp_hist = new ArrayList();
  time_hist = new ArrayList();
  set_hist = new ArrayList();
  controller_hist = new ArrayList();

  data = new FH_kiln_data();

  smooth();

  my_plot = new FH_plot(512+pad, 300+pad, 1023-pad, 667-pad);
  my_plot.set_data(data);
  my_plot.title = "Kiln Temperature";
  my_plot.bg_color = bg_color;
  my_plot.fg_color = plot_fg_color;
  my_plot.text_color = text_color;
  my_plot.plot_color = plot_color;
}

void draw() {
  // time to redraw screen
  if (millis() - last_draw > draw_interval) {
    background(bg_color);
    // draw everything
    my_plot.draw_plot();
    draw_text();
    last_draw = millis();
  }
}
  
void setup_UI() {
  
  int butt_size =75;
  int butt_line = 0;

  cp5 = new ControlP5(this);

  cp5.addBang("START")
    .setPosition(right_x+pad, butt_line*butt_size+pad)
    .setSize(256-2*pad, butt_size-2*pad)
    .setColorActive(button_active_color)
    .setColorForeground(button_color)
    .setColorCaptionLabel(text_color)
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;   

  cp5.addBang("STOP")
    .setPosition(right_x+256+pad, butt_line++*butt_size+pad)
    .setSize(256-2*pad, butt_size-2*pad)
    .setColorActive(button_active_color)
    .setColorForeground(button_color)
    .setColorCaptionLabel(text_color)
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;      
    
  cp5.addBang("PREV")
    .setPosition(right_x+pad, butt_line*butt_size+pad)
    .setSize(256-2*pad, butt_size-2*pad)
    .setColorActive(button_active_color)
    .setColorForeground(button_color)
    .setColorCaptionLabel(text_color)
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;
    
  cp5.addBang("NEXT")
    .setPosition(right_x+256+pad, butt_line++*butt_size+pad)
    .setSize(256-2*pad, butt_size-2*pad)
    .setColorActive(button_active_color)
    .setColorForeground(button_color)
    .setColorCaptionLabel(text_color)
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ; 


  cp5.addToggle("override")
    .setPosition(right_x+pad, butt_line*butt_size+pad)
    .setSize(256-2*pad, butt_size-2*pad)
    .setColorActive(button_active_color)
    .setColorBackground(button_color) 
    .setColorForeground(button_color)
    .setColorCaptionLabel(text_color)
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;
  cp5.addNumberbox("override_value")
    .setPosition(right_x+256+pad, butt_line++*butt_size+pad)
    .setSize(256-2*pad, butt_size-2*pad)
    .setRange(0, 1500)
    .setMultiplier(1) // set the sensitifity of the numberbox
    .setDirection(Controller.HORIZONTAL) // change the control direction to left/right
    .setValue(1000)
    .setColorActive(text_color)
    .setColorBackground(button_color)
    .setColorForeground(button_color)
    .setColorCaptionLabel(text_color)
    .setColorValueLabel(text_color)
    .setCaptionLabel("")
    .getValueLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;
 
  cp5.addBang("QUIT")
    .setPosition(right_x+pad,668+pad)
    .setSize(512-2*pad, 100-2*pad)
    .setColorActive(button_active_color)
    .setColorForeground(color(255,0,0))
    .setColorCaptionLabel(text_color)
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;
    
  cp5.addScrollableList("RAMPS")
     .setPosition(right_x+pad, butt_line*butt_size+pad)
     .setSize(512-2*pad, 300-2*pad)
     .setBarHeight(butt_size-2*pad)
     .setItemHeight(butt_size-2*pad)
     .setColorForeground(button_color)
     .setColorActive(button_active_color)
     .setColorBackground(button_color)
     .setOpen(false)
     .addItems(ramp_names)
     .setCaptionLabel("select ramp")
     ;
    
 ControlFont font = new ControlFont(createFont("Arial",20));
 cp5.getController("RAMPS").getCaptionLabel().setFont(font).toUpperCase(false).setSize(40);
 cp5.getController("RAMPS").getCaptionLabel().getStyle().setPaddingTop(10);
 cp5.getController("RAMPS").getCaptionLabel().getStyle().setPaddingLeft(20);
 cp5.getController("QUIT").getCaptionLabel().setFont(font).toUpperCase(false).setSize(40);
 cp5.getController("START").getCaptionLabel().setFont(font).toUpperCase(false).setSize(40);
 cp5.getController("STOP").getCaptionLabel().setFont(font).toUpperCase(false).setSize(40);
 cp5.getController("PREV").getCaptionLabel().setFont(font).toUpperCase(false).setSize(40);
 cp5.getController("NEXT").getCaptionLabel().setFont(font).toUpperCase(false).setSize(40);
 cp5.getController("override").getCaptionLabel().setFont(font).toUpperCase(true).setSize(40);
 cp5.getController("override_value").getValueLabel().setFont(font).toUpperCase(false).setSize(40);
}

void RAMPS(int n) {
  if(my_controller.get_state() == 99) {
    current_ramp = ramps[n];
    my_controller.set_ramps(current_ramp);
    cp5.getController("RAMPS").setColorBackground(button_color);
  } else cp5.getController("RAMPS").setColorBackground(color(255,0,0));
}

public void NEXT() {
  // go to next ramp segment
  my_controller.next_ramp();
}

public void PREV() {
  // go to previous ramp segment
  my_controller.prev_ramp();
}

// Start the firing cycle
public void START() {
  my_controller.set_init_temp(ctemp);
  my_controller.start();
}

// Stop the firing cycle no matter what ramp we are on
public void STOP() {
  my_controller.stop();
}

// Quit the program if not firing.
public void QUIT() {
  if(my_controller.get_state() == 99) {
    output.flush(); // Write the remaining data
    output.close(); // Finish the file
    myPort.clear();
    myPort.stop(); // close the serial port
    exit(); // Stop the program
  }
}


void draw_text() {
  
  fill(color(0,255,0));
  noStroke();
  rect(0+pad, 0+pad, 512-pad, 100-pad);
  rect(0+pad, 100+pad, 512-pad, 200-pad);
  rect(0+pad, 200+pad, 512-pad, 300-pad);
  
  // draw all text
  fill(color(0,0,0));
  textSize(40);
  textAlign(LEFT);
  
  int lcol=40;
  int mcol=150;
  int rcol=mcol+150;
  int rmarg = 512;
  int line1=60;
  int line2=160;
  int line3=260;
  int ramps_line=300+pad;
  
  text("M", lcol, line1);
  text(String.format("%.1f", max_temp) + " C", mcol, line1);
  text(get_cone_text(max_temp), rcol, line1);
  
  text("T", lcol, line2);
  text(String.format("%.1f", ctemp) + " C", mcol, line2);
  text(String.format("%.1f", ftemp) + " F", rcol, line2);
  
  text("S", lcol, line3);
  text(String.format("%.1f", setpoint) + " C", mcol, line3);
  text(String.format("%.1f", calculate_temp_rate()) + " C/hr", rcol, line3);

  int tsize=25;
  lcol += 30;
  textSize(tsize);
  textAlign(RIGHT, TOP);
  // draw ramps
  int num_ramps = current_ramp.length;
  for (int i = 0; i < num_ramps; i++) {
    int cline = ramps_line+(i*tsize*2)+pad*i*2;
    
    // draw boxes around ramps - orange if current yellow otherwise
    if(my_controller.get_ramp_num()==i && my_controller.get_state() != 99) fill(color(255,128,0));
    else fill(color(255,255,0));
    noStroke();
    rect(0+pad, cline, 512-pad, cline+tsize*2);
    
    // draw red rectangle around value if holding
    //if(my_controller.get_state() == 1) {
    if(my_controller.get_ramp_num()==i && my_controller.get_state() == 2){
     stroke(255,0,0);
     strokeWeight(5);
     rect(360, cline+pad, 512-2*pad, cline+tsize*2-pad);
    }
    
    // now draw numeric ramp values
    fill(color(0,0,0));
    text(i+1, lcol,cline+tsize/2);
    text(String.format("%.1f", current_ramp[i][0]), lcol+120, cline+tsize/2);
    text(String.format("%.1f", current_ramp[i][1]), lcol+260, cline+tsize/2);
    text(String.format("%.1f", current_ramp[i][2]), lcol+380, cline+tsize/2);
  }
    
  //textSize(12);
  //text("FILE:  " + filename, 520, 660);
  //text("Serial Data Received:  " + inBuffer, 500, bot_y+bot_line*2);
  //int offset=40;
  //int col_start=200;
  //text("State:  " + my_controller.get_state(), right_x, col_start);
  //text("Ramp #:  " + my_controller.get_ramp_num(), right_x, col_start+offset);
  //text("Rate:  " + my_controller.get_current_ramp(), right_x, col_start+offset*2);
  //text("Target:  " + my_controller.get_current_target(), right_x, col_start+offset*3);
  //text("Hold:  " + my_controller.get_current_hold(), right_x, col_start+offset*4);
  //text("Heat_Cool:  " + my_controller.get_heat_cool(), right_x, col_start+offset*5);
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
    // Log only every 10 seconds
    if(time % 10 == 0) output.print(inBuffer);

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

float calculate_temp_rate() {
  // try a least squares method over 30 seconds
  //if (temp_hist.size() > 30) {
  //  float temp_mean = 0.0;
  //  float time_mean = 0.0;
  //  float t_sum = 0.0;
  //  float b_sum = 0.0;
  //  int temp_size = temp_hist.size();
  //  for(int j=0;j<30;j++) {
  //    temp_mean += (Float) temp_hist.get(temp_size-j-1);
  //  }
  //  temp_mean /= 30.0;
  //  time_mean = 14.5;
  //  for(int j=0;j<30;j++) {
  //    t_sum += ((Float)temp_hist.get(temp_size-j-1)-temp_mean)*(j-time_mean);
  //    b_sum += ((Float)temp_hist.get(temp_size-j-1)-temp_mean)* ((Float)temp_hist.get(temp_size-j-1)-temp_mean);
  //  }
  //  float m = t_sum/b_sum; // m is slope of least squares linear fit
  //  return(m*3600.0);  // convert to C/Hr from C/sec
  //} else {
  //  return 0.0;
  //}
  
  // old code
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

// return orton cone string based on kiln temperature and rate
// FIXME modify to use rate
String get_cone_text(float temp_in) {
  String cone_text = "C99";
  for(int i=0;i<cones.length;i++) {
    if(temp_in > cones[i][0]) cone_text = cone_names[i];
  }
  return(cone_text);
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