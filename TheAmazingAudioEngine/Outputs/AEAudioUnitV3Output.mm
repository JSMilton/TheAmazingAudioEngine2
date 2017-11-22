//
//  AEAudioUnitV3Output.m
//  TheAmazingAudioEngine
//
//  Created by Jambo on 04/09/2017.
//  Copyright © 2017 A Tasty Pixel. All rights reserved.
//

#import "AEAudioUnitV3Output.h"
#import "AERenderer.h"
#import "AEManagedValue.h"

#include "BufferedAudioBus.hpp"

@interface AEAudioUnitV3Output ()

@property (nonatomic, strong) AEManagedValue * rendererValue;
@property AUAudioUnitBus *outputBus;
@property AUAudioUnitBusArray *outputBusArray;

@property (nonatomic, readwrite) AUParameterTree *parameterTree;

@end

@implementation AEAudioUnitV3Output
{
    BufferedOutputBus _outputBusBuffer;
    //AUHostMusicalContextBlock _musicalContextBlockCache;
}
@synthesize parameterTree = _parameterTree;
@synthesize musicalContextBlock = _musicalContextBlock;

- (instancetype)initWithRenderer:(AERenderer *)renderer
                   parameterTree:(AUParameterTree *)parameterTree
            componentDescription:(AudioComponentDescription)componentDescription
                         options:(AudioComponentInstantiationOptions)options
                           error:(NSError *__autoreleasing *)outError
{
    if ( !(self = [super initWithComponentDescription:componentDescription options:options error:outError]) ) return nil;
    
    self.rendererValue = [AEManagedValue new];
    self.renderer = renderer;
    
    AVAudioFormat *defaultFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100. channels:2];
    
    self.renderer.sampleRate = defaultFormat.sampleRate;
    self.renderer.numberOfOutputChannels = defaultFormat.channelCount;
    
    _outputBusBuffer.init(defaultFormat, 2);
    _outputBus = _outputBusBuffer.bus;
    _outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self busType:AUAudioUnitBusTypeOutput busses: @[_outputBus]];
    
    self.maximumFramesToRender = 512;
    
    _parameterTree = parameterTree;
    
    return self;
}

- (AERenderer *)renderer {
    return self.rendererValue.objectValue;
}

- (void)setRenderer:(AERenderer *)renderer {
//    renderer.sampleRate = self.ioUnit.currentSampleRate;
//    renderer.numberOfOutputChannels = self.ioUnit.numberOfOutputChannels;
    renderer.isOffline = NO;
    
    self.rendererValue.objectValue = renderer;
}

- (AUAudioUnitBusArray *)outputBusses {
    return _outputBusArray;
}

- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
    if (![super allocateRenderResourcesAndReturnError:outError]) {
        return NO;
    }
    
    _outputBusBuffer.allocateRenderResources(self.maximumFramesToRender);
    
    return YES;
}

- (void)deallocateRenderResources {
    _outputBusBuffer.deallocateRenderResources();
    
    [super deallocateRenderResources];
}

- (AUInternalRenderBlock)internalRenderBlock
{
    return ^AUAudioUnitStatus(
                              AudioUnitRenderActionFlags *actionFlags,
                              const AudioTimeStamp       *timestamp,
                              AVAudioFrameCount           frameCount,
                              NSInteger                   outputBusNumber,
                              AudioBufferList            *outputData,
                              const AURenderEvent        *realtimeEventListHead,
                              AURenderPullInputBlock      pullInputBlock) {
        
        if (_musicalContextBlock) {
            double tempo = 0;
            _musicalContextBlock(&tempo, NULL, NULL, NULL, NULL, NULL);
            if (_musicContextChangedBlock) {
                _musicContextChangedBlock(tempo);
            }
        }
        
        AURenderEvent const *event = realtimeEventListHead;
        while (event) {
            if (event->head.eventType == AURenderEventMIDI) {
                if (_midiReceivedBlock) {
                    _midiReceivedBlock(event->MIDI.eventSampleTime - timestamp->mSampleTime, event->MIDI.data[0], event->MIDI.data[1], event->MIDI.data[2]);
                }
            }
            
            if (event->head.eventType == AURenderEventParameter) {
                if (_parameterChangeBlock) {
                    _parameterChangeBlock(0, event->parameter.parameterAddress, event->parameter.value);
                }
            }
            
            event = event->head.next;
        }
        
        _outputBusBuffer.prepareOutputBufferList(outputData, frameCount, true);
        
        __unsafe_unretained AERenderer *renderer = (__bridge AERenderer*)AEManagedValueGetValue(_rendererValue);
        AERendererRun(renderer, outputData, frameCount, timestamp);
        
        return noErr;
    };
}

@end
