//
//  AudioQueuePlayer.m
//  FFmpegAudioPlayer
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import "AudioQueuePlayer.h"
#import "AudioDecoder.h"
#import "MetadataExtractor.h"
#import <libavformat/avformat.h>

@interface AudioQueuePlayer() <AudioDecoderDelegate>

@property (assign, nonatomic) AudioStreamBasicDescription format;
@property (assign, nonatomic) AudioQueueRef queue;
@property (assign, nonatomic) AudioQueueBufferRef *buffers;

@property (strong, nonatomic) AudioDecoder *decoder;
@property (assign, nonatomic) NSString *path;
@property (assign, nonatomic) Float64 timeStamp;

@end

@implementation AudioQueuePlayer

NSString * const AudioPlayerErrorDomain = @"com.sidekick.academy.error.audio.player";
Float64 const PLAYBACK_TIME = 0.5;
UInt32 const PLAYBACK_BUFFERS = 3;

- (instancetype)init {
    self = [super init];
    if (self) {
        _queue = NULL;
    }
    return self;
}

- (void)insertTrack:(NSString *)path withError:(NSError *__autoreleasing *)error {
    _state = AudioQueuePlayerStateTransitioning;
    [self.delegate audioPlayer:self didChangeState:_state];
    _path = path;
    if (!path) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotFoundSourcePath
                                     userInfo:@{NSLocalizedDescriptionKey:@"Could not found source path."}];
        }
        _state = AudioQueuePlayerStateInitialized;
        [self.delegate audioPlayer:self didChangeState:_state];
        return;
    }
    
    _decoder = [[AudioDecoder alloc] init];
    _decoder.delegate = self;
    [_decoder open:path error:error];

    _equalizer.metadata = [MetadataExtractor metadataWithPath:path];
    [_equalizer tune];
    _decoder.equalizer = _equalizer;
    
    if (*error) {
        [_decoder stop];
        return;
    }
    
    OSStatus err = [self setAudioQueue];
    if (err) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotSetAudioQueue
                                     userInfo:@{NSLocalizedDescriptionKey:@"Error occurred while setting up audio queue"}];
        }
        _state = AudioQueuePlayerStateInitialized;
        [self.delegate audioPlayer:self didChangeState:_state];
        [_decoder stop];
        return;
    }
    
    _finished = NO;
    _timeStamp = 0;
    _timeBase = _decoder.timeBase_den;
    
    Float64 curDuration = self.timeStamp / self.timeBase;
    [self.delegate audioPlayer:self didTrackPlayingForDuration:curDuration];
    [_decoder read];
    _state = AudioQueuePlayerStateReady;
    [self.delegate audioPlayer:self didChangeState:_state];
}

- (OSStatus)setAudioQueue {
    OSStatus err = -1;
    if (_decoder) {
        AudioStreamBasicDescription dataFormat = _decoder.dataFormat;
        err = AudioQueueNewOutput(&dataFormat,
                                  AQOutputCallback,
                                  (__bridge void * _Nullable)(self),
                                  NULL,
                                  kCFRunLoopCommonModes,
                                  0,
                                  &_queue);
    
        _buffers = calloc(PLAYBACK_BUFFERS, sizeof(AudioQueueBufferRef));
        UInt32 bufferByteSize = dataFormat.mSampleRate * dataFormat.mBytesPerFrame * PLAYBACK_TIME;
    
        for (int i = 0; i < PLAYBACK_BUFFERS; i++) {
            AudioQueueAllocateBuffer(_queue,            // queue
                                     bufferByteSize,    // size of buffers
                                     &_buffers[i]);     // buffers
        }
    }
    return err;
}

- (void)setTimeBase:(int64_t)timeBase {
    _timeBase = timeBase;
}

- (void)setTimeStamp:(Float64)timeStamp {
    _timeStamp = timeStamp;
}

- (void)setFinished:(BOOL)finished {
    _finished = finished;
}

