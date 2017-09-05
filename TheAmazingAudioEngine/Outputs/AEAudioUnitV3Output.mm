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

@end

@implementation AEAudioUnitV3Output
{
    BufferedOutputBus _outputBusBuffer;
}

- (instancetype)initWithRenderer:(AERenderer *)renderer
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
    __block AEManagedValue *rendererValue = self.rendererValue;
    return ^AUAudioUnitStatus(
                              AudioUnitRenderActionFlags *actionFlags,
                              const AudioTimeStamp       *timestamp,
                              AVAudioFrameCount           frameCount,
                              NSInteger                   outputBusNumber,
                              AudioBufferList            *outputData,
                              const AURenderEvent        *realtimeEventListHead,
                              AURenderPullInputBlock      pullInputBlock) {
        
        _outputBusBuffer.prepareOutputBufferList(outputData, frameCount, true);
        
        __unsafe_unretained AERenderer *renderer = (__bridge AERenderer*)AEManagedValueGetValue(rendererValue);
        AERendererRun(renderer, outputData, frameCount, timestamp);
        
        return noErr;
    };
}

@end
