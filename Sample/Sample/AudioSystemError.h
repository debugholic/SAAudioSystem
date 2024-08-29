//
//  AudioSystemError.h
//  AudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AudioSystemError) {
    // File Errors = 100, 101, 102
    AudioSystemErrorNotOpenFile = 100,
    AudioSystemErrorNotFoundAnyStream = 101,
    AudioSystemErrorNotFoundAudioStream = 102,

    // Bad Request Error = 200
    AudioSystemErrorNotFoundSourcePath = 200,

    // Server Error = 300
    AudioSystemErrorServerError = 300,
    
    // AudioQueue Error = 400, 401, 402, 403
    AudioSystemErrorNotSetAudioQueue = 400,
    AudioSystemErrorNotAudioQueueStarted = 401,
    AudioSystemErrorNotAudioQueueStopped = 402,
    AudioSystemErrorNotAudioQueuePaused = 403,

    // FFmpeg Decoder Error = 500, 501, 502
    AudioSystemErrorNotOpenCodec = 500,
    AudioSystemErrorWhileDecoding = 501,
    AudioSystemErrorSeekingFailed = 502,
};
