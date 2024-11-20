//
//  AudioEqualizer.m
//  FFmpegAudioPlayer
//
//  Created by DebugHolic on 18/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import "AudioEqualizer.h"
#import <libavfilter/avfilter.h>
#import <libavfilter/buffersrc.h>
#import <libavfilter/buffersink.h>
#import <libavutil/channel_layout.h>
#import <libavutil/opt.h>

@interface AudioEqualizer()

@property (assign, nonatomic, nullable) AVFilterGraph *graph;
@property (assign, nonatomic, nullable) AVFilterGraph *next;

@end

@implementation AudioEqualizer

- (instancetype _Nonnull)initWithValues:(NSArray<AudioEqualizerValue *> * _Nonnull)values {
    self = [super init];
    if (self) {
        _values = values;
        _preamp = -6.0f;
    }
    [self deleteDumpFile:@"dump1.raw"];
    [self deleteDumpFile:@"dump2.raw"];
    [self deleteDumpFile:@"dump3.raw"];
    return self;
}

- (void)setPreamp:(float)preamp {
    _preamp = preamp;
}

- (AVFilterGraph *)drawFilter {
    AVFilterGraph *graph = avfilter_graph_alloc();
    if (!graph || !_metadata) {
        return NULL;
    }

    AVFilterContext *abuffer = NULL;
    AVFilterContext *aformat_in = NULL;
    AVFilterContext *aformat_out = NULL;
    AVFilterContext *abuffersink = NULL;
    AVFilterContext *equalizer_first = NULL;
    AVFilterContext *equalizer_last = NULL;

    
    char ch_layout_str[64];
    char option_str[32];
    int i;
    int ret = 0;
    NSUInteger nb_bands = _values.count;

    /* Set audio buffer source */
    abuffer = avfilter_graph_alloc_filter(graph, avfilter_get_by_name("abuffer"), "in");
    if (!abuffer) {
        NSLog(@"Error!! : 'abuffer' filter could not be allocated.");
        return NULL;
    }

    enum AVSampleFormat sample_fmt = AV_SAMPLE_FMT_NONE;
    switch (_metadata.bitdepth) {
        case 16 : sample_fmt = AV_SAMPLE_FMT_S16;
        case 24 : sample_fmt = AV_SAMPLE_FMT_S32;
        case 32 : sample_fmt = AV_SAMPLE_FMT_S32;
    }

    AVChannelLayout ch_layout;
    av_channel_layout_default(&ch_layout, (int)_metadata.channels);
    av_channel_layout_describe(&ch_layout, ch_layout_str, sizeof(ch_layout_str));
    
    av_opt_set(abuffer, "channel_layout", ch_layout_str, AV_OPT_SEARCH_CHILDREN);
    av_opt_set(abuffer, "sample_fmt", av_get_sample_fmt_name(sample_fmt), AV_OPT_SEARCH_CHILDREN);
    av_opt_set_q(abuffer, "time_base", (AVRational){ 1, (int)_metadata.samplerate }, AV_OPT_SEARCH_CHILDREN);
    av_opt_set_int(abuffer, "sample_rate", _metadata.samplerate, AV_OPT_SEARCH_CHILDREN);
        
    ret = avfilter_init_str(abuffer, NULL);
    if (ret < 0) {
        char errbuf[128];
        av_strerror(ret, errbuf, sizeof(errbuf));
        NSLog(@"Could not initialize the abuffer filter. / %s", errbuf);
        return NULL;
    }
    
    aformat_in = avfilter_graph_alloc_filter(graph, avfilter_get_by_name("aformat"), "aformat_in");
    if (!aformat_in) {
        NSLog(@"Error!! : 'aformat' filter could not be allocated.");
        return NULL;
    }
    av_opt_set(aformat_in, "channel_layouts", ch_layout_str, AV_OPT_SEARCH_CHILDREN);
    av_opt_set(aformat_in, "sample_fmts", av_get_sample_fmt_name(AV_SAMPLE_FMT_S32P), AV_OPT_SEARCH_CHILDREN);

    ret = avfilter_init_str(aformat_in, NULL);
    if (ret < 0) {
        char errbuf[128];
        av_strerror(ret, errbuf, sizeof(errbuf));
        NSLog(@"Could not initialize the aformat filter. / %s", errbuf);
        return NULL;
    }

    /* Set volume  */
//    volume = avfilter_graph_alloc_filter(graph, avfilter_get_by_name("volume"), "volume");
//    if (!volume) {
//        NSLog(@"Error!! : 'volume' filter could not be allocated.");
//        return NULL;
//    }

//    snprintf(option_str, sizeof(option_str), "%fdB", _preamp);
//    NSLog(@"%s", option_str);
//    av_opt_set(volume, "volume", "0.9", AV_OPT_SEARCH_CHILDREN);

//    ret = avfilter_init_str(volume, NULL);
//    if (ret < 0) {
//        char errbuf[128];
//        av_strerror(ret, errbuf, sizeof(errbuf));
//        NSLog(@"Could not initialize the volume filter. / %s", errbuf);
//        return NULL;
//    }
    
    aformat_out = avfilter_graph_alloc_filter(graph, avfilter_get_by_name("aformat"), "aformat_out");
    if (!aformat_out) {
        NSLog(@"Error!! : 'aformat' filter could not be allocated.");
        return NULL;
    }
    
    av_opt_set(aformat_out, "channel_layouts", ch_layout_str, AV_OPT_SEARCH_CHILDREN);
    av_opt_set(aformat_out, "sample_fmts", av_get_sample_fmt_name(sample_fmt), AV_OPT_SEARCH_CHILDREN);
    
    ret = avfilter_init_str(aformat_out, NULL);
    if (ret < 0) {
        char errbuf[128];
        av_strerror(ret, errbuf, sizeof(errbuf));
        NSLog(@"Could not initialize the aformat filter. / %s", errbuf);
        return NULL;
    }
    
    /* Set equalizer */
    for (i=0; i<nb_bands; i++) {
        char name[64];
        snprintf(name, sizeof(name), "equalizer%d", i);

        AVFilterContext *equalizer = avfilter_graph_alloc_filter(graph, avfilter_get_by_name("equalizer"), name);
        if (!equalizer) {
            NSLog(@"Error!! : 'equalizer' filter could not be allocated.");
            return NULL;
        }
        
        av_opt_set_double(equalizer, "frequency", _values[i].band.doubleValue, AV_OPT_SEARCH_CHILDREN);
        av_opt_set(equalizer, "width_type", "q", AV_OPT_SEARCH_CHILDREN);
        av_opt_set_double(equalizer, "width", _values[i].q.doubleValue, AV_OPT_SEARCH_CHILDREN);
        av_opt_set_double(equalizer, "gain", _values[i].gain/100.0f, AV_OPT_SEARCH_CHILDREN);

        ret = avfilter_init_str(equalizer, NULL);
        if (ret < 0) {
            char errbuf[128];
            av_strerror(ret, errbuf, sizeof(errbuf));
            NSLog(@"Could not initialize the equalizer filter. / %s", errbuf);
            return NULL;
        }

        if (i == 0) {
            equalizer_first = equalizer;
        } else {
            avfilter_link(equalizer_last, 0, equalizer, 0);
        }
        equalizer_last = equalizer;
    }

    /* Set audio buffer sink */
    abuffersink = avfilter_graph_alloc_filter(graph, avfilter_get_by_name("abuffersink"), "out");
    if (abuffersink == NULL) {
        NSLog(@"Error!! : 'equalizer' filter could not be allocated.");
        return NULL;
    }
    
    ret = avfilter_init_str(abuffersink, NULL);
    if (ret < 0) {
        char errbuf[128];
        av_strerror(ret, errbuf, sizeof(errbuf));
        NSLog(@"Could not initialize the abuffersink filter. / %s", errbuf);
        return NULL;
    }
    
    /* Connect the filters;
     * in this simple case the filters just form a linear chain. */
    avfilter_link(abuffer, 0, aformat_in, 0);
    avfilter_link(aformat_in, 0, equalizer_first, 0);
    avfilter_link(equalizer_last, 0, aformat_out, 0);
    avfilter_link(aformat_out, 0, abuffersink, 0);

    
    
    /* Configure the graph. */
    ret = avfilter_graph_config(graph, NULL);
    if (ret < 0) {
        char errbuf[128];
        av_strerror(ret, errbuf, sizeof(errbuf));
        NSLog(@"Error occurred while configuring the filter graph. / %s", errbuf);
        return NULL;
    }
    
    char *filter_graph_desc = avfilter_graph_dump(graph, NULL);
    NSLog(@"Filter Graph:\n%s", filter_graph_desc);
    av_free(filter_graph_desc);
    
    return graph;
}

