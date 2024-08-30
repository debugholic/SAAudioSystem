//
//  AudioDecoder.m
//  FFmpegAudioPlayer
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import "AudioDecoder.h"
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#import <libavformat/avformat.h>
#import <libswresample/swresample.h>
#import <libavutil/opt.h>
#import "PacketQueue.h"
#import "MetadataCollector.h"
#import "AlbumArtExtractor.h"

@interface AudioDecoder()

@property (assign, nonatomic) AVFormatContext *formatContext;
@property (assign, nonatomic) AVCodecContext *codecContext;
@property (assign, nonatomic) const AVCodec *codec;
@property (assign, nonatomic) SwrContext *swrContext;
@property (assign, nonatomic) int audioStreamIndex;

@property (assign, nonatomic) AVPacket packet;
@property (assign, nonatomic) AVFrame *frame;
@property (assign, nonatomic) UInt32 frameRemainderSize;
@property (assign, nonatomic) UInt32 frameRemainderIndex;

@property (assign, nonatomic) PacketQueue packetQueue;
@property (assign, nonatomic) PacketQueue cacheQueue;

@property (assign, nonatomic) BOOL stopDecode;
@property (assign, nonatomic) BOOL stopRead;
@property (assign, nonatomic) BOOL seekable;
@property (assign, nonatomic) AudioEqualizerFlag eqFlag;

@end

NSString * const AudioDecoderErrorDomain = @"com.sidekick.academy.error.audio.decoder";

@implementation AudioDecoder

- (instancetype)init {
    self = [super init];
    if (self) {
        _formatContext = NULL;
        _codecContext = NULL;
        _codec = NULL;
        _swrContext = NULL;
        _audioStreamIndex = -1;
        _frame = NULL;
        _readFinished = NO;
        _stopRead = NO;
        _stopDecode = NO;
        _endOfFile = NO;
        _seekable = NO;
        _equalizer = [[AudioEqualizer alloc] initWithDefautBands_10];
        _adjustEQ = NO;
        _eqFlag = AudioEqualizerFlagNone;
    }
    return self;
}

