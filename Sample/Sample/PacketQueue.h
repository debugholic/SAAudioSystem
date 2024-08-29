//
//  PacketQueue.h
//  AudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>
#import <libavcodec/avcodec.h>



struct PacketList {
    AVPacket pkt;
    struct PacketList *next;
} typedef PacketList;

struct PacketQueue {
    PacketList *first, *last;
    uint32_t nb_packets;
    uint32_t size;
    int64_t pts;
} typedef PacketQueue;

void packet_queue_init(PacketQueue *q );
int packet_queue_put_packet(PacketQueue *q, AVPacket *packet);
int packet_queue_get_packet(PacketQueue *q, AVPacket *packet);
void packet_queue_destroy(PacketQueue *q );
void packet_queue_copy(PacketQueue *source, PacketQueue *dest);
