//
//  AudioDecoder.h
//  FFmpegAudioPlayer
//
//  Created by debugholic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AudioSystemError.h"
#import "AudioMetadata.h"
#import "AudioEqualizer.h"

@class AudioDecoder;

@protocol AudioDecoderDelegate <NSObject>

- (void)audioDecoder:(AudioDecoder *_Nonnull)audioDecoder didTrackReadingProgress:(Float64)progress;

@end

@interface AudioDecoder : NSObject

@property (strong, nonatomic, nullable) id <AudioDecoderDelegate> delegate;
@property (strong, nonatomic, readonly, nullable) NSString *sourcePath;
@property (assign, nonatomic, readonly) AudioStreamBasicDescription dataFormat;
@property (assign, nonatomic, readonly) int64_t timeBase_den;
@property (assign, nonatomic, readonly) int64_t timeStamp;
@property (assign, nonatomic, readonly) NSUInteger duration;
@property (assign, nonatomic, readonly) BOOL readFinished;
@property (assign, nonatomic, readonly) BOOL endOfFile;
@property (assign, nonatomic, readonly) Float32 readProgress;
@property (strong, nonatomic, nullable) AudioEqualizer *equalizer;

- (void)open:(NSString * _Nonnull)path error:(NSError *_Nullable *_Nonnull)error;
- (void)close;
- (void)read;
- (BOOL)decodeFrameInAQBufferCapacity:(UInt32)bufferCapacity outAQBuffer:(UInt8 * _Nonnull)buffer inFrameSize:(UInt32 * _Nonnull)frameSize error:(NSError *_Nullable *_Nonnull)error;
- (void)stop;
- (void)seekFrameToPos:(int64_t)pos error:(NSError *_Nullable *_Nonnull)error;

@end
