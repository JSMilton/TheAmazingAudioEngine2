//
//  AEAudioUnitV3Output.h
//  TheAmazingAudioEngine
//
//  Created by Jambo on 04/09/2017.
//  Copyright © 2017 A Tasty Pixel. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

@class AERenderer;

@interface AEAudioUnitV3Output : AUAudioUnit

@property (nonatomic, strong) AERenderer * _Nullable renderer;

- (instancetype _Nullable)initWithRenderer:(AERenderer * _Nonnull)renderer
                      componentDescription:(AudioComponentDescription)componentDescription
                                   options:(AudioComponentInstantiationOptions)options
                                     error:(NSError **)outError;

@end
