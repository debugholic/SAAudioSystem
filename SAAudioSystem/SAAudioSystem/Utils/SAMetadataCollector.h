//
//  SAMetadataCollector.h
//  SAAudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <UIKit/UIDevice.h>
#import <libavformat/avformat.h>
#import "SAAudioMetadata.h"

@interface SAMetadataCollector : NSObject

+ (SAAudioMetadata *)metadataWithFormatContext:(AVFormatContext *)formatContext;

@end
