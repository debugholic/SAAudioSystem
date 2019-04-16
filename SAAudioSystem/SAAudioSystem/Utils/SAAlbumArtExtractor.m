//
//  AlbumArtExtractor.m
//  SAAudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import "SAAlbumArtExtractor.h"
#import <libavformat/avformat.h>

@implementation SAAlbumArtExtractor

+ (UIImage *)albumArtWithFormatContext:(AVFormatContext *)formatContext {
    if (!formatContext) {
        return nil;
    }

    UIImage *albumArt = nil;
    int ret = formatContext->iformat->read_header(formatContext);
    if (ret < 0) {
        return nil;
    }

    for (int i = 0; i < formatContext->nb_streams; i++) {
        if (formatContext->streams[i]->disposition & AV_DISPOSITION_ATTACHED_PIC) {
            AVPacket packet = formatContext->streams[i]->attached_pic;
            NSData *imageData = [NSData dataWithBytes:packet.data length:packet.size];
            albumArt = [UIImage imageWithData:imageData];
            break;
        }
    }
    return albumArt;
}

@end
