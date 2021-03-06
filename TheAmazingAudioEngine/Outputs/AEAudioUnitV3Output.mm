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

NSString * AEAUV3CurrentPresetChangedNotification = @"AEAUV3CurrentPresetChangedNotification";

@interface AEAudioUnitV3Output ()

@property (nonatomic, strong) AEManagedValue * rendererValue;
@property AUAudioUnitBus *outputBus;
@property AUAudioUnitBusArray *outputBusArray;

@property (nonatomic, readwrite) AUParameterTree *parameterTree;

@end

@implementation AEAudioUnitV3Output
{
    BufferedOutputBus _outputBusBuffer;
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
    
    _outputBusBuffer.init(defaultFormat, 2);
    _outputBus = _outputBusBuffer.bus;
    _outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self busType:AUAudioUnitBusTypeOutput busses: @[_outputBus]];
    
    self.maximumFramesToRender = 1024;
    
    _parameterTree = parameterTree;
    
    [_outputBus addObserver:self forKeyPath:@"format" options:0 context:nil];
    
    return self;
}

- (AERenderer *)renderer {
    return self.rendererValue.objectValue;
}

- (void)setRenderer:(AERenderer *)renderer {
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
    
    if (self.allocateBlock) {
        self.allocateBlock();
    }
    
    return YES;
}

- (void)deallocateRenderResources {
    _outputBusBuffer.deallocateRenderResources();
    if (self.deallocateBlock) {
        self.deallocateBlock();
    }
    [super deallocateRenderResources];
}

- (void)setCurrentPreset:(AUAudioUnitPreset *)currentPreset
{
    [super setCurrentPreset:currentPreset];
    [[NSNotificationCenter defaultCenter] postNotificationName:AEAUV3CurrentPresetChangedNotification object:nil];
}

- (void)setFullState:(NSDictionary<NSString *,id> *)fullState
{
    [super setFullState:fullState];
    [[NSNotificationCenter defaultCenter] postNotificationName:AEAUV3CurrentPresetChangedNotification object:nil];
}

- (AUInternalRenderBlock)internalRenderBlock
{
    __unsafe_unretained typeof(self) THIS = self;
    
    return ^AUAudioUnitStatus(
                              AudioUnitRenderActionFlags *actionFlags,
                              const AudioTimeStamp       *timestamp,
                              AVAudioFrameCount           frameCount,
                              NSInteger                   outputBusNumber,
                              AudioBufferList            *outputData,
                              const AURenderEvent        *realtimeEventListHead,
                              AURenderPullInputBlock      pullInputBlock) {
        
        if (THIS->_musicalContextBlock) {
            double tempo = 0;
            THIS->_musicalContextBlock(&tempo, NULL, NULL, NULL, NULL, NULL);
            if (THIS->_musicContextChangedBlock) {
                THIS->_musicContextChangedBlock(tempo);
            }
        }
        
        AURenderEvent const *event = realtimeEventListHead;
        while (event) {
            if (event->head.eventType == AURenderEventMIDI) {
                if (THIS->_midiReceivedBlock) {
                    THIS->_midiReceivedBlock(event->MIDI.eventSampleTime - timestamp->mSampleTime, event->MIDI.data[0], event->MIDI.data[1], event->MIDI.data[2]);
                }
            }
            
            if (event->head.eventType == AURenderEventParameter) {
                if (THIS->_parameterChangeBlock) {
                    THIS->_parameterChangeBlock(0, event->parameter.parameterAddress, event->parameter.value);
                }
            }
            
            event = event->head.next;
        }
        
        THIS->_outputBusBuffer.prepareOutputBufferList(outputData, frameCount, true);
        
        __unsafe_unretained AERenderer *renderer = (__bridge AERenderer*)AEManagedValueGetValue(THIS->_rendererValue);
        AERendererRun(renderer, outputData, frameCount, timestamp);
        
        return noErr;
    };
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"format"]) {
        self.renderer.sampleRate = _outputBus.format.sampleRate;
        self.renderer.numberOfOutputChannels = _outputBus.format.channelCount;
    }
}

- (void)dealloc
{
    [_outputBus removeObserver:self forKeyPath:@"format"];
}

@end