- (void)playWithError:(NSError *__autoreleasing *)error {
    _state = AudioQueuePlayerStateTransitioning;
    [self.delegate audioPlayer:self didChangeState:_state];
    if (!_path) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotFoundSourcePath
                                     userInfo:@{NSLocalizedDescriptionKey:@"Could not found source path."}];
        }
        _state = AudioQueuePlayerStateInitialized;
        [self.delegate audioPlayer:self didChangeState:_state];
        [_decoder stop];
        return;
    }
    
    if (!_queue) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotSetAudioQueue
                                     userInfo:@{NSLocalizedDescriptionKey:@"Audio queue is not initianlized."}];
        }
        _state = AudioQueuePlayerStateInitialized;
        if (_delegate) {
            [self.delegate audioPlayer:self didChangeState:_state];
        }
        [_decoder stop];
        return;
    }
    
    for (int i = 0; i < PLAYBACK_BUFFERS; i++) {
        AQOutputCallback((__bridge void * _Nullable)(self), _queue, _buffers[i]);
    }
    
    OSStatus err = AudioQueueSetParameter(_queue,
                                          kAudioQueueParam_Volume,
                                          1.0);
    if (err) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotSetAudioQueue
                                     userInfo:@{NSLocalizedDescriptionKey:@"Error occurred while setting up audio queue."}];
        }
        _state = AudioQueuePlayerStateInitialized;
        [self.delegate audioPlayer:self didChangeState:_state];
        [_decoder stop];
        return;
    }
    
    Float64 duration = _decoder.duration;
    if (duration - (Float64)_timeStamp/_timeBase < 1) {
        self.finished = YES;
        [self stopWithError:nil];
        return;
    }

    err = AudioQueueStart(_queue, NULL);
    if (err) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotAudioQueueStarted
                                     userInfo:@{NSLocalizedDescriptionKey:@"Audio queue not started."}];
        }
        _state = AudioQueuePlayerStateInitialized;
        if (_delegate) {
            [self.delegate audioPlayer:self didChangeState:_state];
        }
        [_decoder stop];
        return;
    }
    _state = AudioQueuePlayerStatePlaying;
    [self.delegate audioPlayer:self didChangeState:_state];
}

- (void)stopWithError:(NSError *__autoreleasing *)error {
    _state = AudioQueuePlayerStateTransitioning;
    [self.delegate audioPlayer:self didChangeState:_state];

    if (!_queue) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotSetAudioQueue
                                     userInfo:@{NSLocalizedDescriptionKey:@"Audio queue is not initianlized."}];
        }
        _state = AudioQueuePlayerStateInitialized;
        [self.delegate audioPlayer:self didChangeState:_state];
        [_decoder stop];
        return;
    }
    [_decoder stop];
    OSStatus errStop = AudioQueueStop(_queue, true);
    OSStatus errFlush = AudioQueueFlush(_queue);
    OSStatus errFree = noErr;
    for (int i = 0; i < PLAYBACK_BUFFERS; i++) {
        errFree = AudioQueueFreeBuffer(_queue, _buffers[i]);
    }
    
    OSStatus errDispose = AudioQueueDispose(_queue, true);
    if (errStop || errFlush || errDispose || errFree) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotAudioQueueStopped
                                     userInfo:@{NSLocalizedDescriptionKey:@"Error occurred while stopping audio queue."}];
        }
    }

    _state = AudioQueuePlayerStateStopped;
    if (_delegate) {
        [self.delegate audioPlayer:self didChangeState:_state];
    }
}

