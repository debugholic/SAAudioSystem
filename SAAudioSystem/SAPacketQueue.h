//
//  SAPacketQueue.h
//  SAAudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avformat.h"
#import "avcodec.h"

struct SAPacketQueue {
    AVPacketList *first, *last;
    uint32_t nb_packets;
    uint32_t size;
    int64_t pts;
} typedef SAPacketQueue;

void packet_queue_init(SAPacketQueue *q );
int packet_queue_put_packet(SAPacketQueue *q, AVPacket *packet );
int packet_queue_get_packet(SAPacketQueue *q, AVPacket *packet );
void packet_queue_destroy(SAPacketQueue *q );
void packet_queue_copy(SAPacketQueue *source, SAPacketQueue *dest);
