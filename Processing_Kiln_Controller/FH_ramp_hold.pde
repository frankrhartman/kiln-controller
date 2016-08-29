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

//  class to implement a ramp hold controller
//  inputs are time,  current temp, and program
//  output is setpoint

// states are:
//  0 init
//  1 ramping
//  2 holding
// 99 done / not started

class FH_ramp_hold {
  float time;
  float temp;
  float setpoint;
  float[][] ramps;
  int state;
  float ramp_start;
  float hold_start;
  float current_ramp_rate;
  float current_hold_dur;
  float current_ramp_target;
  int current_ramp_num;
  int heat_cool;
  float last_ramp_target;
  int num_ramps;
  float init_temp;

  FH_ramp_hold(float[][] _ramps) {
    ramps = _ramps;
    num_ramps = ramps.length;
    setpoint = 0.0;
    time = 0.0;
    temp = 0.0;
    state = 99;
    init_temp = 0.0;
  }
  
  int get_state() {
    return state;
  }
  
  int get_ramp_num() {
    return current_ramp_num;
  }
  
  float get_current_ramp() {
    return current_ramp_rate;
  }
  
  float get_current_target() {
    return current_ramp_target;
  }
  
  float get_current_hold() {
    return current_hold_dur;
  }
  
  int get_heat_cool() {
    return heat_cool;
  }
  
  void set_init_temp(float _temp) {
    init_temp = _temp; 
  }

  void start() {
    state = 0; 
  }
  
  void stop() {
    state = 99;
    current_ramp_num = 0;
    current_ramp_rate = 0.0;
    current_ramp_target = 0.0;
    current_hold_dur = 0.0;
  }
    
  void setTime(float _time) {
    time = _time;
  }

  void setTemp(float _temp) {
    temp = _temp;
  }

  void calculate() {
    calculateState();
    calculateSetpoint();
  }

  // state transition logic
  void calculateState() {
    
    // transition from init state to ramping state
    if (state==0) {
      state = 1;
      current_ramp_num = 0;
      current_ramp_rate = ramps[current_ramp_num][0];
      current_ramp_target = ramps[current_ramp_num][1];
      current_hold_dur = ramps[current_ramp_num][2];
      ramp_start = time;
      if (current_ramp_rate > 0) heat_cool = 1; // heating
      else heat_cool = -1;                      // cooling
    } 
    // transition from ramping state to holding state for heating
    else if ((state==1) && (temp > current_ramp_target) && (heat_cool==1)) {
      state = 2;
      hold_start = time;
    }
    // transition from ramping state to holding state for cooling
    else if ((state==1) && (temp < current_ramp_target) && (heat_cool==-1)) {
      state = 2;
      hold_start = time;
    } 
    // transition from holding state...
    if (state==2 && time-hold_start > current_hold_dur*60) {
      // to finished state
      if (current_ramp_num == num_ramps-1) {
        state=99;
      // to next ramp 
      } else {
        state = 1;
        last_ramp_target = ramps[current_ramp_num][1];
        current_ramp_num = current_ramp_num + 1;
        current_ramp_rate = ramps[current_ramp_num][0];
        current_ramp_target = ramps[current_ramp_num][1];
        current_hold_dur = ramps[current_ramp_num][2];
        ramp_start = time;
        init_temp = 0.0; // no longer on first ramp so forget about starting temp
        if (current_ramp_rate > 0) heat_cool = 1; // heating
        else heat_cool = -1;                      // cooling
      }
    }

    if (ramps[current_ramp_num][0] == 0.0 && ramps[current_ramp_num][1] == 0.0 && ramps[current_ramp_num][2] == 0.0)
      state = 99;
  }



  // compute setpoint based on state, ramp parameters, and timing
  void calculateSetpoint() {
    float tmp = 0;
    
    if (state==1) {
      tmp = (current_ramp_rate/3600) * (time-ramp_start) + last_ramp_target + init_temp;
      // If heating clamp setpoint to target temp +5 degrees so controller will get kiln to target temp
      // If cooling clamp to ramp target
      if (tmp > current_ramp_target+5 && heat_cool==1) tmp = current_ramp_target+5; 
      else if (tmp < current_ramp_target && heat_cool==-1) tmp = current_ramp_target; 
    }  else if (state==2) tmp = current_ramp_target;
    else tmp = 0;

//println("TMP: " + tmp);
//println("CURRENT_RAMP_TARGET: " + current_ramp_target);
//println("HC: " + heat_cool);
//println("STATE: " + state);
    setpoint = tmp;
  }

  float getSetpoint() {
    return setpoint;
  }
}

