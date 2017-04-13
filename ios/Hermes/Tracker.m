//
//  Tracker.m
//  Hermes
//
//  Created by Andre Pinto on 4/9/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "Tracker.h"
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OnStepAccelerometer: NSObject
{
  int steps;
  int offset;
  int curSteps;
}

-(void)setSteps:(int) value;
-(int)getSteps;
-(void)setOffset:(int) value;
-(int)getOffset;
-(void)setCurSteps:(int) value;
-(int)getCurSteps;
-(void)update:(int) value;

@end

@implementation OnStepAccelerometer

-(instancetype)init {
  steps = 0;
  offset = 0;
  curSteps = 0;
  return self;
}

-(int)getSteps {
  return steps;
}

-(void)setSteps:(int)value {
  steps = value;
}

-(int)getOffset {
  return offset;
}

-(void)setOffset:(int)value {
  offset = value;
}

-(int)getCurSteps {
  return curSteps;
}

-(void)setCurSteps:(int)value {
  curSteps = value;
}

-(void)update:(int) value {
  steps++;
  curSteps = 1;
}

@end

@interface OnStepCounter : OnStepAccelerometer

@end

@implementation OnStepCounter

-(void)update:(int) value {
  if(value >= steps) {
    curSteps = value - steps;
    steps = value;
  } else {
    curSteps = value;
    offset = offset + steps;
    steps = value;
  }
}

@end

@implementation Tracker

@synthesize bridge = _bridge;

// interval in seconds for the accelerometer update
float interval = .1;
float v0 = 0, vx = 0;

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(start) {
  // clear pedometer data from user defaults
  //NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
  //[preferences removeObjectForKey:@"pedometer"];
  //[preferences synchronize];
  [[UIAccelerometer sharedAccelerometer] setUpdateInterval:interval];
  [[UIAccelerometer sharedAccelerometer] setDelegate:self];
}

RCT_EXPORT_METHOD(stop) {
  [[UIAccelerometer sharedAccelerometer] setDelegate:nil];
}

//==============================================================================
// How are the steps stored
//------------------------------------------------------------------------------
// All pedometer information is stored in the user defaults in a dictionary with
// dates in the format yyyyMMddHHmm, in intervals not smaller than 30 minutes.
// The dictionary also contains the total number of steps and an offset.
// Example:
// { "steps": 1000,
//   "offset": 500,
//   "201704101200": 200,
//   "201704101230": 200,
//   "201704101300": 100,
//   "201704111130": 250,
//   "201704111200": 250,
//   "201704121200": 250,
//   "201704121230": 250 }
// In order to get the number of steps for one day, let's say 12/04/2017, we get
// all date entries that start with 20170412 and sum them.
//==============================================================================
RCT_EXPORT_METHOD(getStepCountToday:(RCTResponseSenderBlock)response) {
  int steps = 0;
  // read steps from the current date
  NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
  if([preferences objectForKey:@"pedometer"] != nil) {
    NSDictionary *pedometer;
    pedometer = [preferences dictionaryForKey:@"pedometer"];

    long timestamp = [[NSDate date] timeIntervalSince1970];
    NSDate* date = [NSDate dateWithTimeIntervalSince1970: timestamp];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd"];
    NSString* filter = [formatter stringFromDate:date];

    for(NSString* key in pedometer) {
      if([key hasPrefix:filter]) {
        steps += [pedometer[key] intValue];
      }
    }
  }
  response(@[[NSNumber numberWithInt:steps]]);
}
//==============================================================================
// Get all date entries of the current week, returning an array with the steps
// per day, starting on sunday and ending on saturday.
//==============================================================================
RCT_EXPORT_METHOD(getStepCountWeek:(RCTResponseSenderBlock)response) {
  NSMutableArray* week = [NSMutableArray arrayWithArray:@[ @0, @0, @0, @0, @0, @0, @0 ]];
  NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
  if([preferences objectForKey:@"pedometer"] != nil) {
    NSDictionary *pedometer;
    pedometer = [preferences dictionaryForKey:@"pedometer"];

    NSDate* today = [NSDate date];
    NSDateFormatter* weekFmt = [[NSDateFormatter alloc] init];
    [weekFmt setDateFormat:@"c"];
    NSDateFormatter* dateFmt = [[NSDateFormatter alloc] init];
    [dateFmt setDateFormat:@"yyyyMMdd"];

    int c = [[weekFmt stringFromDate:today] intValue];
    long timestamp = [today timeIntervalSince1970];
    for(int i = 0; i < 7; i++) {
      long day = timestamp + (i-c+1) * 86400;
      NSDate* date = [NSDate dateWithTimeIntervalSince1970: day];
      NSString* filter = [dateFmt stringFromDate:date];
      int steps = 0;
      for(NSString* key in pedometer) {
        if([key hasPrefix:filter]) {
          steps += [pedometer[key] intValue];
        }
      }
      week[i] = [NSNumber numberWithInt:steps];
    }
  }
  response(week);
}

