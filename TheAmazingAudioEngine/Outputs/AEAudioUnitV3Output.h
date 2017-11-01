//
//  AEAudioUnitV3Output.h
//  TheAmazingAudioEngine
//
//  Created by Jambo on 04/09/2017.
//  Copyright © 2017 A Tasty Pixel. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "AETime.h"

@class AERenderer;

typedef void (^AEAUV3MIDIReceivedBlock)(UInt32 eventOffset, uint8_t statusByte, uint8_t dataByte1, uint8_t dataByte2);

@interface AEAudioUnitV3Output : AUAudioUnit

@property (nonatomic, strong) AERenderer * _Nullable renderer;
@property (copy) AEAUV3MIDIReceivedBlock midiReceivedBlock;

- (instancetype _Nullable)initWithRenderer:(AERenderer * _Nonnull)renderer
                             parameterTree:(AUParameterTree *)parameterTree
                      componentDescription:(AudioComponentDescription)componentDescription
                                   options:(AudioComponentInstantiationOptions)options
                                     error:(NSError **)outError;

@end
