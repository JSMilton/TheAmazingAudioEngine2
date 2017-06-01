//
//  AETimeTests.m
//  TheAmazingAudioEngine
//
//  Created by Geoff Milton on 01/06/2017.
//  Copyright © 2017 A Tasty Pixel. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AETime.h"

@interface AETimeTests : XCTestCase

@end

@implementation AETimeTests

- (void)testTicksToBeats {
    
    AEHostTicks ticks = AEHostTicksFromSeconds(1.0);
    AEBeats beat = AEBeatsFromHostTicks(ticks, 120);
    AEBeats roundedBeats = round(beat * 10000) / 10000.0;
    XCTAssert(roundedBeats == 2.0);
}

- (void)testSecondsToBeats {
    
    AESeconds seconds = AESecondsFromBeats(1, 120);
    XCTAssert(seconds = 0.5);
}

@end
