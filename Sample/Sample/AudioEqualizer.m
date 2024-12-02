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
        _preamp = 0.0f;
    }
    return self;
}

- (void)setPreamp:(float)preamp {
    _preamp = preamp;
}

- (void)setMetadata:(AudioMetadata *)metadata {
    _metadata = metadata;
    _graph = [self drawFilter];
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
    AVFilterContext *volume = NULL;
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
    
    enum AVSampleFormat sample_fmt = av_get_sample_fmt([_metadata.sampleformat cStringUsingEncoding: NSASCIIStringEncoding]);
    switch (sample_fmt) {
        case AV_SAMPLE_FMT_U8P : sample_fmt = AV_SAMPLE_FMT_U8;
        case AV_SAMPLE_FMT_S16P : sample_fmt = AV_SAMPLE_FMT_S16;
        case AV_SAMPLE_FMT_S32P : sample_fmt = AV_SAMPLE_FMT_S32;
        case AV_SAMPLE_FMT_FLTP : sample_fmt = AV_SAMPLE_FMT_FLT;
        case AV_SAMPLE_FMT_DBLP : sample_fmt = AV_SAMPLE_FMT_FLT;
        default: break;
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
    av_opt_set(aformat_in, "sample_fmts", av_get_sample_fmt_name(AV_SAMPLE_FMT_DBLP), AV_OPT_SEARCH_CHILDREN);

    ret = avfilter_init_str(aformat_in, NULL);
    if (ret < 0) {
        char errbuf[128];
        av_strerror(ret, errbuf, sizeof(errbuf));
        NSLog(@"Could not initialize the aformat filter. / %s", errbuf);
        return NULL;
    }
    
    aformat_out = avfilter_graph_alloc_filter(graph, avfilter_get_by_name("aformat"), "aformat_out");
    if (!aformat_out) {
        NSLog(@"Error!! : 'aformat' filter could not be allocated.");
        return NULL;
    }
    
    av_opt_set(aformat_out, "channel_layouts", ch_layout_str, AV_OPT_SEARCH_CHILDREN);
    av_opt_set(aformat_out, "sample_fmts", av_get_sample_fmt_name(sample_fmt), AV_OPT_SEARCH_CHILDREN);
    
    NSLog(@"%s", av_get_sample_fmt_name(sample_fmt));
    
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
        
        av_opt_set_double(equalizer, "frequency", _values[i].band, AV_OPT_SEARCH_CHILDREN);
        av_opt_set(equalizer, "width_type", "q", AV_OPT_SEARCH_CHILDREN);
        av_opt_set_double(equalizer, "width", _values[i].q, AV_OPT_SEARCH_CHILDREN);
        av_opt_set_int(equalizer, "gain", (int)_values[i].gain, AV_OPT_SEARCH_CHILDREN);

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
    
    /* Set volume  */
    volume = avfilter_graph_alloc_filter(graph, avfilter_get_by_name("volume"), "volume");
    if (!volume) {
        NSLog(@"Error!! : 'volume' filter could not be allocated.");
        return NULL;
    }
    
    snprintf(option_str, sizeof(option_str), "%fdB", _preamp);
    av_opt_set(volume, "volume", option_str, AV_OPT_SEARCH_CHILDREN);

    ret = avfilter_init_str(volume, NULL);
    if (ret < 0) {
        char errbuf[128];
        av_strerror(ret, errbuf, sizeof(errbuf));
        NSLog(@"Could not initialize the volume filter. / %s", errbuf);
        return NULL;
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
    avfilter_link(aformat_in, 0, volume, 0);
    avfilter_link(volume, 0, equalizer_first, 0);
    avfilter_link(equalizer_first, 0, equalizer_last, 0);
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
    if (!_on) {
        return -1;
    }

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

    enum AVSampleFormat sample_fmt = av_get_sample_fmt([_metadata.sampleformat cStringUsingEncoding: NSASCIIStringEncoding]);
    switch (sample_fmt) {
        case AV_SAMPLE_FMT_U8P : sample_fmt = AV_SAMPLE_FMT_U8;
        case AV_SAMPLE_FMT_S16P : sample_fmt = AV_SAMPLE_FMT_S16;
        case AV_SAMPLE_FMT_S32P : sample_fmt = AV_SAMPLE_FMT_S32;
        case AV_SAMPLE_FMT_FLTP : sample_fmt = AV_SAMPLE_FMT_FLT;
        case AV_SAMPLE_FMT_DBLP : sample_fmt = AV_SAMPLE_FMT_FLT;
        default: break;
    }

    src->nb_samples     = nb_samples / channels;
    src->format         = sample_fmt;
    av_channel_layout_default(&src->ch_layout, (int)_metadata.channels);
    src->sample_rate    = (int)_metadata.samplerate;
    
    av_frame_get_buffer(src, 0);
    av_frame_make_writable(src);
    
    buffer_size = nb_samples;
    buffer_size = av_samples_get_buffer_size(NULL, (int)_metadata.channels, src->nb_samples, src->format, 1);
    
    if (buffer_size < 0) {
        return -1;
    }
    
    samples = av_malloc(buffer_size);
    if (_metadata.bitdepth == 24) {
        memcpy_24_to_32(samples, data, nb_samples);
    } else {
        memcpy(samples, data, buffer_size);
    }
    memcpy(src->data[0], samples, buffer_size);
    
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

        if (_metadata.bitdepth == 24) {
            memcpy_24_to_32(data, (int32_t *)sink->data[0], nb_samples);
        } else {
            memcpy(data, sink->data[0], buffer_size);
        }

        av_frame_unref(sink);
        av_frame_free(&sink);
            
        @synchronized (self) {
            if (_next) {
                sink = av_frame_alloc();
                ret = [self doFilterWithGraph:_next src:src sink:sink];
                if (ret >= 0) {
                    avfilter_graph_free(&_graph);
                    _graph = _next;
                    _next = NULL;
                }
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
    AVFilterContext *abuffer = avfilter_graph_get_filter(graph, "in");
    ret = av_buffersrc_add_frame_flags(abuffer, src, AV_BUFFERSRC_FLAG_KEEP_REF);
    if (ret < 0) {
        char errbuf[128];
        av_strerror(ret, errbuf, sizeof(errbuf));
        NSLog(@"Error while feeding the audio filtergraph. / %s", errbuf);
        return ret;
    }
    
    /* pull filtered audio from the filtergraph */
    AVFilterContext *abuffersink = avfilter_graph_get_filter(graph, "out");
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
        avfilter_graph_free(&_next);
        _next = graph;
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
