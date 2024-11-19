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
        _preamp = @(0.10);
    }
    return self;
}

- (void)setPreamp:(NSNumber *)preamp {
    _preamp = preamp;
}

- (AVFilterGraph *)drawFilter2 {
    int ret = 0;
    const AVFilter *abuffersrc  = avfilter_get_by_name("abuffer");
    const AVFilter *abuffersink = avfilter_get_by_name("abuffersink");
    AVFilterInOut *outputs = avfilter_inout_alloc();
    AVFilterInOut *inputs  = avfilter_inout_alloc();
    static const int out_sample_rate = 8000;
    const AVFilterLink *outlink;
    AVRational time_base = (AVRational){ 1, (int)_metadata.samplerate };
    AVFilterContext *buffersink_ctx;
    AVFilterContext *buffersrc_ctx;
    char ch_layout_str[64];

    AVFilterGraph *graph = avfilter_graph_alloc();
    if (!graph || !_metadata) {
        return NULL;
    }

    buffersrc_ctx = avfilter_graph_alloc_filter(graph, abuffersrc, "in");
    if (!buffersrc_ctx) {
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
    
    av_opt_set(buffersrc_ctx, "channel_layout", ch_layout_str, AV_OPT_SEARCH_CHILDREN);
    av_opt_set(buffersrc_ctx, "sample_fmt", av_get_sample_fmt_name(sample_fmt), AV_OPT_SEARCH_CHILDREN);
    av_opt_set_q(buffersrc_ctx, "time_base", (AVRational){ 1, (int)_metadata.samplerate }, AV_OPT_SEARCH_CHILDREN);
    av_opt_set_int(buffersrc_ctx, "sample_rate", _metadata.samplerate, AV_OPT_SEARCH_CHILDREN);
    
    ret = avfilter_init_str(buffersrc_ctx, NULL);
    if (ret < 0) {
        char errbuf[128];
        av_strerror(ret, errbuf, sizeof(errbuf));
        NSLog(@"Could not initialize the abuffer filter. / %s", errbuf);
        return NULL;
    }
    
    /* buffer audio sink: to terminate the filter chain. */
    buffersink_ctx = avfilter_graph_alloc_filter(graph, abuffersink, "out");
    if (!buffersink_ctx) {
        char errbuf[128];
        av_strerror(ret, errbuf, sizeof(errbuf));
        NSLog(@"Cannot create audio buffer sink. / %s", errbuf);
        return NULL;
    }
    
//    ret = av_opt_set(buffersink_ctx, "sample_formats", "s16", AV_OPT_SEARCH_CHILDREN);
//    if (ret < 0) {
//        char errbuf[128];
//        av_strerror(ret, errbuf, sizeof(errbuf));
//        NSLog(@"Cannot set output sample format. / %s", errbuf);
//        return NULL;
//    }
//    
//    ret = av_opt_set(buffersink_ctx, "channel_layouts", "mono", AV_OPT_SEARCH_CHILDREN);
//    if (ret < 0) {
//        char errbuf[128];
//        av_strerror(ret, errbuf, sizeof(errbuf));
//        NSLog(@"Cannot set output channel layout. / %s", errbuf);
//        return NULL;
//    }
//
//    char option_str[32];
//    snprintf(option_str, sizeof(option_str), "%d", out_sample_rate);
    
//    ret = av_opt_set(buffersink_ctx, "samplerates", option_str, AV_OPT_SEARCH_CHILDREN);
//    if (ret < 0) {
//        char errbuf[128];
//        av_strerror(ret, errbuf, sizeof(errbuf));
//        NSLog(@"Cannot set output sample rate. / %s", errbuf);
//        return NULL;
//    }
 
    ret = avfilter_init_dict(buffersink_ctx, NULL);
    if (ret < 0) {
        char errbuf[128];
        av_strerror(ret, errbuf, sizeof(errbuf));
        NSLog(@"Cannot initialize audio buffer sink. / %s", errbuf);
        return NULL;
    }
 
    outputs->name       = av_strdup("in");
    outputs->filter_ctx = buffersrc_ctx;
    outputs->pad_idx    = 0;
    outputs->next       = NULL;
 
    /*
     * The buffer sink input must be connected to the output pad of
     * the last filter described by filters_descr; since the last
     * filter output label is not specified, it is set to "out" by
     * default.
     */
    inputs->name       = av_strdup("out");
    inputs->filter_ctx = buffersink_ctx;
    inputs->pad_idx    = 0;
    inputs->next       = NULL;
 
    char *filters_descr = "aresample=44100,aformat=sample_fmts=s32:channel_layouts=stereo";
    if ((ret = avfilter_graph_parse_ptr(graph, filters_descr,
                                        &inputs, &outputs, NULL)) < 0)
        return NULL;
 
    if ((ret = avfilter_graph_config(graph, NULL)) < 0)
        return NULL;
 
    /* Print summary of the sink buffer
     * Note: args buffer is reused to store channel layout string */
    outlink = buffersink_ctx->inputs[0];
    
////    /* Set equalizer */
//    for (i = 0; i < nb_bands; i++) {
//        char name[64];
//        snprintf(name, sizeof(name), "equalizer%d", i);
//
//        AVFilterContext *equalizer = avfilter_graph_alloc_filter(graph, avfilter_get_by_name("equalizer"), name);
//        if (!equalizer) {
//            NSLog(@"Error!! : 'equalizer' filter could not be allocated.");
//            return NULL;
//        }
//        
//        NSLog(@"%lf, %lf", _values[i].band.doubleValue, _values[i].q.doubleValue);
//
//        av_opt_set_double(equalizer, "frequency", _values[i].band.doubleValue, AV_OPT_SEARCH_CHILDREN);
//        av_opt_set(equalizer, "width_type", "q", AV_OPT_SEARCH_CHILDREN);
//        av_opt_set_double(equalizer, "width", _values[i].q.doubleValue, AV_OPT_SEARCH_CHILDREN);
//        av_opt_set_double(equalizer, "gain", _values[i].gain, AV_OPT_SEARCH_CHILDREN);
//        
//        snprintf(option_str, sizeof(option_str), "%d", (int)_metadata.channels);
//        av_opt_set(equalizer, "channels", option_str, AV_OPT_SEARCH_CHILDREN);
//    
//        ret = avfilter_init_str(equalizer, NULL);
//        if (ret < 0) {
//            char errbuf[128];
//            av_strerror(ret, errbuf, sizeof(errbuf));
//            NSLog(@"Could not initialize the equalizer filter. / %s", errbuf);
//            return NULL;
//        }
//
//        if (i == 0) {
//            equalizer_first = equalizer;
//        } else {
//            avfilter_link(equalizer_last, 0, equalizer, 0);
//        }
//        equalizer_last = equalizer;
//    }
//
//    /* Set audio buffer sink */
//    abuffersink = avfilter_graph_alloc_filter(graph, avfilter_get_by_name("abuffersink"), "out");
//    if (abuffersink == NULL) {
//        NSLog(@"Error!! : 'equalizer' filter could not be allocated.");
//        return NULL;
//    }
//    
//    ret = avfilter_init_str(abuffersink, NULL);
//    if (ret < 0) {
//        char errbuf[128];
//        av_strerror(ret, errbuf, sizeof(errbuf));
//        NSLog(@"Could not initialize the abuffersink filter. / %s", errbuf);
//        return NULL;
//    }
//    
//    /* Connect the filters;
//     * in this simple case the filters just form a linear chain. */
//    avfilter_link(abuffer, 0, volume, 0);
//    avfilter_link(volume, 0, equalizer_first, 0);
//    avfilter_link(equalizer_last, 0, aformat, 0);
//    avfilter_link(aformat, 0, abuffersink, 0);
//
//    /* Configure the graph. */
//    ret = avfilter_graph_config(graph, NULL);
//    if (ret < 0) {
//        char errbuf[128];
//        av_strerror(ret, errbuf, sizeof(errbuf));
//        NSLog(@"Error occurred while configuring the filter graph. / %s", errbuf);
//        return NULL;
//    }
    return graph;
}




- (AVFilterGraph *)drawFilter {
    AVFilterGraph *graph = avfilter_graph_alloc();
    if (!graph || !_metadata) {
        return NULL;
    }

    AVFilterContext *abuffer = NULL;
    AVFilterContext *volume = NULL;
    AVFilterContext *aformat = NULL;
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
    
    /* Set volume  */
//    volume = avfilter_graph_alloc_filter(graph, avfilter_get_by_name("volume"), "volume");
//    if (!volume) {
//        NSLog(@"Error!! : 'volume' filter could not be allocated.");
//        return NULL;
//    }
//    
//    snprintf(option_str, sizeof(option_str), "%f", _preamp.doubleValue);
//    av_opt_set(volume, "volume", option_str, AV_OPT_SEARCH_CHILDREN);
//
//    ret = avfilter_init_str(volume, NULL);
//    if (ret < 0) {
//        char errbuf[128];
//        av_strerror(ret, errbuf, sizeof(errbuf));
//        NSLog(@"Could not initialize the volume filter. / %s", errbuf);
//        return NULL;
//    }
//
    aformat = avfilter_graph_alloc_filter(graph, avfilter_get_by_name("aformat"), "aformat");
    if (!aformat) {
        NSLog(@"Error!! : 'aformat' filter could not be allocated.");
        return NULL;
    }
    
    av_opt_set(aformat, "channel_layouts", ch_layout_str, AV_OPT_SEARCH_CHILDREN);
    av_opt_set(aformat, "sample_fmts", av_get_sample_fmt_name(sample_fmt), AV_OPT_SEARCH_CHILDREN);
    
    snprintf(option_str, sizeof(option_str), "%d", (int)_metadata.samplerate);
    av_opt_set(aformat, "sample_rates", option_str, AV_OPT_SEARCH_CHILDREN);

    ret = avfilter_init_str(aformat, NULL);
    if (ret < 0) {
        char errbuf[128];
        av_strerror(ret, errbuf, sizeof(errbuf));
        NSLog(@"Could not initialize the aformat filter. / %s", errbuf);
        return NULL;
    }
    
    /* Set equalizer */
    for (i = 0; i < nb_bands; i++) {
        char name[64];
        snprintf(name, sizeof(name), "equalizer%d", i);

        AVFilterContext *equalizer = avfilter_graph_alloc_filter(graph, avfilter_get_by_name("equalizer"), name);
        if (!equalizer) {
            NSLog(@"Error!! : 'equalizer' filter could not be allocated.");
            return NULL;
        }
        
        NSLog(@"%lf, %lf", _values[i].band.doubleValue, _values[i].q.doubleValue);

        av_opt_set_double(equalizer, "frequency", _values[i].band.doubleValue, AV_OPT_SEARCH_CHILDREN);
        av_opt_set(equalizer, "width_type", "q", AV_OPT_SEARCH_CHILDREN);
        av_opt_set_double(equalizer, "width", _values[i].q.doubleValue, AV_OPT_SEARCH_CHILDREN);
        av_opt_set_double(equalizer, "gain", _values[i].gain, AV_OPT_SEARCH_CHILDREN);
        
        snprintf(option_str, sizeof(option_str), "%d", (int)_metadata.channels);
        av_opt_set(equalizer, "channels", option_str, AV_OPT_SEARCH_CHILDREN);
    
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
//    avfilter_link(abuffer, 0, volume, 0);
    avfilter_link(abuffer, 0, equalizer_first, 0);
    avfilter_link(equalizer_last, 0, aformat, 0);
//    avfilter_link(abuffer, 0, aformat, 0);
    avfilter_link(aformat, 0, abuffersink, 0);

    /* Configure the graph. */
    ret = avfilter_graph_config(graph, NULL);
    if (ret < 0) {
        char errbuf[128];
        av_strerror(ret, errbuf, sizeof(errbuf));
        NSLog(@"Error occurred while configuring the filter graph. / %s", errbuf);
        return NULL;
    }
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
                
        for (int i = 0; i < nb_samples; i += channels) {
            double r = (double)i / (nb_samples-1);
            for (int j = 0; j < channels; j++) {
                if (_metadata.bitdepth == 16) {
                    *(int16_t *)(data+i+j) = (1-r)*(*(int16_t *)(origin+i+j)) + r*(*(int16_t *)(data+i+j));
                } else {
                    *(int32_t *)(data+i+j) = (1-r)*(*(int32_t *)(origin+i+j)) + r*(*(int32_t *)(data+i+j));
                }
            }
        }
        av_free(origin);
        av_frame_unref(sink);
        av_frame_free(&sink);
    
        if (_next) {
            sink = av_frame_alloc();
            ret = [self doFilterWithGraph:_next src:src sink:sink];
            if (ret >= 0) {
                avfilter_graph_free(&_graph);
                _graph = _next;
                _next = NULL;
                
                void *next = calloc(1, buffer_size);
                if (_metadata.bitdepth == 24) {
                    memcpy_24_to_32(next, (int32_t *)sink->extended_data[0], nb_samples);
                } else {
                    memcpy(next, sink->extended_data[0], buffer_size);
                }
                
                for (int i = 0; i < nb_samples; i += channels) {
                    double r = (double)i / (nb_samples-1);
                    for (int j = 0; j < channels; j++) {
                        if (_metadata.bitdepth == 16) {
                            *(int16_t *)(data+i+j) = (1-r)*(*(int16_t *)(data+i+j)) + r*(*(int16_t *)(next+i+j));
                        } else {
                            *(int32_t *)(data+i+j) = (1-r)*(*(int32_t *)(data+i+j)) + r*(*(int32_t *)(next+i+j));
                        }
                    }
                }
                free(next);
                av_frame_unref(sink);
                av_frame_free(&sink);
            }
        }
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
        if (!_graph) {
            _graph = graph;

        } else {
            avfilter_graph_free(&_next);
            _next = graph;
        }
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

@end
