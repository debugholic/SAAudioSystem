//
//  AlbumArtExtractor.h
//  AudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <UIKit/UIImage.h>
#import <libavformat/avformat.h>

@interface AlbumArtExtractor : NSObject

+ (UIImage *)albumArtWithFormatContext:(AVFormatContext *)fmt_ctx;

@end
