//
//  Tracker.h
//  Hermes
//
//  Created by Andre Pinto on 4/9/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#ifndef Tracker_h
#define Tracker_h

#import <React/RCTBridgeModule.h>
#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIKit.h>

@interface Tracker : NSObject<RCTBridgeModule, UIAccelerometerDelegate>

@property (nonatomic, strong) CMPedometer *pedometer;

@end


#endif /* Tracker_h */