- (void)seekToTarget:(int64_t)target withError:(NSError *__autoreleasing *)error {
    AudioQueuePlayerState lastState = _state;
    _state = AudioQueuePlayerStateTransitioning;
    [self.delegate audioPlayer:self didChangeState:_state];

    if (!_queue) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotSetAudioQueue
                                     userInfo:@{NSLocalizedDescriptionKey:@"Audio queue is not initianlized."}];
        }
        _state = AudioQueuePlayerStateInitialized;
        [self.delegate audioPlayer:self didChangeState:_state];
        [_decoder stop];
        return;
    }

    OSStatus errStop = AudioQueueStop(_queue, true);
    if (errStop) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotAudioQueueStopped
                                     userInfo:@{NSLocalizedDescriptionKey:@"Error occurred while stopping audio queue."}];
        }
        _state = AudioQueuePlayerStateInitialized;
        [self.delegate audioPlayer:self didChangeState:_state];
        [_decoder stop];
        return;
    }

    target *= _timeBase;
    [_decoder seekFrameToPos:target error:error];
    
    OSStatus errFlush = AudioQueueFlush(_queue);
    OSStatus errFree = noErr;
    for (int i = 0; i < PLAYBACK_BUFFERS; i++) {
        errFree = AudioQueueFreeBuffer(_queue, _buffers[i]);
    }
    
    OSStatus errDispose = AudioQueueDispose(_queue, true);
    if (errFlush || errDispose || errFree) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotAudioQueueStopped
                                         userInfo:@{NSLocalizedDescriptionKey:@"Error occurred while stopping audio queue."}];
        }
        _state = AudioQueuePlayerStateInitialized;
        if (_delegate) {
            [self.delegate audioPlayer:self didChangeState:_state];
        }
        [_decoder stop];
        return;
    }
    
    OSStatus err = [self setAudioQueue];
    if (err) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotSetAudioQueue
                                     userInfo:@{NSLocalizedDescriptionKey:@"Error occurred while setting up audio queue."}];
        }
        _state = AudioQueuePlayerStateInitialized;
        [self.delegate audioPlayer:self didChangeState:_state];
        [_decoder stop];
        return;
    }
    
    if (lastState == AudioQueuePlayerStatePlaying) {
        [self playWithError:error];
        
    } else {
        for (int i = 0; i < PLAYBACK_BUFFERS; i++) {
            AQOutputCallback((__bridge void * _Nullable)(self), _queue, _buffers[i]);
        }
        err = AudioQueueSetParameter(_queue,
                                     kAudioQueueParam_Volume,
                                     1.0);
        if (err) {
            if (error) {
                *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                             code:AudioSystemErrorNotSetAudioQueue
                                         userInfo:@{NSLocalizedDescriptionKey:@"Error occurred while setting up audio queue."}];
            }
            _state = AudioQueuePlayerStateInitialized;
            if (_delegate) {
                [self.delegate audioPlayer:self didChangeState:_state];
            }
            [_decoder stop];
            return;
        }

        [self pauseWithError:error];
    }
}

- (void)pauseWithError:(NSError *__autoreleasing *)error {
    if (!_queue) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotSetAudioQueue
                                     userInfo:@{NSLocalizedDescriptionKey:@"Audio queue is not initianlized."}];
        }
        _state = AudioQueuePlayerStateInitialized;
        [self.delegate audioPlayer:self didChangeState:_state];
        [_decoder stop];
        return;
    }
    
    OSStatus err = AudioQueuePause(_queue);
    if (err) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotAudioQueuePaused
                                     userInfo:@{NSLocalizedDescriptionKey:@"Error occurred while pausing audio queue."}];
        }
        _state = AudioQueuePlayerStateInitialized;
        if (_delegate) {
            [self.delegate audioPlayer:self didChangeState:_state];
        }
        [_decoder stop];
        return;
    }
    
    _state = AudioQueuePlayerStatePaused;
    [self.delegate audioPlayer:self didChangeState:_state];
}

- (void)resumeWithError:(NSError *__autoreleasing *)error {
    if (!_queue) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotSetAudioQueue
                                     userInfo:@{NSLocalizedDescriptionKey:@"Audio queue is not initianlized."}];
        }
        _state = AudioQueuePlayerStateInitialized;
        [self.delegate audioPlayer:self didChangeState:_state];
        [_decoder stop];
        return;
    }

    Float64 duration = _decoder.duration;
    if (duration - (Float64)_timeStamp/_timeBase < 1) {
        self.finished = YES;
        [self stopWithError:nil];
        return;
    }

    OSStatus err = AudioQueueStart(_queue, NULL);
    if (err) {
        if (error) {
            *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                         code:AudioSystemErrorNotAudioQueueStarted
                                     userInfo:@{NSLocalizedDescriptionKey:@"Audio queue not started."}];
        }
        _state = AudioQueuePlayerStateInitialized;
        if (_delegate) {
            [self.delegate audioPlayer:self didChangeState:_state];
        }
        [_decoder stop];
        return;
    }
    
    _state = AudioQueuePlayerStatePlaying;
    [self.delegate audioPlayer:self didChangeState:_state];
}

