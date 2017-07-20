//
//  MGLTiltGestureRecognizer.m
//  ios
//
//  Created by Fabian Guerra Soto on 7/18/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

#import "MGLTiltGestureRecognizer.h"
#import "MGLGeometry.h"

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

static CGFloat const angleThreshold = 20.0;

@interface MGLTiltGestureRecognizer()

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
    _tiltPhase = MGLTiltGestureStatePossible;
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
        self.tiltPhase = MGLTiltGestureStateBegan;
        self.state = UIGestureRecognizerStateBegan;
    }

}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    NSArray *touchesArray = touches.allObjects;

    
    if (touches.count == 2) {
        CGPoint currentPointA = [touchesArray.firstObject locationInView:self.view];
        CGPoint currentPointB = [touchesArray.lastObject locationInView:self.view];
        MGLTouchBounds currentBounds = MGLTouchBoundsMake(currentPointA, currentPointB);
        
        if ([self isValidBounds:currentBounds] && (self.tiltPhase == MGLTiltGestureStateBegan ||
                                                   self.tiltPhase == MGLTiltGestureStateChanged)) {
            // Make sure the initial movement is up/down
            if ((currentBounds.west.y > self.initialTouchBounds.west.y &&
                currentBounds.east.y > self.initialTouchBounds.east.y) ||
                (currentBounds.west.y <= self.initialTouchBounds.west.y &&
                 currentBounds.east.y <= self.initialTouchBounds.east.y)) {
                self.tiltPhase = MGLTiltGestureStateChanged;
            } else {
                self.tiltPhase = MGLTiltGestureStateInvalidated;
            }
        } else {
            self.tiltPhase = MGLTiltGestureStateInvalidated;
        }
        
    } else {
        // Workaround to make a smooth transition for tilting the map
        // for some reason I have detected we get a single touch somtimes
        if ( [self isWithinThreshold] )
        {
            self.tiltPhase = MGLTiltGestureStateChanged;
        } else {
            self.tiltPhase = MGLTiltGestureStateInvalidated;
        }
    }
    self.state = UIGestureRecognizerStateChanged;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];

    NSArray *touchesArray = touches.allObjects;
    
    // Workaround to make a smooth transition for tilt
    if (touches.count == 2) {
        CGPoint currentPointA = [touchesArray.firstObject locationInView:self.view];
        CGPoint currentPointB = [touchesArray.lastObject locationInView:self.view];
        MGLTouchBounds currentBounds = MGLTouchBoundsMake(currentPointA, currentPointB);
        
        if ([self isValidBounds:currentBounds] && (self.tiltPhase == MGLTiltGestureStateBegan ||
                                                   self.tiltPhase == MGLTiltGestureStateChanged)) {
            // Make sure the initial movement is up/down
            if ((currentBounds.west.y > self.initialTouchBounds.west.y &&
                 currentBounds.east.y > self.initialTouchBounds.east.y) ||
                (currentBounds.west.y <= self.initialTouchBounds.west.y &&
                 currentBounds.east.y <= self.initialTouchBounds.east.y)) {
                    self.tiltPhase = MGLTiltGestureStateEnded;
                } else {
                    self.tiltPhase = MGLTiltGestureStateInvalidated;
                }
        }
    } else {
        if ( [self isWithinThreshold] )
        {
            self.tiltPhase = MGLTiltGestureStateEnded;
        } else {
            self.tiltPhase = MGLTiltGestureStateInvalidated;
        }
    }
    self.state = UIGestureRecognizerStateEnded;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.tiltPhase = MGLTiltGestureStateCancelled;
    self.state = UIGestureRecognizerStateCancelled;
}

- (void)reset {
    [super reset];
    self.tiltPhase = MGLTiltGestureStatePossible;
    self.initialTouchBounds = MGLTouchBoundsMake(self.CGPointNil, self.CGPointNil);
}

- (BOOL)isValidBounds:(MGLTouchBounds)bounds {
    BOOL state = YES;
    
    float slope = (bounds.west.y - bounds.east.y) / (bounds.west.x - bounds.east.x);
    
    float angle = atan(fabs(slope));
    float degrees = MGLDegreesFromRadians(angle);
    
    if (degrees > angleThreshold) {
        state = NO;
    }
    
    return state;
}

- (BOOL)isWithinThreshold {
    BOOL isWithinThreshold = YES;
    // Workaround to make a smooth transition for tilting the map
    // for some reason I have detected we get a single touch somtimes
    CGPoint velocity = [self velocityInView:self.view];
    double gestureAngle = MGLDegreesFromRadians(atan(velocity.y / velocity.x));
    double delta = fabs((fabs(gestureAngle) - 90.0));
    
    // cancel if gesture angle is not 90º±20º (more or less vertical)
    if ( delta < angleThreshold )
    {
        isWithinThreshold = NO;
    }
    
    return isWithinThreshold;
}

@end
