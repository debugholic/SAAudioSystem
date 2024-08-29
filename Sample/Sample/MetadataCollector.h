//
//  MetadataCollector.h
//  AudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <UIKit/UIDevice.h>
#import <libavformat/avformat.h>
#import "AudioMetadata.h"

@interface MetadataCollector : NSObject

+ (AudioMetadata *)metadataWithFormatContext:(AVFormatContext *)fmt_ctx;

@end