- (void)terminateWithError:(NSError *__autoreleasing *)error {
    if (_state != AudioQueuePlayerStateStopped) {
        _state = AudioQueuePlayerStateTransitioning;
        [self.delegate audioPlayer:self didChangeState:_state];

        [_decoder stop];
        OSStatus errStop = AudioQueueStop(_queue, true);
        OSStatus errFlush = AudioQueueFlush(_queue);
        OSStatus errFree = noErr;
        for (int i = 0; i < PLAYBACK_BUFFERS; i++) {
            errFree = AudioQueueFreeBuffer(_queue, _buffers[i]);
        }
        
        OSStatus errDispose = AudioQueueDispose(_queue, true);
        if (errStop || errFlush || errDispose || errFree) {
            if (error) {
                *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                             code:AudioSystemErrorNotAudioQueueStopped
                                         userInfo:@{NSLocalizedDescriptionKey:@"Error occurred while stopping audio queue."}];
            }
        }
    }

    _state = AudioQueuePlayerStateInitialized;
    [self.delegate audioPlayer:self didChangeState:_state];
}

- (void)endFile {
    Float64 duration = _decoder.duration * self.timeBase;
    self.timeStamp += PLAYBACK_TIME * self.timeBase;
    _state = AudioQueuePlayerStateFinished;
    [self.delegate audioPlayer:self didChangeState:_state];
    
    if (abs((int)(duration - self.timeStamp)) < PLAYBACK_TIME * self.timeBase) {
        [self.delegate audioPlayer:self didTrackPlayingForDuration:_decoder.duration];
        self.finished = YES;
        [self stopWithError:nil];
        return;
    }
    Float64 curDuration = self.timeStamp / self.timeBase;
    [self.delegate audioPlayer:self didTrackPlayingForDuration:curDuration];
    AudioQueueFlush(_queue);
}

static void AQOutputCallback(void * __nullable inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inAQBuffer) {
    AudioQueuePlayer *userData = (__bridge AudioQueuePlayer *)(inUserData);
    AudioDecoder *decoder = userData.decoder;
    
    if (!userData.buffers) {
        return;
    }
    
    if (userData->_state == AudioQueuePlayerStateStopped || userData->_state == AudioQueuePlayerStateInitialized) {
        return;
    }

    if (decoder.endOfFile) {
        memset(inAQBuffer->mAudioData, 0, inAQBuffer->mAudioDataBytesCapacity);
        OSStatus err = AudioQueueEnqueueBuffer(inAQ, inAQBuffer, 0, NULL);
        if (err != noErr) {
            UInt32 isRunning = 0;
            UInt32 size = sizeof(isRunning);
            AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &isRunning, &size);
            if (isRunning) {
                NSLog(@"Could not write data into audio queue because it is running.");
            }
        }
        [userData endFile];
        return;
    }
    
    int len = inAQBuffer->mAudioDataBytesCapacity;
    UInt32 numBytes;
    inAQBuffer->mAudioDataByteSize = 0;
    UInt8 *buffer = (UInt8 *)inAQBuffer->mAudioData;
    
    while (len > 0) {
        NSError *error = nil;
        BOOL isPlayable = [decoder decodeFrameInAQBufferCapacity:len outAQBuffer:buffer inFrameSize:&numBytes error:&error];
        if (error) {
            NSLog(@"Error occurred while decode frames = %@", error);
            return;
        }
        
        userData.timeStamp = decoder.timeStamp - (PLAYBACK_TIME * PLAYBACK_BUFFERS * userData.timeBase);
        UInt32 ret = numBytes;
        
        if (!isPlayable) {
            ret = len;
            memset(buffer, 0, ret);
        }
        
        len -= ret;
        inAQBuffer->mAudioDataByteSize += ret;
        buffer += ret;
    }
    
    OSStatus err = AudioQueueEnqueueBuffer(inAQ,
                                           inAQBuffer,
                                           0,
                                           NULL);
    if (err) {
        NSLog(@"Error occurred while enqueuing audio queue buffer.");
        return;
    }
    
    Float64 curDuration = (Float64) userData.timeStamp / userData.timeBase;
    [userData.delegate audioPlayer:userData didTrackPlayingForDuration:curDuration];
    
    if (err != noErr) {
        UInt32 isRunning = 0;
        UInt32 size = sizeof(isRunning);
        AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &isRunning, &size);
        if (isRunning) {
            NSLog(@"Counld not write data into audio queue because it is running.");
        }
        return;
    }
}

- (void)audioDecoder:(AudioDecoder *)audioDecoder didTrackReadingProgress:(Float64)progress {
    [_delegate audioPlayer:self didTrackReadingProgress:progress];
}

- (void)setEqualizer:(AudioEqualizer *)equalizer {
    _equalizer = equalizer;
    _decoder.equalizer = _equalizer;
}

@end