-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
  [self handleAccelerationSimple: acceleration];
}

//==============================================================================
// A much simpler way with similar results is to check if any of the components
// of the acceleration vector is more than gravity (in this case ~1).
-(void)handleAccelerationSimple:(UIAcceleration *)acceleration {
  const float threshold = 1.2;
  if(ABS(acceleration.x) > threshold ||
     ABS(acceleration.y) > threshold ||
     ABS(acceleration.z) > threshold) {
    OnStepAccelerometer *stepLogic = [[OnStepAccelerometer alloc] init];
    [self onStep:stepLogic value:0];
  }
}

//==============================================================================
// All the values in the following example are arbitrary.
// The idea here is to detect a subtle change in the acceleration vector. When
// the vector reaches its maximum value and then decreases, we check if the top
// value was withing a certain threshold. If it was, the it was a step.
//
//  4 --       o              o
//  3 --      /|\          ---|\                o           o
//  2 --     / | \        /   | \/\            /|\         /|\
//  1 --    /  |  \     --    |    \          / | \     --- | \
//  0 -----/---|---\---/------|-----\-----o--/--|--\---/----|--\
// -1 --  /    |    ---       |      \   /|\/   |   ---     |
// -2 ----     |              |       --- |     |           |
// -3 --       |              |           |     |           |
// -4 --       |              |           |     |           |
//       |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
//       0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7  8
//
//      v  vd  vx  vt = 2
//  0: -2  -2   0
//  1:  1   3   3
//  2:  4   3   6
//  3:  1  -3   0  step: 6 > vt
//  4: -1  -2   0
//  5:  1   2   2
//  6:  3   2   4
//  7:  4   1   5
//  8:  2  -2   0  step: 5 > vt
//  9:  0  -2   0
// 10: -2  -2   0
// 11:  0   2   2
// 12:  0   0   0  noise: 2 <= vt
// 13:  3   3   3
// 14:  0  -3   0  step: 3 > vt
// 15: -1  -1   0
// 16:  1   2   2
// 17:  3   2   4
// 18:  0  -3   0  step: 4 > vt
//
//==============================================================================
-(void)handleAcceleration:(UIAcceleration *)acceleration {
  float x = acceleration.x;
  float y = acceleration.y;
  float z = acceleration.z;
  // threshold that indicates a step
  const float vt = .5;
  // acceleration vector size
  float v = sqrtf(x * x + y * y + z * z);
  // difference between previous and current sizes
  float vd = v0 - v;
  // previous becomes current for next iteraction
  v0 = v;
  // if difference is less than zero, the graph is going down
  if(vd < 0) {
    // if last top value is over the threshold, register a step
    if(vx > vt) {
      OnStepAccelerometer *stepLogic = [[OnStepAccelerometer alloc] init];
      [self onStep:stepLogic value:0];
    }
    // top goes to zero
    vx = 0;
  }
  // if difference is greater or equal to zero, the graph is going up
  else {
    // add the value, let's see how far does it goes
    vx += vd;
  }
}

-(void)onStep:(OnStepAccelerometer*)onStepLogic value:(int)value {
  // get preferences
  NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary *pedometer;
  if([preferences objectForKey:@"pedometer"] == nil) {
    pedometer = [[NSMutableDictionary alloc] initWithDictionary: @{ @"steps": @0, @"offset": @0 }];
  } else {
    pedometer = [[preferences dictionaryForKey:@"pedometer"] mutableCopy];
  }
  // from preferences, get the overall steps and offset
  [onStepLogic setSteps: [pedometer[@"steps"] intValue]];
  [onStepLogic setOffset: [pedometer[@"offset"] intValue]];
  [onStepLogic setCurSteps: 0];
  [onStepLogic update:value];
  // generate the timestamp key (hourly)
  long timestamp = [[NSDate date] timeIntervalSince1970];
  NSDate* date = [NSDate dateWithTimeIntervalSince1970: timestamp];
  NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"yyyyMMddHH"];
  NSString* key = [formatter stringFromDate:date];
  // from preferences, get steps for that timestamp
  // if does not exist, create an empty one
  int prevSteps = 0;
  if([pedometer objectForKey:key] != nil) {
    prevSteps = [pedometer[key] intValue];
  }
  int curSteps = prevSteps + [onStepLogic getCurSteps];
  // update the steps for that timestamp
  [pedometer setObject:[NSNumber numberWithInt:[onStepLogic getSteps]] forKey:@"steps"];
  [pedometer setObject:[NSNumber numberWithInt:[onStepLogic getOffset]] forKey:@"offset"];
  [pedometer setObject:[NSNumber numberWithInt:curSteps] forKey:key];
  // put it back in preferences
  [preferences setObject:pedometer forKey:@"pedometer"];
  // save preferences
  [preferences synchronize];
  // event up the total steps
  [self.bridge.eventDispatcher sendAppEventWithName:@"onSensorChanged" body:@{@"steps": [NSString stringWithFormat:@"%d", [onStepLogic getSteps]]}];
}

@end