- (void)open:(NSString *)path error:(NSError *__autoreleasing *)error {
    if (!path) {
        *error = [NSError errorWithDomain:AudioDecoderErrorDomain
                                     code:AudioSystemErrorNotFoundSourcePath
                                 userInfo:@{NSLocalizedDescriptionKey:@"Could not found source path."}];

        return;
    }

    avformat_network_init();
    packet_queue_init(&_packetQueue);
    
    _formatContext = avformat_alloc_context();
    _sourcePath = [path copy];
    const char *filePathStr = _sourcePath.UTF8String;
    
    int ret = avformat_open_input(&_formatContext, filePathStr, NULL, NULL);
    if (ret < 0) {
        if (AVERROR(ret) == AVERROR_HTTP_SERVER_ERROR) {
            *error = [NSError errorWithDomain:AudioDecoderErrorDomain
                                         code:AudioSystemErrorServerError
                                     userInfo:@{NSLocalizedDescriptionKey:@"Could not connect a server"}];
        } else {
            *error = [NSError errorWithDomain:AudioDecoderErrorDomain
                                         code:AudioSystemErrorNotOpenFile
                                     userInfo:@{NSLocalizedDescriptionKey:@"Could not open an input file."}];
        }
        return;
    }
    
    ret = avformat_find_stream_info(_formatContext, NULL);
    if (ret < 0) {
        *error = [NSError errorWithDomain:AudioDecoderErrorDomain
                                     code:AudioSystemErrorNotFoundAnyStream
                                 userInfo:@{NSLocalizedDescriptionKey:@"Could not found any streams."}];
        return;
    }
    
    for (int i = 0; i < (_formatContext->nb_streams); i++) {
        if (_formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            _audioStreamIndex = i;
            break;
        }
    }
    
    if (_audioStreamIndex == -1) {
        *error = [NSError errorWithDomain:AudioDecoderErrorDomain
                                     code:AudioSystemErrorNotFoundAudioStream
                                 userInfo:@{NSLocalizedDescriptionKey:@"Could not found any audio streams."}];
        return;
    }
    
    _frameRemainderIndex = 0;
    _frameRemainderSize = 0;
    
    AVCodecParameters *codecParams = _formatContext->streams[_audioStreamIndex]->codecpar;
    _codecContext = avcodec_alloc_context3(NULL);
    avcodec_parameters_to_context(_codecContext, codecParams);
    
    if (_codecContext->codec_id == AV_CODEC_ID_DSD_LSBF
        || _codecContext->codec_id == AV_CODEC_ID_DSD_MSBF
        || _codecContext->codec_id == AV_CODEC_ID_DSD_LSBF_PLANAR
        || _codecContext->codec_id == AV_CODEC_ID_DSD_MSBF_PLANAR) {
        *error = [NSError errorWithDomain:AudioDecoderErrorDomain
                                     code:AudioSystemErrorNotOpenCodec
                                 userInfo:@{NSLocalizedDescriptionKey:@"Could not open codec."}];
        return;
    }
    
    _codec = avcodec_find_decoder(_codecContext->codec_id);
    ret = avcodec_open2(_codecContext, _codec, NULL);
    if (ret < 0) {
        *error = [NSError errorWithDomain:AudioDecoderErrorDomain
                                     code:AudioSystemErrorNotOpenCodec
                                 userInfo:@{NSLocalizedDescriptionKey:@"Could not open codec."}];
        return;
    }
    
    _dataFormat.mSampleRate = _codecContext->sample_rate;
    _dataFormat.mChannelsPerFrame = _codecContext->channels;
    _dataFormat.mFramesPerPacket = 1;
    _dataFormat.mReserved = 0;
    _dataFormat.mFormatID = kAudioFormatLinearPCM;
    _dataFormat.mFormatFlags = kAudioFormatFlagIsPacked;
    
//    if (_codecContext->channel_layout == 0) {
//        _codecContext->channel_layout = av_get_default_channel_layout(_codecContext->channels);
//    }
    
    enum AVSampleFormat outDecodeFormat = AV_SAMPLE_FMT_S16;
    switch(_codecContext->sample_fmt) {
        case AV_SAMPLE_FMT_U8P :
            outDecodeFormat = AV_SAMPLE_FMT_U8;
        case AV_SAMPLE_FMT_U8 :
            _dataFormat.mFormatFlags |= kAudioFormatFlagIsSignedInteger;
            _dataFormat.mBitsPerChannel = 8;
            break;
            
        case AV_SAMPLE_FMT_S16P :
            outDecodeFormat = AV_SAMPLE_FMT_S16;
        case AV_SAMPLE_FMT_S16 :
            _dataFormat.mFormatFlags |= kAudioFormatFlagIsSignedInteger;
            _dataFormat.mBitsPerChannel = 16;
            break;
            
        case AV_SAMPLE_FMT_S32P :
            outDecodeFormat = AV_SAMPLE_FMT_S32;
        case AV_SAMPLE_FMT_S32 :
            _dataFormat.mFormatFlags |= kAudioFormatFlagIsSignedInteger;
            _dataFormat.mBitsPerChannel = 32;
            break;
            
        case AV_SAMPLE_FMT_FLTP :
            outDecodeFormat = AV_SAMPLE_FMT_FLT;
        case AV_SAMPLE_FMT_FLT :
            _dataFormat.mFormatFlags |= kAudioFormatFlagIsFloat;
            _dataFormat.mBitsPerChannel = 32;
            break;
            
        case AV_SAMPLE_FMT_DBLP :
        case AV_SAMPLE_FMT_DBL :
            outDecodeFormat = AV_SAMPLE_FMT_FLT;
            _dataFormat.mFormatFlags |= kAudioFormatFlagIsFloat;
            _dataFormat.mBitsPerChannel = 32;
            break;
            
        default:
            break;
    }
    
    if (_codecContext->sample_fmt == AV_SAMPLE_FMT_U8P
        || _codecContext->sample_fmt == AV_SAMPLE_FMT_S16P
        || _codecContext->sample_fmt == AV_SAMPLE_FMT_S32P
        || _codecContext->sample_fmt == AV_SAMPLE_FMT_FLTP
        || _codecContext->sample_fmt == AV_SAMPLE_FMT_DBL
        || _codecContext->sample_fmt == AV_SAMPLE_FMT_DBLP) {
        _swrContext = swr_alloc_set_opts( NULL,
                                         _codecContext->channel_layout,
                                         outDecodeFormat,
                                         _codecContext->sample_rate,
                                         _codecContext->channel_layout,
                                         _codecContext->sample_fmt,
                                         _codecContext->sample_rate, 0, NULL );
        swr_init(_swrContext);
    }

    _dataFormat.mBytesPerFrame = (_dataFormat.mBitsPerChannel / 8) * _dataFormat.mChannelsPerFrame;
    _dataFormat.mBytesPerPacket = _dataFormat.mBytesPerFrame * _dataFormat.mFramesPerPacket;
    
    _metadata = [MetadataCollector metadataWithFormatContext:_formatContext];
    _albumArt = [AlbumArtExtractor albumArtWithFormatContext:_formatContext];
    
    _frameRemainderIndex = 0;
    _frameRemainderSize = 0;
    
    _timeBase_den = _formatContext->streams[_audioStreamIndex]->time_base.den;
    _stopRead = NO;
}