void memcpy_24_to_32(int32_t *dst, const int32_t *src, size_t c) {
    while (c--) {
        *dst++ = *src++ >> 8;
    }
}

void memcpy_32_to_24(int32_t *dst, const int32_t *src, size_t c) {
    while (c--) {
        *dst++ = *src++ << 8;
    }
}

- (void)deleteDumpFile:(NSString *)name {
    // 1. NSFileManager 인스턴스를 생성
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 2. "dump.raw" 파일 경로 가져오기
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentDirectory stringByAppendingPathComponent:name];
    NSLog(@"FILE PATH: %@", filePath);

    // 3. 파일이 존재하는지 확인
    if ([fileManager fileExistsAtPath:filePath]) {
        // 4. 파일 삭제
        NSError *error = nil;
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        
        if (success) {
            NSLog(@"파일 삭제 성공");
        } else {
            NSLog(@"파일 삭제 실패: %@", error.localizedDescription);
        }
    } else {
        NSLog(@"파일이 존재하지 않습니다.");
    }
}

- (void)appendDataToDumpFile:(void *)data length:(int)length name:(NSString *)name {
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentDirectory stringByAppendingPathComponent:name];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    
    if (!fileHandle) {
        // 파일이 없으면 새로 생성
        [[NSData dataWithBytes:data length:length] writeToFile:filePath atomically:YES];
    } else {
        // 파일 끝으로 이동한 후 데이터 추가
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[NSData dataWithBytes:data length:length]];
        [fileHandle closeFile];
    }
}

