//
//  MetadataExtractor.m
//  FFmpegAudioPlayer
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import "MetadataExtractor.h"
#import "AudioSystemError.h"

@implementation MetadataExtractor

+ (AudioMetadata *)metadataWithPath:(NSString *)path {
    if (!path) {
        return nil;
    }
    
    AVFormatContext *formatContext = avformat_alloc_context();
    const char *filePathStr = path.UTF8String;
    
    int ret = avformat_open_input(&formatContext, filePathStr, NULL, NULL);
    if (ret < 0) {
        return nil;
    }

    AudioMetadata *metadata = [MetadataExtractor metadataWithFormatContext:formatContext];
    if (formatContext != NULL) {
        avformat_close_input(&formatContext);
        avformat_free_context(formatContext);
    }
    return metadata;
}


+ (AudioMetadata *)metadataWithFormatContext:(AVFormatContext *)fmt_ctx {
    if (!fmt_ctx) {
        return nil;
    }

    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    AVDictionaryEntry *entry = NULL;

    while ((entry = av_dict_get(fmt_ctx->metadata, "", entry, AV_DICT_IGNORE_SUFFIX))) {
        NSString *key = [NSString stringWithUTF8String:entry->key];
        NSString *str = [NSString stringWithUTF8String:entry->value];
        const char *cString = [str cStringUsingEncoding:NSWindowsCP1252StringEncoding];
    
        NSString *code = [[NSLocale preferredLanguages] firstObject];
        NSUInteger encoding = 0;
        NSString *langCode = code;
        
        if ([langCode isEqualToString:@"ko"]) {
            encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_KR);
       
        } else if ([langCode isEqualToString:@"ja"]) {
            encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS);
            
        } else if ([langCode isEqualToString:@"zh-Hans"]) {
            encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGBK_95);
            
        } else if ([langCode isEqualToString:@"zh-Hant"]) {
            encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5);
            
        } else {
            encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF8);
        }
    
        NSString *value = nil;
        if (cString) {
            value = [NSString stringWithCString:cString encoding:encoding];
        }
        
        if (!value) {
            value = str;
        }
        
        [metadata setObject:value forKey:key];
    }
    
    AVCodecParameters *codecParams;
    int timeBase_den = 0;
    int64_t duration = 0;
    
    for (int i = 0; i < fmt_ctx->nb_streams; i++) {
        if (fmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            codecParams = fmt_ctx->streams[i]->codecpar;
            timeBase_den = fmt_ctx->streams[i]->time_base.den;
            duration = fmt_ctx->streams[i]->duration;
            break;
        }
    }
    
    AVCodecContext *codec_ctx = avcodec_alloc_context3(NULL);
    avcodec_parameters_to_context(codec_ctx, codecParams);

    [metadata setValue:@(codec_ctx->sample_rate) forKey:@"samplerate"];
    [metadata setValue:@(codec_ctx->ch_layout.nb_channels) forKey:@"channels"];
    
    int bitDepth = 0;
    
    if (codec_ctx->codec_id == AV_CODEC_ID_FLAC) {
        bitDepth = codec_ctx->bits_per_raw_sample;
    } else {
        bitDepth = codec_ctx->bits_per_coded_sample;
    }
    NSString *sampleformat = [NSString stringWithFormat:@"%s", av_get_sample_fmt_name(codec_ctx->sample_fmt)];
    [metadata setValue:sampleformat forKey:AudioMetadataSampleformatKey];
    
    if (!bitDepth) {
        switch(codec_ctx->sample_fmt) {
            case AV_SAMPLE_FMT_U8 :
            case AV_SAMPLE_FMT_U8P :
                bitDepth = 8;
                break;
                
            case AV_SAMPLE_FMT_S16 :
            case AV_SAMPLE_FMT_S16P :
                bitDepth = 16;
                break;
                
            case AV_SAMPLE_FMT_S32 :
            case AV_SAMPLE_FMT_S32P :
            case AV_SAMPLE_FMT_FLT :
            case AV_SAMPLE_FMT_FLTP :
            case AV_SAMPLE_FMT_DBL :
            case AV_SAMPLE_FMT_DBLP :
                bitDepth = 32;
                break;
                
            default:
                break;
        }
    }
    
    [metadata setValue:@(bitDepth) forKey:AudioMetadataBitdepthKey];
    [metadata setValue:@(duration/timeBase_den) forKey:AudioMetadataDurationKey];

    if (codec_ctx != NULL) {
        avcodec_close(codec_ctx);
    }

    return [AudioMetadata metadataWithDictionary:metadata];
}

@end
