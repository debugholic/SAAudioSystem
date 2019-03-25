//
//  SAAudioEqualizer.h
//  SAAudioSystem
//
//  Created by 김영훈 on 18/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SAAudioMetadata.h"

typedef enum : NSUInteger {
    SAAudioEqualizerFlagNone,
    SAAudioEqualizerFlagOn,
    SAAudioEqualizerFlagOff,
} SAAudioEqualizerFlag;

@interface SAAudioEqualizer : NSObject

@property (strong, nonatomic, nonnull) NSArray <NSNumber *> *bands;
@property (strong, nonatomic, nonnull) NSArray <NSNumber *> *gains;
@property (strong, nonatomic, nonnull) NSArray <NSNumber *> *qFactors;
@property (strong, nonatomic, nonnull) NSNumber *preamp;
@property (strong, nonatomic, readonly, nullable) SAAudioMetadata *metadata;

- (instancetype)initWithDefautBands_10;
- (instancetype)initWithDefautBands_20;
- (int)adjust:(void *)data length:(size_t)length flag:(SAAudioEqualizerFlag)flag;

@end
