//
//  MGLTiltGestureRecognizer.h
//  ios
//
//  Created by Fabian Guerra Soto on 7/18/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

typedef NS_ENUM(NSUInteger, MGLTiltGestureState) {
    MGLTiltGestureStatePossible,
    MGLTiltGestureStateBegan,
    MGLTiltGestureStateChanged,
    MGLTiltGestureStateEnded,
    MGLTiltGestureStateCancelled,
    MGLTiltGestureStateInvalidated
};

@interface MGLTiltGestureRecognizer : UIPanGestureRecognizer

@property (nonatomic) MGLTiltGestureState tiltPhase;

@end
