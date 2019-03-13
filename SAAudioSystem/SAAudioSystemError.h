//
//  SAAudioSystemError.h
//  SAAudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SAAudioSystemError) {
    // File Errors = 100, 101, 102
    SAAudioSystemErrorNotOpenFile = 100,
    SAAudioSystemErrorNotFoundAnyStream = 101,
    SAAudioSystemErrorNotFoundAudioStream = 102,

    // Bad Request Error = 200
    SAAudioSystemErrorNotFoundSourcePath = 200,

    // Server Error = 300
    SAAudioSystemErrorServerError = 300,
    
    // AudioQueue Error = 400, 401, 402, 403
    SAAudioSystemErrorNotSetAudioQueue = 400,
    SAAudioSystemErrorNotAudioQueueStarted = 401,
    SAAudioSystemErrorNotAudioQueueStopped = 402,
    SAAudioSystemErrorNotAudioQueuePaused = 403,

    // FFmpeg Decoder Error = 500, 501, 502
    SAAudioSystemErrorNotOpenCodec = 500,
    SAAudioSystemErrorWhileDecoding = 501,
    SAAudioSystemErrorSeekingFailed = 502,
};
