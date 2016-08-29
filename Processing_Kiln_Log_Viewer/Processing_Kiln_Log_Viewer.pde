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

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import controlP5.*;



ControlP5 cp5;

FH_plot my_plot;
FH_graph_data data;

color bg_color = color(200, 200, 200);
color fg_color = color(240, 240, 240);
color line_color = color(129, 129, 129);
color text_color = color(80, 80, 80);
color plot_color = color(255,0,0);

PFont font;

String logfile = "No logfile loaded.";

void setup() {
  size(1000, 800);

  font = createFont("arial", 12);

  setup_UI();

  // graph data from a comma seperated file
  //data = new FH_graph_data("logs/" + logfile);
  data = new FH_graph_data();

  smooth();

  my_plot = new FH_plot(50, 50, 950, 700);
  my_plot.set_data(data);
  my_plot.title = logfile;
  my_plot.plot_color = color(128, 128, 128);
  my_plot.bg_color = bg_color;
  my_plot.fg_color = fg_color;
  my_plot.text_color = text_color;
  my_plot.plot_color = plot_color;
}


void draw() {
  background(220);
  my_plot.draw_plot();
}

public void load() {
  logfile = cp5.get(Textfield.class, "Logfile Name").getText();
  if(logfile.length() > 2) {
    println("Setting filename to: " + logfile);
    my_plot.set_data(new FH_graph_data(logfile));
    my_plot.title = logfile;
  } else {
    println("Please choose a logfile to load.");
  }
}

public void set() {
  println("Bring up file browser");
  String filename = loadFile(new Frame(), "Open Kiln Log File", "", "");
  if(filename != null) {
    println("Filename is: " + filename);
    cp5.get(Textfield.class, "Logfile Name").setText(filename);
  }

}

void keyPressed() {
}

void setup_UI() {

  cp5 = new ControlP5(this);

  cp5.addTextfield("Logfile Name")
    .setPosition(200, 730)
      .setSize(600, 40)
        .setFont(font)
          .setFocus(true)
            .setColor(text_color)
              .setColorBackground(bg_color)
                .setColorActive(bg_color)
                  .setColorForeground(bg_color)
                    .setColorCaptionLabel(text_color)
                      //.setLabel("")
                      ;


  cp5.addBang("load")
    .setPosition(850, 730)
      .setSize(100, 40)
        .setColorActive(fg_color)
          .setColorBackground(bg_color)
            .setColorForeground(bg_color)
              .setColorCaptionLabel(text_color)
                .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
                  ;   

  cp5.addButton("set")
    .setPosition(50, 730)
      .setSize(100, 40)
        .setColorActive(fg_color)
          .setColorBackground(bg_color)
            .setColorForeground(bg_color)
              .setColorCaptionLabel(text_color)
               .setCaptionLabel("Set File")
                .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
                  ;
}

public void controlEvent(ControlEvent theEvent) {
  //println(theEvent.getController().getName());
}

String loadFile (Frame f, String title, String defDir, String fileType) {
  FileDialog fd = new FileDialog(f, title, FileDialog.LOAD);
  fd.setFile(fileType);
  fd.setDirectory(defDir);
  fd.setLocation(50, 50);
  fd.show();
  if(fd.getDirectory()==null) return null;
  if(fd.getFile()==null) return null;
  String path = fd.getDirectory()+fd.getFile();
  return path;
}
