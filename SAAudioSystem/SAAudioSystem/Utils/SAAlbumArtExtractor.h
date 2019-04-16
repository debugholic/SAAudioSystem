//
//  SAAlbumArtExtractor.h
//  SAAudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <UIKit/UIImage.h>
#import <libavformat/avformat.h>

@interface SAAlbumArtExtractor : NSObject

+ (UIImage *)albumArtWithFormatContext:(AVFormatContext *)formatContext;

@end
