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

// plot class


class FH_plot {
  // Corners of entire plot including title and axis labels
  float outerX1, outerY1;
  float outerX2, outerY2;
  // Offset between entire plot and data plotting area
  float offset = 70;
  // Corner of data plotting area
  float plotX1, plotY1; // upper left corner of plot
  float plotX2, plotY2; // lower right corner of plot
  float labelX, labelY; // x label and y label positions
  PFont plotFont;
  // data to be plotted
  FH_graph_data data;
  // min and max of data
  float xdataMin, xdataMax;
  float ydataMin, ydataMax;
  // number of data samples
  int rowCount;
  // plot title
  String title;
  // intervals for tick spacing
  float xInterval = 3600.0;
  float yInterval = 100.0;
  // color of the plot line
  color plot_color = color(128,0,0);
  color text_color = color(80, 80, 80);
  color bg_color = color(200,200,200);
  color fg_color = color(220, 220, 220);
  

  FH_plot(float X1, float Y1, float X2, float Y2) {

    // outer rectangle - plot + labels
    outerX1 = X1;
    outerY1 = Y1;
    outerX2 = X2;
    outerY2 = Y2;

    // inner rectangle - plot
    plotX1 = X1 + offset;
    plotY1 = Y1 + offset;
    plotX2 = X2 - offset;
    plotY2 = Y2 - offset;

    labelX = X1 + (X2 - X1)/2;
    labelY = Y1 + (Y2 - Y1)/2;
    plotFont = createFont("arial", 12);
    textFont(plotFont);
  }

  void set_column_names() {
  }

  void set_data(FH_graph_data in_data) {
    data = in_data;

    xdataMin = data.getColumnMin(0);
    xdataMax = data.getColumnMax(0);
    ydataMin = 0.0;
    ydataMax = data.getColumnMax(1) + 20.0;

    rowCount = data.getRowCount();
  }

  void draw_plot() {

    strokeWeight(1);

    // Show the full area as a dark cyan box  
    fill(bg_color);
    rectMode(CORNERS);
    stroke(128, 128, 128);
    rect(outerX1, outerY1, outerX2, outerY2);

    // Show the plot area as a lighter cyan box  
    fill(fg_color);
    rectMode(CORNERS);
    stroke(128, 128, 128);
    rect(plotX1, plotY1, plotX2, plotY2);

    drawTitle();
    drawAxisLabels();
    //drawDataPoints();
    if(rowCount > 1) {
      drawXAxisTicks();
      drawYAxisTicks();
      drawDataLine();
    }
  }

  void drawDataPoints() {
    strokeWeight(2);
    for (int row = 0; row < rowCount; row++) {
      if (data.isValid(row, 1)) {
        float yvalue = data.getFloat(row, 1);
        float xvalue = data.getFloat(row, 0);

        float x = map(xvalue, xdataMin, xdataMax, plotX1, plotX2);
        float y = map(yvalue, ydataMin, ydataMax, plotY2, plotY1);
        point(x, y);
      }
    }
  }

  void drawDataLine() {
    noFill();
    strokeWeight(1);
    beginShape();
    stroke(plot_color);
    for (int row = 0; row < rowCount; row++) {
      if (data.isValid(row, 1)) {
        float yvalue = data.getFloat(row, 1);
        float xvalue = data.getFloat(row, 0);

        float x = map(xvalue, xdataMin, xdataMax, plotX1, plotX2);
        float y = map(yvalue, ydataMin, ydataMax, plotY2, plotY1);    
        vertex(x, y);
      }
    }
    endShape();
  }

  void drawTitle() {
    fill(text_color);
    textSize(16);
    textAlign(CENTER, CENTER);
    text(title, plotX1+(plotX2-plotX1)/2, plotY1 - offset/2);
  }

  void drawAxisLabels() {
    fill(text_color);
    textSize(13);
    textLeading(15);

    textAlign(CENTER, CENTER);
    pushMatrix();
    translate(outerX1 + offset/3, plotY1+(plotY2-plotY1)/2);
    rotate(-1.57);
    text("Temperature \u00B0C", 0, 0);
    popMatrix();

    textAlign(CENTER, CENTER);
    pushMatrix();
    translate(plotX1+(plotX2-plotX1)/2, outerY2 - offset/3);
    rotate(0);
    text("Time (Hours)", 0, 0);
    popMatrix();
  }

  void drawXAxisTicks() {
    fill(text_color);
    textSize(10);
    textAlign(CENTER);

    // Use thin, gray lines to draw the grid
    stroke(200);
    strokeWeight(1);
    
    float x;

    
    for(float xtick = xdataMin; xtick<xdataMax-100; xtick += xInterval) {
        x = map(xtick, xdataMin, xdataMax, plotX1, plotX2);
        text((int)(xtick/xInterval), x, plotY2 + textAscent() + 10);
        if(xtick != xdataMin) line(x, plotY1, x, plotY2);
    }
    
    x = map(xdataMax, xdataMin, xdataMax, plotX1, plotX2);
    text(xdataMax/xInterval, x, plotY2 + textAscent() + 10);

  }
  
    void drawYAxisTicks() {
    fill(text_color);
    textSize(10);
    textAlign(RIGHT, CENTER);

    // Use thin, gray lines to draw the grid
    stroke(200);
    strokeWeight(1);
    
    float y;

    for(float ytick = ydataMin; ytick<ydataMax-5; ytick += yInterval) {
        y = map(ytick, ydataMin, ydataMax, plotY2, plotY1);
        text((int)ytick, plotX1-5, y);
        if(ytick != ydataMin) line(plotX1, y, plotX2, y);
    }
    
    y = map(ydataMax, ydataMin, ydataMax, plotY2, plotY1);
    text((int)ydataMax, plotX1-5, y);

  }
  
  //void drawDataHighlight(int col) {
//  for (int row = 0; row < rowCount; row++) {
//    if (data.isValid(row, col)) {
//      float value = data.getFloat(row, col);
//      float x = map(years[row], yearMin, yearMax, plotX1, plotX2);
//      float y = map(value, dataMin, dataMax, plotY2, plotY1);
//      if (dist(mouseX, mouseY, x, y) < 3) {
//        strokeWeight(10);
//        point(x, y);
//        fill(0);
//        textSize(10);
//        textAlign(CENTER);
//        text(nf(value, 0, 2) + " (" + years[row] + ")", x, y-8);
//        textAlign(LEFT);
//      }
//    }
//  }
//}

}