- (void)close {
    if (_packetQueue.size > 0) {
        packet_queue_destroy(&_packetQueue);
    }

    if (_cacheQueue.size > 0) {
        packet_queue_destroy(&_cacheQueue);
    }
    
    if (_swrContext != NULL ) {
        swr_free(&_swrContext);                     // Release SwrContext.
    }
    
    if (_codecContext != NULL) {
        avcodec_close(_codecContext);               // Close codec.
    }
    
    if (_formatContext != NULL) {
        avformat_close_input(&_formatContext);      // Close container.
        avformat_free_context(_formatContext);      // Release container.
    }
    _metadata = nil;
}

- (void)read {
    _readFinished = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self readAudioFrameWithError:nil];
    });
}

- (void)readAudioFrameWithError:(NSError **)error {
    if (!_formatContext) {
        _stopRead = YES;
        _readFinished = YES;
        [self stop];
        if (error) {
            *error = [NSError errorWithDomain:AudioDecoderErrorDomain
                                         code:AudioSystemErrorWhileDecoding
                                     userInfo:@{NSLocalizedDescriptionKey:@"Reading frames failed because formatContext is null."}];
        }
        return;
    }

    NSUInteger loop = 0;
    while (!_stopRead) {
        AVPacket packet;
        int ret = av_read_frame(_formatContext, &packet);
        if (ret < 0) {
            _readFinished = YES;
            return;
        }
        
        if (loop > 0 && _cacheQueue.size > 0) {
            while (packet.pts >= _cacheQueue.first->pkt.pts) {
                if (packet.pts == _cacheQueue.first->pkt.pts) {
                    packet_queue_copy(&_cacheQueue, &_packetQueue);
                    avformat_seek_file(_formatContext, _audioStreamIndex, INT64_MIN, _cacheQueue.pts, INT64_MAX, AVSEEK_FLAG_FRAME);
                    packet_queue_destroy(&_cacheQueue);
                    av_packet_unref (&packet);
                    break;
                }
                
                AVPacket gabagePacket;
                packet_queue_get_packet(&_cacheQueue, &gabagePacket);
                av_packet_unref(&gabagePacket);

                if (_cacheQueue.nb_packets == 0) {
                    break;
                }
            }
        }
        int64_t duration = (int64_t)_metadata.duration * _timeBase_den;
        if (packet.pts < duration && packet.pts > _packetQueue.pts) {
            packet_queue_put_packet(&_packetQueue, &packet);
        }
        loop++;
        
        if (_delegate && _metadata) {
             Float64 progress = (Float64) _packetQueue.pts / _metadata.duration;
            [_delegate audioDecoder:self didTrackReadingProgress:progress];
        }
        
    }
    _readFinished = YES;
    if (_stopDecode && _stopRead) {
        [self close];
    }
}

- (void)stop {
    _stopDecode = YES;
    _stopRead = YES;
    if (_readFinished) {
        [self close];
    }
}

