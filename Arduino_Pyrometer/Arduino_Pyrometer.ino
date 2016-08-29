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

#include "Adafruit_MAX31855.h"
#include <LiquidCrystal.h>

int thermoDO = 4;
int thermoCS = 5;
int thermoCLK = 6;

int interval = 1000;     // sampling interval in msec
float last_C_temp = 0.0; // keep last temp to display delta

Adafruit_MAX31855 thermocouple(thermoCLK, thermoCS, thermoDO);

LiquidCrystal lcd(8, 9, 10, 11, 12, 13);

// make a cute degree symbol
uint8_t degree[8]  = {140,146,146,140,128,128,128,128};

byte heart[8] = {
  0b00000,
  0b01010,
  0b11111,
  0b11111,
  0b11111,
  0b01110,
  0b00100,
  0b00000
};

void setup() {
  
  // Serial port setup
  Serial.begin(9600);
  
  // LCD setup
  lcd.begin(16, 2);
  lcd.createChar(0, degree);
  lcd.createChar(1, heart);
  
  // wait for MAX thermocouple interface chip to stabilize
  delay(500);
  
}

void loop() {
  // get the current time at start of loop
  long int start_time = millis();
  
  // print the current temp in degrees C to the lcd
  lcd.clear();
  lcd.setCursor(0, 0);
  float C_temp = thermocouple.readCelsius();
  if(isnan(C_temp)) {
    lcd.print("ERROR");
  } else {
    lcd.print(C_temp);
    lcd.write((byte)0);
    lcd.print("C ");
  }

  // print the current temp in degrees F to the lcd
  lcd.setCursor(0,1);  
  if(isnan(C_temp)) {
    lcd.print("ERROR");
  } else {
    float F_temp = (C_temp * 1.8) + 32.0;
    lcd.print(F_temp);
    lcd.write((byte)0);
    lcd.print("F ");
  }
  
  // print the delta temp in degrees F to the lcd
  lcd.setCursor(10,0);  
  if(isnan(C_temp)) {
    lcd.print("ERROR");
  } else {
    float delta_temp = C_temp - last_C_temp;
    float seconds = interval/1000.0;
    float hours = seconds/360.0;
    float C_rate = delta_temp/hours;
    lcd.print(C_rate);
    last_C_temp = C_temp;
  }
  
  // Important message
  lcd.setCursor(10,1);
  lcd.write((byte)0);
  lcd.print("C/Hr");
  
  // log the time in seconds and temp in degrees C to the serial port for data capture
  long int t = millis()/1000;
  
  Serial.print(t);
  Serial.print(",");  
  if (isnan(C_temp)) Serial.println("ERROR");
  else Serial.println(C_temp);
  
  // temperatture sample every interval seconds
  long int end_time = millis();
  long int delta_time = end_time - start_time;
  delay(interval - delta_time);
}