- (int)filter:(void *)data length:(size_t)length {
    if (!_metadata) {
        return -1;
    }
    void *samples;
    int buffer_size;
    int nb_samples;
    int ret;

    NSUInteger channels = _metadata.channels;
    if (channels == 0) {
        AVChannelLayout layout = AV_CHANNEL_LAYOUT_STEREO;
        channels = layout.nb_channels;
    }
    AVFrame *src = NULL;
    AVFrame *sink = NULL;
    
    if (!data) {
        return -1;
    }
    
    src = av_frame_alloc();
    sink = av_frame_alloc();
    
    if (_metadata.bitdepth == 16) {
        nb_samples = (int)(length / sizeof(int16_t));
    } else {
        nb_samples = (int)(length / sizeof(int32_t));
    }

    enum AVSampleFormat sample_fmt = AV_SAMPLE_FMT_NONE;
    switch (_metadata.bitdepth) {
        case 16 : sample_fmt = AV_SAMPLE_FMT_S16;
        case 24 : sample_fmt = AV_SAMPLE_FMT_S32;
        case 32 : sample_fmt = AV_SAMPLE_FMT_S32;
    }
    
    src->nb_samples     = nb_samples / channels;
    src->format         = sample_fmt;
    av_channel_layout_default(&src->ch_layout, (int)_metadata.channels);
    src->sample_rate    = (int)_metadata.samplerate;
    
    av_frame_get_buffer(src, 0);
    av_frame_make_writable(src);
    
    buffer_size = nb_samples;
    buffer_size = av_samples_get_buffer_size(NULL, 2, src->nb_samples, src->format, 1);
    
    if (buffer_size < 0) {
        return -1;
    }
    samples = av_malloc(buffer_size);

    if (_metadata.bitdepth == 24) {
        memcpy_24_to_32(samples, data, nb_samples);
    } else {
        memcpy(samples, data, buffer_size);
    }
    memcpy(src->extended_data[0], samples, buffer_size);
    [self appendDataToDumpFile:src->extended_data[0] length: buffer_size name:@"dump1.raw"];

    av_free(samples);
    
    @synchronized (self) {
        ret = [self doFilterWithGraph:_graph src:src sink:sink];
        if (ret < 0) {
            av_frame_unref(src);
            av_frame_free(&src);
            av_frame_unref(sink);
            av_frame_free(&sink);
            return 0;
        }
        
        void *origin = calloc(1, buffer_size);
        memcpy(origin, data, buffer_size);
        
        if (_metadata.bitdepth == 24) {
            memcpy_24_to_32(data, (int32_t *)sink->extended_data[0], nb_samples);
        } else {
            memcpy(data, sink->extended_data[0], buffer_size);
        }
        [self appendDataToDumpFile:sink->extended_data[0] length: buffer_size name:@"dump2.raw"];
//        if (_metadata.bitdepth == 16) {
//            eq_frame_mix_by_ratio_int_16((int16_t *)origin, (int16_t *)data, nb_samples, 2);
//        } else {
//            eq_frame_mix_by_ratio_int_32((int32_t *)origin, (int32_t *)data, nb_samples, 2);
//        }

//
//        for (int i = 0; i < nb_samples; i += channels) {
//            double r = (double)i / (nb_samples-1);
//            for (int j = 0; j < channels; j++) {
//                if (_metadata.bitdepth == 16) {
//                    *(int16_t *)(data+i+j) = (1-r)*(*(int16_t *)(origin+i+j)) + r*(*(int16_t *)(data+i+j));
//                } else {
//                    *(int32_t *)(data+i+j) = (1-r)*(*(int32_t *)(origin+i+j)) + r*(*(int32_t *)(data+i+j));
//                }
//            }
//        }
//        [self appendDataToDumpFile:sink->extended_data[0] length: buffer_size name:@"dump2.raw"];
//
        av_free(origin);
        av_frame_unref(sink);
        av_frame_free(&sink);
    
//        if (_next) {
//            sink = av_frame_alloc();
//            ret = [self doFilterWithGraph:_next src:src sink:sink];
//            if (ret >= 0) {
//                avfilter_graph_free(&_graph);
//                _graph = _next;
//                _next = NULL;
                
//                void *next = calloc(1, buffer_size);
//                if (_metadata.bitdepth == 24) {
//                    memcpy_24_to_32(next, (int32_t *)sink->extended_data[0], nb_samples);
//                } else {
//                    memcpy(next, sink->extended_data[0], buffer_size);
//                }
//                
//                for (int i = 0; i < nb_samples; i += channels) {
//                    double r = (double)i / (nb_samples-1);
//                    for (int j = 0; j < channels; j++) {
//                        if (_metadata.bitdepth == 16) {
//                            *(int16_t *)(data+i+j) = (1-r)*(*(int16_t *)(data+i+j)) + r*(*(int16_t *)(next+i+j));
//                       
//                        } else {
//                            *(int32_t *)(data+i+j) = (1-r)*(*(int32_t *)(data+i+j)) + r*(*(int32_t *)(next+i+j));
//                        }
//                    }
//                }
//                free(next);
//                av_frame_unref(sink);
//                av_frame_free(&sink);
//            }
//        }
        av_frame_unref(src);
        av_frame_free(&src);
    }
    return 0;
}

