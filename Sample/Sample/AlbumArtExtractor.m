//
//  AlbumArtExtractor.m
//  FFmpegAudioPlayer
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import "AlbumArtExtractor.h"
#import <libavformat/avformat.h>

@implementation AlbumArtExtractor

+ (UIImage *)albumArtWithFormatContext:(AVFormatContext *)fmt_ctx {
    if (!fmt_ctx) {
        return nil;
    }

    UIImage *albumArt = nil;
    int ret = fmt_ctx->iformat->read_header(fmt_ctx);
    if (ret < 0) {
        return nil;
    }

    for (int i = 0; i < fmt_ctx->nb_streams; i++) {
        if (fmt_ctx->streams[i]->disposition & AV_DISPOSITION_ATTACHED_PIC) {
            AVPacket packet = fmt_ctx->streams[i]->attached_pic;
            NSData *imageData = [NSData dataWithBytes:packet.data length:packet.size];
            albumArt = [UIImage imageWithData:imageData];
            break;
        }
    }
    return albumArt;
}

@end
