//
//  MGLTiltGestureRecognizer.m
//  ios
//
//  Created by Fabian Guerra Soto on 7/18/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

#import "MGLTiltGestureRecognizer.h"

typedef NS_ENUM(NSUInteger, MGLTiltGestureState) {
    MGLTiltGestureStateNotStarted,
    MGLTiltGestureStateInitialPoint,
    MGLTiltGestureStateInvalidated,
    MGLTiltGestureStateUp,
    MGLTiltGestureStateDown,
};

typedef struct MGLTouchBounds {
    CGPoint west;
    CGPoint east;
} MGLTouchBounds;


NS_INLINE MGLTouchBounds MGLTouchBoundsMake(CGPoint pointA, CGPoint pointB) {
    MGLTouchBounds touchBounds;
    
    if (pointA.x < pointB.x)  {
        touchBounds.west = pointA;
        touchBounds.east = pointB;
    } else {
        touchBounds.west = pointB;
        touchBounds.east = pointA;
    }
    
    return touchBounds;
}

static CGFloat const fingerThreshold = 40.0;

@interface MGLTiltGestureRecognizer()

@property (nonatomic) MGLTiltGestureState tiltPhase;
@property (nonatomic) MGLTouchBounds initialTouchBounds;
@property (nonatomic) CGPoint CGPointNil;

@end

@implementation MGLTiltGestureRecognizer

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
    if ((self = [super initWithTarget:target action:action])) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _CGPointNil = CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
    _tiltPhase = MGLTiltGestureStateNotStarted;
    _initialTouchBounds.east = _CGPointNil;
    _initialTouchBounds.west = _CGPointNil;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [super touchesBegan:touches withEvent:event];
    
    // Tilt gesture requires two fingers to triger
    if (touches.count != 2) {
        self.state = UIGestureRecognizerStateFailed;
        return;
    }
    
    if (CGPointEqualToPoint(self.initialTouchBounds.east, self.CGPointNil) &&
        CGPointEqualToPoint(self.initialTouchBounds.west, self.CGPointNil)  &&
        self.state != UIGestureRecognizerStateFailed) {
        NSArray *touchesArray = touches.allObjects;
        CGPoint pointA = [touchesArray.firstObject locationInView:self.view];
        CGPoint pointB = [touchesArray.lastObject locationInView:self.view];
        self.initialTouchBounds = MGLTouchBoundsMake(pointA, pointB);
        self.tiltPhase = MGLTiltGestureStateInitialPoint;
    }
    else {
        // Ignore all but the first touch.
        for (UITouch *touch in touches) {
            [self ignoreTouch:touch forEvent:event];
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];

    NSArray *touchesArray = touches.allObjects;
    
    // There should be only the first touch.
    if (touchesArray.count != 2) {
        self.state = UIGestureRecognizerStateFailed;
        return;
    }
    
    CGPoint currentPointA = [touchesArray.firstObject locationInView:self.view];
    CGPoint currentPointB = [touchesArray.lastObject locationInView:self.view];
    MGLTouchBounds currentBounds = MGLTouchBoundsMake(currentPointA, currentPointB);
    
    if (![self isValidBounds:currentBounds]) {
        self.state = UIGestureRecognizerStateFailed;
        return;
    }
    
    if (self.tiltPhase == MGLTiltGestureStateInitialPoint || self.tiltPhase == MGLTiltGestureStateDown  ||
        self.tiltPhase == MGLTiltGestureStateUp) {
        // Make sure the initial movement is down and to the right.
        if (currentBounds.west.y > self.initialTouchBounds.west.y &&
            currentBounds.east.y > self.initialTouchBounds.east.y) {
            self.tiltPhase = MGLTiltGestureStateDown;
        }
        else if (currentBounds.west.y <= self.initialTouchBounds.west.y && currentBounds.east.y <= self.initialTouchBounds.east.y) {
            self.tiltPhase = MGLTiltGestureStateUp;
        }
        else {
            self.state = UIGestureRecognizerStateFailed;
            self.tiltPhase = MGLTiltGestureStateInvalidated;
        }
        
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    NSArray *touchesArray = touches.allObjects;
    
    if (touchesArray.count != 2) {
        self.state = UIGestureRecognizerStateFailed;
        return;
    }
    
    if (self.state == UIGestureRecognizerStatePossible && (self.tiltPhase == MGLTiltGestureStateDown  ||
        self.tiltPhase == MGLTiltGestureStateUp)) {
        self.state = UIGestureRecognizerStateRecognized;
    }
    else {
        self.state = UIGestureRecognizerStateFailed;
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.tiltPhase = MGLTiltGestureStateNotStarted;
    self.state = UIGestureRecognizerStateCancelled;
}

- (void)reset {
    [super reset];
    self.tiltPhase = MGLTiltGestureStateNotStarted;
    self.initialTouchBounds = MGLTouchBoundsMake(self.CGPointNil, self.CGPointNil);
}

- (BOOL)isValidBounds:(MGLTouchBounds)bounds {
    BOOL state = YES;
    
    CGFloat horizontalDistance = fabs(bounds.east.x - bounds.west.x);
    CGFloat verticalDistance = fabs(bounds.east.y - bounds.west.y);
    
    if (horizontalDistance < fingerThreshold && verticalDistance > fingerThreshold) {
        state = NO;
    }
    
    return state;
}

@end
