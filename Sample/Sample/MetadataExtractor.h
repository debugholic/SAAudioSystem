//
//  MetadataExtractor.h
//  FFmpegAudioPlayer
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <UIKit/UIDevice.h>
#import <libavformat/avformat.h>
#import "AudioMetadata.h"

@interface MetadataExtractor : NSObject

+ (AudioMetadata * _Nullable)metadataWithPath:(NSString * _Nullable)path;
+ (AudioMetadata * _Nullable)metadataWithFormatContext:(AVFormatContext * _Nullable)fmt_ctx;

@end
