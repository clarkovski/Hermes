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

@implementation Tracker

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(pedometer:(RCTResponseSenderBlock)callback) {
  BOOL pedo = [CMPedometer isStepCountingAvailable];
  BOOL step = [CMStepCounter isStepCountingAvailable];
  BOOL motion = [CMMotionActivityManager isActivityAvailable];
 
  if(!_pedometer) {
    _pedometer = [[CMPedometer alloc] init];
  }
  
  NSString *result = [NSString stringWithFormat:@"pedo %hhd step %hhd motion %hhd", pedo, step, motion];
  
  callback(@[result]);
}

RCT_EXPORT_METHOD(accelerometer) {
  [[UIAccelerometer sharedAccelerometer] setUpdateInterval:1];
  [[UIAccelerometer sharedAccelerometer] setDelegate:self];
}

-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
  NSString *result = [NSString stringWithFormat:@"acceleration vector (%f, %f, %f)",
                      acceleration.x,
                      acceleration.y,
                      acceleration.z];
  [self.bridge.eventDispatcher sendAppEventWithName:@"onAccelerate" body:@{@"vector": result}];
}


@end