- (int)doFilterWithGraph:(AVFilterGraph *)graph src:(AVFrame *)src sink:(AVFrame *)sink {
    if (!graph) {
        return -1;
    }

    int ret;
    AVFilterContext *abuffer = avfilter_graph_get_filter(_graph, "in");
    ret = av_buffersrc_add_frame_flags(abuffer, src, AV_BUFFERSRC_FLAG_KEEP_REF);
    if (ret < 0) {
        char errbuf[128];
        av_strerror(ret, errbuf, sizeof(errbuf));
        NSLog(@"Error while feeding the audio filtergraph. / %s", errbuf);
        return ret;
    }
    
    /* pull filtered audio from the filtergraph */
    AVFilterContext *abuffersink = avfilter_graph_get_filter(_graph, "out");
    ret = av_buffersink_get_frame(abuffersink, sink);
    if (ret < 0) {
        char errbuf[128];
        av_strerror(ret, errbuf, sizeof(errbuf));
        NSLog(@"Error while draining the audio filtergraph. / %s", errbuf);
        return ret;
    }
    return 0;
}

- (int)changeFilter {
    AVFilterGraph *graph = [self drawFilter];
    if (!graph) {
        return -1;
    }
    @synchronized (self) {
//        if (!_graph) {
            _graph = graph;

//        } else {
//            avfilter_graph_free(&_next);
//            _next = graph;
//        }
    }
    return 0;
}

- (void)dealloc {
    if (self.graph) {
        avfilter_graph_free(&_graph);
    }
    if (self.next) {
        avfilter_graph_free(&_next);
    }
}

void eq_frame_mix_by_ratio_int_16(int16_t *pSample1, int16_t *pSample2, int nb_samples, int ch) {
    double r = 0.0f;
    int i, j;
    for (i = 0; i < nb_samples; i += ch) {
        r = (double)i / (nb_samples-1);
        for (j = 0; j < ch; j++) {
            *(pSample1+i+j) = (1-r)*(*(pSample1+i+j)) + r*(*(pSample2+i+j));
        }
    }
}

void eq_frame_mix_by_ratio_int_32(int32_t *pSample1, int32_t *pSample2, int nb_samples, int ch) {
    double r = 0.0f;
    int i, j;
    for (i = 0; i < nb_samples; i += ch) {
        r = (double)i / (nb_samples-1);
        for (j = 0; j < ch; j++) {
            *(pSample1+i+j) = (1-r)*(*(pSample1+i+j)) + r*(*(pSample2+i+j));
        }
    }
}


@end
