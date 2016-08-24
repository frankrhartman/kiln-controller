
import processing.serial.*;

Serial myPort;      // Create object from Serial class
int lf = 10;        // ASCII linefeed
String inBuffer;    // input buffer to hold serial data
PrintWriter output; // output file stream
String filename;    // our filename

ArrayList temp_hist;   // ArrayList to hold temp history
ArrayList time_hist;   // ArrayList to hold time history
float last_temp;
boolean clean_start = false;

FH_plot my_plot;
FH_graph_data data;

color bg_color = color(200, 200, 200);
color fg_color = color(240, 240, 240);
color line_color = color(129, 129, 129);
color text_color = color(80, 80, 80);
color plot_color = color(255, 0, 0);

PFont font = createFont("arial", 12);

void setup() 
{ 
  size(1000, 800);

  // List all the available serial ports:
  println("Available serial ports:");
  println(Serial.list());

  // Open whatever serial port you are using
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);

  // buffer until a linefeed character
  // then trigger serialEvent callback
  myPort.bufferUntil(lf);

  // open a log file for writing e.g. "07-14-2012-1038.log"
  filename = month() + "-" + day() + "-" + year() + "-" + hour() + minute() + ".log";
  output = createWriter(filename);

  // create space to store time and temp history data
  temp_hist = new ArrayList();
  time_hist = new ArrayList();

  data = new FH_graph_data();

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
  if (inBuffer != null) {
    background(220);

    // then split into tokens to display and graph
    String[] tokens = splitTokens(inBuffer, ",");
    float ctemp;
    if (tokens[1] == "ERROR") ctemp = 0.0;
    else ctemp = float(tokens[1]);
    float time = float(tokens[0]);
    float ftemp = ctemp *(9.0/5.0) + 32.0;

    // Add time and ctemp to ArrayList histories
    temp_hist.add(ctemp);
    time_hist.add(time);
    last_temp = ctemp;

    fill(text_color);
    textSize(20);
    textAlign(LEFT);
    text("Temp:  " + ctemp + " \u00B0C", 50, 700);  
    text("Temp:  " + ftemp + " \u00B0F", 270, 700);
    text("Firing Time:  " + nf(time/60, 4, 1) + " Minutes", 500, 700);
    text("Rate:  " + calculate_temp_rate() + " C/hr", 800, 700);
    textSize(12);
    text("Logging to file:  " + filename, 50, 750);

    // only log after we had seen a zero time value
    // to eliminated logging of junk on the serial port
    if (time==0) clean_start = true;
    text("Serial Data Received:  " + inBuffer, 700, 750);
    if (clean_start) {
      // append string to firing log file
      output.print(inBuffer);

      // add data to running graph
      data.addPoint(time, ctemp);
      my_plot.set_data(data);
    }

    my_plot.draw_plot();
    // set inBuffer to NULL to prevent needless redraws
    inBuffer = null;
  }
}

void serialEvent(Serial p) {
  // read from the serial port
  inBuffer = (myPort.readString());
}

float calculate_temp_rate()
{
  if (temp_hist.size() > 2) {
    // FIXME Calculate temp rate based on recent history
    int last_temp = temp_hist.size()-1;
    float delta_temp = ((Float)temp_hist.get(last_temp)).floatValue() - ((Float)temp_hist.get(last_temp-1)).floatValue();
    int last_time = time_hist.size()-1;
    float delta_time = ((Float)time_hist.get(last_time)).floatValue() - ((Float)time_hist.get(last_time-1)).floatValue();

    float rate_temp_sec = delta_temp/delta_time;
    float rate_temp_hr = rate_temp_sec * 360;
    return(rate_temp_hr);
  } 
  else {
    return 0.0;
  }
}

void keyPressed() { // Press a key to close the file and cleanly exit
  output.flush(); // Write the remaining data
  output.close(); // Finish the file
  exit(); // Stop the program
}


