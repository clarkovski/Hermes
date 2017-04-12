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
#import <UIKit/UIKit.h>

@interface Tracker : NSObject<RCTBridgeModule, UIAccelerometerDelegate>

@end


#endif /* Tracker_h */
