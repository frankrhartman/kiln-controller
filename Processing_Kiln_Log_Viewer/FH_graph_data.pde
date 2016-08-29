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

// FloatTable class from graphing example modified to allow
// dynamic insertion of data

// first line of the file should be the column headers
// first column should be the row titles
// all other values are expected to be floats
// getFloat(0, 0) returns the first data value in the upper lefthand corner
// files should be saved as "text, tab-delimited"
// empty rows are ignored
// extra whitespace is ignored


class FH_graph_data {
  int rowCount;
  int columnCount;
  float[][] data;
  String[] columnNames;
  
  
  FH_graph_data() {

    rowCount = 1;
    data = new float[rowCount][2];
    data[0][0] = -1000.0;
    data[0][1] =  0.0;
  }
  
  FH_graph_data(String filename) {
    String[] rows = loadStrings(filename);
    
    println("Loading: " + filename);
    println("Got " + rows.length + " rows");
    
    String[] columns = split(rows[0], ",");
    columnCount = columns.length;
    println("Got " + columns.length + " columns");   

    data = new float[rows.length][];

    for (int i = 0, rowcount=0; i < rows.length; i++) {

      // split the row on the commas
      String[] pieces = split(rows[i], ",");
      
      // copy data into the table starting at pieces[0]
      data[rowCount] = parseFloat(subset(pieces, 0));

      // increment the number of valid rows found so far
      rowCount++;      
    }
    // resize the 'data' array as necessary
    data = (float[][]) subset(data, 0, rowCount);
  }
  
  
  void addPoint(float x, float y) {
    
    // resize the 'data' array as necessary
    if(data[rowCount-1][0] != -1000.0) {
      rowCount++;
      float[][] new_row = new float[1][2];
      data = (float[][]) concat(data, new_row);
    }
    data[rowCount-1][0] = x;
    data[rowCount-1][1] = y;
  }
  
  int getRowCount() {
    return rowCount;
  }
  
  // technically, this only returns the number of columns 
  // in the very first row (which will be most accurate)
  int getColumnCount() {
    return columnCount;
  }

  float getFloat(int rowIndex, int col) {
    // Remove the 'training wheels' section for greater efficiency
    // It's included here to provide more useful error messages
    
    // begin training wheels
    if ((rowIndex < 0) || (rowIndex >= data.length)) {
      throw new RuntimeException("There is no row " + rowIndex);
    }
    if ((col < 0) || (col >= data[rowIndex].length)) {
      throw new RuntimeException("Row " + rowIndex + " does not have a column " + col);
    }
    // end training wheels
    
    return data[rowIndex][col];
  }
  
  
  boolean isValid(int row, int col) {
    if (row < 0) return false;
    if (row >= rowCount) return false;
    //if (col >= columnCount) return false;
    if (col >= data[row].length) return false;
    if (col < 0) return false;
    return !Float.isNaN(data[row][col]);
  }


  float getColumnMin(int col) {
    float m = Float.MAX_VALUE;
    for (int row = 0; row < rowCount; row++) {
      if (isValid(row, col)) {
        if (data[row][col] < m) {
          m = data[row][col];
        }
      } else {
        println("Invalid data query in FH_graph_data");
      }
    }
    return m;
  }


  float getColumnMax(int col) {
    float m = -Float.MAX_VALUE;
    for (int row = 0; row < rowCount; row++) {
      if (isValid(row, col)) {
        if (data[row][col] > m) {
          m = data[row][col];
        }
      } else {
        println("Invalid data query in FH_graph_data");
      }
    }
    return m;
  }


  float getTableMin() {
    float m = Float.MAX_VALUE;
    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < columnCount; col++) {
        if (isValid(row, col)) {
          if (data[row][col] < m) {
            m = data[row][col];
          }
        }
      }
    }
    return m;
  }


  float getTableMax() {
    float m = -Float.MAX_VALUE;
    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < columnCount; col++) {
        if (isValid(row, col)) {
          if (data[row][col] > m) {
            m = data[row][col];
          }
        }
      }
    }
    return m;
  }
}
