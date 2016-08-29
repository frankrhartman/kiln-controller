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

#include <PID_v1.h>
#include "Adafruit_MAX31855.h"
#include <LiquidCrystal.h>

// thermcouple interface object
Adafruit_MAX31855 thermocouple(6, 5, 4);

// make a degree symbol
uint8_t degree[8]  = {140,146,146,140,128,128,128,128};

// lcd interface
LiquidCrystal lcd(8, 9, 10, 11, 12, 13);

// variables for the PID
double Setpoint, Input, Output;

// output pin for PID control
int outputPin=3;

//Specify the links and initial tuning parameters
// Kp = 1
// Ki = 0
// Kd = 0
PID myPID(&Input, &Output, &Setpoint,1,0,0, DIRECT);

// how often in msec we talk to processing
unsigned long serialInterval = 1000;
unsigned long serialTime;

// how often in msec we sample temp
unsigned long sampleTimeInterval = 1000;
unsigned long sampleTime;

// our relay output window size in msec
// compute PID once every output window size
unsigned long windowSize = 10000;
unsigned long windowStartTime;

// kiln temp in degrees C
float C_temp;
// last temp measurement that wasn't an error
float last_valid_temp=0.0;
// was the last temp measurement and error
int temp_error=0;

// correction factor to calibrate thermocouple output to Orton cone 6
float calibration = 1.0703; 

void setup()
{
  // init all our windows at start
  windowStartTime = millis();
  serialTime = millis();
  sampleTime = millis();

  //initialize the serial link with processing
  Serial.begin(9600);
  Serial.println("START");
  
  pinMode(7, OUTPUT); 
  digitalWrite(7, LOW);
  pinMode(outputPin, OUTPUT); 

  // initialize our setpoint to zero - will be set via serial
  Setpoint = 0;
  Input = 0;

  //tell the PID to range between 0 and 1
  myPID.SetOutputLimits(0, 1);

  // LCD setup
  lcd.begin(16, 2);
  lcd.createChar(0, degree);
  lcd.setCursor(0,0); 
  lcd.print("KILN CONTROLLER");
  lcd.setCursor(0,1); 
  lcd.print("VERSION 1.4");
  
  // wait for MAX thermocouple interface chip to stabilize
  delay(500);

  //turn the PID on
  myPID.SetMode(AUTOMATIC);
}

void loop()
{
  ////////////////////////////////////
  // Sample Pyrometer and update LCD
  ////////////////////////////////////
  
  // sample temp, and update LCD if it's time
  if(millis()>sampleTime) {

    // read temp from the thermocouple
    // if not valid use the last valid temp
    C_temp = thermocouple.readCelsius();
    if(isnan(C_temp)) {
      // error measuring temp
      C_temp = last_valid_temp;
      temp_error = 1;
    } else {
      // no error measuring temp
      last_valid_temp = C_temp;
      temp_error = 0;
    }
    C_temp *= calibration;

    // update the LCD display
    updateLCD();

    // increment sample time to next sample
    sampleTime+=sampleTimeInterval;
  }

  ////////////////////////////////////
  // PWM Output
  ////////////////////////////////////
  
  // shift window and compute PID if it's time
  if(millis() - windowStartTime>windowSize) {
    // process PID computation
    Input = C_temp;
    myPID.Compute();

    // shift the Relay Window
    windowStartTime += windowSize;
  }

  lcd.setCursor(12, 1);
  // turn the output pin on/off based on pid output
  // Output controls percentage of windowSize that 
  // relay will be on
  if(Output*windowSize>=millis()-windowStartTime || Output > 0.99) {
    digitalWrite(outputPin,HIGH);
    lcd.print("ON ");
  } 
  else {
    digitalWrite(outputPin,LOW);
    lcd.print("OFF");
  }

  ////////////////////////////////////
  // Serial Communication
  ////////////////////////////////////
  
  // send-receive with processing if it's time
  if(millis()>serialTime) {
    SerialReceive();
    SerialSend();
    serialTime+=serialInterval;
  }

}

void updateLCD() {
  // print the current temp in degrees C to the lcd
  lcd.clear();
  lcd.setCursor(0, 0);
  if(isnan(C_temp)) {
    lcd.print("ERROR");
  } 
  else {
    lcd.print("T");
    lcd.setCursor(2,0);
    lcd.print(C_temp);
    lcd.write((byte)0);
    lcd.print("C ");
    if(temp_error) lcd.print("*");
  }

  // print the setpoint to the lcd
  lcd.setCursor(0,1);
  lcd.print("S");
  lcd.setCursor(2,1);
  lcd.print(Setpoint);
  lcd.write((byte)0);
  lcd.print("C ");

  // write controller output value to lcd
  lcd.setCursor(12, 0);
  lcd.print(Output);
}

//////////////////////////////////////////////
// Serial Communication functions / helpers //
//////////////////////////////////////////////

// Send time, temp, setpoint, and controller output back to processing program for logging and display
void SerialSend()
{
  long int t = millis()/1000;

  Serial.print(t);
  Serial.print(",");  
  if (isnan(C_temp)) Serial.print("ERROR");
  else Serial.print(C_temp);
  Serial.print(","); 
  Serial.print(Setpoint);   
  Serial.print(",");
  Serial.println(Output);
}

// Recieve
union {                // This Data structure lets
  byte asBytes[4];    // us take the byte array
  float asFloat[1];    // sent from processing and
}                      // easily convert it to a
foo;                   // float array

// getting float values from processing into the arduino
// was no small task.  the way this program does it is
// as follows:
//  * a float takes up 4 bytes.  in processing, convert
//    the array of floats we want to send, into an array
//    of bytes.
//  * send the bytes to the arduino
//  * use a data structure known as a union to convert
//    the array of bytes back into an array of floats

//  the bytes coming from the arduino follow the following
//  format:
//  0-3: float setpoint
void SerialReceive()
{
  // read the bytes sent from Processing
  int index=0;
  while(Serial.available()&&index<4) {
    foo.asBytes[index++] = Serial.read();
  } 

  // if the information we got was in the correct format, 
  // read it into the system
  if(index==4){
    Setpoint=double(foo.asFloat[0]);
  }

  // clear any random data from the serial buffer
  Serial.flush();
}








