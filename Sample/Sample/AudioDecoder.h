//
//  AudioDecoder.h
//  FFmpegAudioPlayer
//
//  Created by DebugHolic on 08/03/2019.
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
@property (strong, nonatomic, readonly, nullable) AudioMetadata *metadata;
@property (strong, nonatomic, readonly, nullable) UIImage *albumArt;
@property (assign, nonatomic, readonly) AudioStreamBasicDescription dataFormat;
@property (nonatomic, readonly) int64_t timeBase_den;
@property (nonatomic, readonly) int64_t timeStamp;
@property (assign, nonatomic) BOOL readFinished;
@property (assign, nonatomic) BOOL endOfFile;
@property (assign, nonatomic) Float32 readProgress;
@property (strong, nonatomic, nullable) AudioEqualizer *equalizer;

- (void)open:(NSString * _Nonnull)path error:(NSError *_Nullable *_Nonnull)error;
- (void)close;
- (void)read;
- (BOOL)decodeFrameInAQBufferCapacity:(UInt32)bufferCapacity outAQBuffer:(UInt8 * _Nonnull)buffer inFrameSize:(UInt32 * _Nonnull)frameSize error:(NSError *_Nullable *_Nonnull)error;
- (void)stop;
- (void)seekFrameToPos:(int64_t)pos error:(NSError *_Nullable *_Nonnull)error;

@end