- (void)setAdjustEQ:(BOOL)adjustEQ {
    if (_adjustEQ != adjustEQ) {
        if (adjustEQ) {
            _eqFlag = AudioEqualizerFlagOn;
        } else {
            _eqFlag = AudioEqualizerFlagOff;
        }
    }
    _adjustEQ = adjustEQ;
}

- (BOOL)decodeFrameInAQBufferCapacity:(UInt32)bufferCapacity outAQBuffer:(UInt8 *)buffer inFrameSize:(UInt32 *)frameSize error:(NSError **)error {
    if (!_sourcePath || !buffer) {
        return NO;
    }
    
    int ret = [self decodeFrameInAQBufferCapacity:bufferCapacity outAQBuffer:buffer error:error];
    if (ret < 0) {
        *error = [NSError errorWithDomain:AudioDecoderErrorDomain
                                     code:AudioSystemErrorWhileDecoding
                                 userInfo:@{NSLocalizedDescriptionKey:@"Error occurred while decoding."}];
        return NO;
    }
    
    *frameSize = ret;
    return YES;
}

- (int)decodeFrameInAQBufferCapacity:(UInt32)bufferCapacity outAQBuffer:(UInt8 *)buffer error:(NSError **)error {
    int frameSize = 0;
    
    // If a frame remained in previous writing.
    if (_frameRemainderSize > 0) {
        frameSize = _frameRemainderSize;
        _frameRemainderSize = 0;
    }
    
    // Else allocate a new frame.
    else {
        _frame = av_frame_alloc();
        frameSize = [self drainPacket:error];
        
        if (frameSize < 0) {
            av_frame_free(&_frame);
            return frameSize;
        }
    }
    
    // If a remaining buffer size is less than a decoded frame size. Then fulfill the remaining buffer.
    if (bufferCapacity < frameSize) {
        _frameRemainderSize = frameSize - bufferCapacity;
        frameSize = bufferCapacity;
    }
    
    // Non-planar data.
    if (!av_sample_fmt_is_planar(_codecContext->sample_fmt)
        && _codecContext->sample_fmt != AV_SAMPLE_FMT_DBL) {
        if (_adjustEQ) {
            [_equalizer adjust:_frame->data[0]+_frameRemainderIndex length:frameSize flag:_eqFlag];
            if (_eqFlag != AudioEqualizerFlagNone) {
                _eqFlag = AudioEqualizerFlagNone;
            }
        }
        memcpy(buffer, _frame->data[0]+_frameRemainderIndex, frameSize);
    }
    
    // Planar and double type data.
    else {
        UInt8 *cvtData = NULL;
        switch (_codecContext->sample_fmt) {
            case AV_SAMPLE_FMT_U8P :
                av_samples_alloc(&cvtData, NULL, _codecContext->ch_layout.nb_channels, _frame->nb_samples, AV_SAMPLE_FMT_U8, 0);
                break;
                
            case AV_SAMPLE_FMT_S16P :
                av_samples_alloc(&cvtData, NULL, _codecContext->ch_layout.nb_channels, _frame->nb_samples, AV_SAMPLE_FMT_S16, 0);
                break;
                
            case AV_SAMPLE_FMT_S32P :
                av_samples_alloc(&cvtData, NULL, _codecContext->ch_layout.nb_channels, _frame->nb_samples, AV_SAMPLE_FMT_S32, 0);
                break;
                
            case AV_SAMPLE_FMT_FLTP :
            case AV_SAMPLE_FMT_DBL :
            case AV_SAMPLE_FMT_DBLP :
                av_samples_alloc(&cvtData, NULL, _codecContext->ch_layout.nb_channels, _frame->nb_samples, AV_SAMPLE_FMT_FLT, 0);
                break;
                
            default :
                cvtData = _frame->data[0];
                break;
        }
        
        if (cvtData && _swrContext) {
            if (_codecContext->sample_fmt == AV_SAMPLE_FMT_DBL) {
                swr_convert(_swrContext,
                            &cvtData,
                            _frame->nb_samples,
                            (const uint8_t **) _frame->data,
                            _frame->nb_samples);
            } else {
                swr_convert(_swrContext,
                            &cvtData,
                            _frame->nb_samples,
                            (const uint8_t **) _frame->extended_data,
                            _frame->nb_samples);
            }

            if (_adjustEQ) {
                [_equalizer adjust:cvtData+_frameRemainderIndex length:frameSize flag:_eqFlag];
                if (_eqFlag != AudioEqualizerFlagNone) {
                    _eqFlag = AudioEqualizerFlagNone;
                }
            }

            memcpy(buffer, cvtData+_frameRemainderIndex, frameSize);
            if (frameSize > 0) {
                av_freep(&cvtData);
            }
        }
    }
    
    // If a frame remained. Then set it's index to a remainder index.
    if (_frameRemainderSize > 0) {
        _frameRemainderIndex = bufferCapacity;
    }
    
    // Else deallocate the frame and initializer the index.
    else {
        _frameRemainderIndex = 0;
        av_frame_unref(_frame);
        av_frame_free(&_frame);
        _frame = NULL;
    }
    
    return frameSize;
}

