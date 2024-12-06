//
//  AlbumArtExtractor.h
//  FFmpegAudioPlayer
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <UIKit/UIImage.h>
#import <libavformat/avformat.h>

@interface AlbumArtExtractor : NSObject

+ (UIImage * _Nullable)albumArtWithPath:(NSString * _Nullable)path;
+ (UIImage * _Nullable)albumArtWithFormatContext:(AVFormatContext * _Nullable)fmt_ctx;

@end
