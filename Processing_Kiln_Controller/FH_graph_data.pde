// FloatTable class from graphing example modified to allow
// dynamic insertion of data

class FH_kiln_data {
  int rowCount;
  int columnCount;
  float[][] data;
  String[] columnNames;
  
  
  FH_kiln_data() {

    rowCount = 1;
    columnCount = 3;
    data = new float[rowCount][3];
    data[0][0] = -1000.0;
    data[0][1] =  0.0;
    data[0][2] =  0.0;
  }
  
  void addPoint(float x, float y, float z) {
    
    // resize the 'data' array as necessary
    if(data[rowCount-1][0] != -1000.0) {
      rowCount++;
      float[][] new_row = new float[1][3];
      data = (float[][]) concat(data, new_row);
    }
    data[rowCount-1][0] = x;
    data[rowCount-1][1] = y;
    data[rowCount-1][2] = z;    
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
