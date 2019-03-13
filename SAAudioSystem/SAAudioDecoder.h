//
//  SAAudioDecoder.h
//  SAAudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SAAudioSystemError.h"
#import "SAAudioMetadata.h"

@class SAAudioDecoder;

@protocol SAAudioDecoderDelegate <NSObject>

- (void)audioDecoder:(SAAudioDecoder *)audioDecoder didTrackReadingProgress:(Float64)progress;

@end

@interface SAAudioDecoder : NSObject

@property (strong, nonatomic, nullable) id <SAAudioDecoderDelegate> delegate;
@property (strong, nonatomic, readonly, nullable) NSString *sourcePath;
@property (strong, nonatomic, readonly, nullable) SAAudioMetadata *metadata;
@property (assign, nonatomic, readonly) AudioStreamBasicDescription dataFormat;
@property (nonatomic, readonly) int64_t timeBase_den;
@property (nonatomic, readonly) int64_t timeStamp;
@property (assign, nonatomic) BOOL readFinished;
@property (assign, nonatomic) BOOL endOfFile;
@property (assign, nonatomic) Float32 readProgress;

- (void)openSource:(NSString *)sourcePath error:(NSError **)error;
- (void)closeSource;
- (void)readStart;
- (BOOL)decodeFrameInAQBufferCapacity:(UInt32)bufferCapacity outAQBuffer:(UInt8 *)buffer inFrameSize:(UInt32 *)frameSize error:(NSError **)error;
- (void)stopDecoding;
- (void)seekFrameToPos:(int64_t)pos error:(NSError **)error;

@end