- (void)seekFrameToPos:(int64_t)pos error:(NSError **)error {
    _stopRead = YES;
    while (!_readFinished) {
        [NSThread sleepForTimeInterval:1];
    }
    
    if (!_formatContext) {
        *error = [NSError errorWithDomain:AudioDecoderErrorDomain
                                     code:AudioSystemErrorSeekingFailed
                                 userInfo:@{NSLocalizedDescriptionKey:@"Seeking failed because formatContext is null."}];
        return;
    }
    
    int ret = avformat_seek_file(_formatContext, _audioStreamIndex, INT64_MIN, pos, INT64_MAX, AVSEEK_FLAG_FRAME);
    if (ret < 0) {
        *error = [NSError errorWithDomain:AudioDecoderErrorDomain
                                     code:AudioSystemErrorSeekingFailed
                                 userInfo:@{NSLocalizedDescriptionKey:@"Seeking failed."}];
        return;
    }

    if (_frame) {
        av_frame_unref(_frame);
        av_frame_free(&_frame);
        _frame = NULL;
        _frameRemainderSize = 0;
        _frameRemainderIndex = 0;
    }
    
    avcodec_flush_buffers(_codecContext);
    packet_queue_init(&_cacheQueue);
    packet_queue_copy(&_packetQueue, &_cacheQueue);
    packet_queue_destroy(&_packetQueue);
    packet_queue_init(&_packetQueue);

    self.stopRead = NO;
    [self read];
}


- (void)feedPacket:(NSError **)error {
    AVPacket *packet = av_packet_alloc();
    BOOL gotPacket = packet_queue_get_packet(&_packetQueue, packet);
    
    if (gotPacket) {
        int ret = avcodec_send_packet(_codecContext, packet);
        _timeStamp = packet->pts;
        
        if (packet->data != NULL) {
            av_packet_unref(packet);
        }
        if (ret == AVERROR(EAGAIN)) {
            [self drainPacket:error];
            return;
        } else if (ret == AVERROR_EOF) {
            _endOfFile = YES;
            return;
        } else if (ret < 0) {
            return;
        } else {
            return;
        }
    } else {
        if (_readFinished) {
            _endOfFile = YES;
        
        // Wait for draining packets.
        } else {
            [NSThread sleepForTimeInterval:0.5];
        }
    }
}

- (int)drainPacket:(NSError **)error {
    int ret = 0;
    ret = avcodec_receive_frame(_codecContext, _frame);
    
    if (ret == AVERROR(EAGAIN)) {
        [self feedPacket:error];
        if (_stopDecode || _endOfFile) {
            return -1;
        }
        
    } else if (ret == AVERROR_EOF) {
        _endOfFile = YES;
        return -1;
        
    } else if (ret < 0) {
        return -1;
        
    } else {
        int frameSize = av_samples_get_buffer_size(NULL, _codecContext->ch_layout.nb_channels,
                                                   _frame->nb_samples,
                                                   _codecContext->sample_fmt, 1);
        return frameSize;
    }
    return 0;
}
@end
