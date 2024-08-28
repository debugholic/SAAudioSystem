//
//  SAMetadataCollector.m
//  SAAudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import "SAMetadataCollector.h"

@implementation SAMetadataCollector

+ (SAAudioMetadata *)metadataWithFormatContext:(AVFormatContext *)formatContext {
    if (!formatContext) {
        return nil;
    }

    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    AVDictionaryEntry *entry = NULL;

    while ((entry = av_dict_get(formatContext->metadata, "", entry, AV_DICT_IGNORE_SUFFIX))) {
        NSString *key = [NSString stringWithUTF8String:entry->key];
        NSString *str = [NSString stringWithUTF8String:entry->value];
        const char *cString = [str cStringUsingEncoding:NSWindowsCP1252StringEncoding];
    
        NSString *code = [[NSLocale preferredLanguages] firstObject];
        NSUInteger encoding = 0;
        NSString *langCode;
        NSString *countryCode;
        if ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] == NSOrderedAscending) {
            langCode = code;
        } else {
            NSArray *codes = [code componentsSeparatedByString:@"-"];
            langCode = @"";
            for (NSUInteger i = 0; i < codes.count-1; i++) {
                if (i > 0) {
                    langCode = [langCode stringByAppendingString:@"-"];
                }
                langCode = [langCode stringByAppendingString:codes[i]];
            }
            countryCode = codes.lastObject;
        }
    
        if ([langCode isEqualToString:@"ko"] || [countryCode isEqualToString:@"KR"]) {
            encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_KR);
        } else if ([langCode isEqualToString:@"ja"] || [countryCode isEqualToString:@"JP"]) {
            encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS);
        } else if ([langCode isEqualToString:@"zh-Hans"] || [countryCode isEqualToString:@"CN"] || [countryCode isEqualToString:@"SG"]) {
            encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGBK_95);
        } else if ([langCode isEqualToString:@"zh-Hant"] || [countryCode isEqualToString:@"HK"] || [countryCode isEqualToString:@"MO"] || [countryCode isEqualToString:@"TW"]) {
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
    
    for (int i = 0; i < formatContext->nb_streams; i++) {
        if (formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            codecParams = formatContext->streams[i]->codecpar;
            timeBase_den = formatContext->streams[i]->time_base.den;
            duration = formatContext->streams[i]->duration;
            break;
        }
    }
    
    AVCodecContext *codecContext = avcodec_alloc_context3(NULL);
    avcodec_parameters_to_context(codecContext, codecParams);

    [metadata setValue:@(codecContext->sample_rate) forKey:@"samplerate"];
    [metadata setValue:@(codecContext->channels) forKey:@"channels"];
    
    int bitDepth = 0;
    
    if (codecContext->codec_id == AV_CODEC_ID_FLAC) {
        bitDepth = codecContext->bits_per_raw_sample;
    } else {
        bitDepth = codecContext->bits_per_coded_sample;
    }
    
    if (!bitDepth) {
        switch(codecContext->sample_fmt) {
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
    
    [metadata setValue:@(bitDepth) forKey:SAAudioMetadataBitdepthKey];
    [metadata setValue:@(duration/timeBase_den) forKey:SAAudioMetadataDurationKey];

    if (codecContext != NULL) {
        avcodec_close(codecContext);
    }

    return [SAAudioMetadata metadataWithDictionary:metadata];
}

@end
