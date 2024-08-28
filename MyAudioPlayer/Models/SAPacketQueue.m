//
//  SAPacketQueue.m
//  SAAudioSystem
//
//  Created by DebugHolic on 08/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import "SAPacketQueue.h"

void packet_queue_init(SAPacketQueue *q) {
	memset(q, 0, sizeof(SAPacketQueue));
	q->first = NULL;
	q->last = NULL;
    q->pts = 0;
}

int packet_queue_put_packet(SAPacketQueue *q, AVPacket *packet) {
	AVPacketList *packetList = NULL;
	packetList = av_malloc(sizeof(AVPacketList));

	if (!packetList) {
		return -1;
	}

	packetList->pkt = *packet;
	packetList->next = NULL;

	/* Empty Queue */
	if (!q->last) {
		q->first = packetList;
	}

	/* Normal case */
	else {
		q->last->next = packetList;
	}

	q->last = packetList;
	q->nb_packets++;
	q->size += packetList->pkt.size;
    q->pts = packetList->pkt.pts;
	return TRUE;
}

int packet_queue_get_packet(SAPacketQueue *q, AVPacket *packet) {
	AVPacketList *packetTemp = NULL;
	packetTemp = q->first;

	/* Normal case */
	if (packetTemp) {
		q->first = packetTemp->next;

		/* Only 1 Node in Queue */
		if (!q->first) {
			q->last = NULL;
		}

		q->nb_packets--;
		q->size -= packetTemp->pkt.size;
		*packet = packetTemp->pkt;
        av_free(packetTemp);
		return TRUE;
	}

	/* Empty Queue */
	else {
        if (q->nb_packets > 0) {
            q->nb_packets = 0;
            q->size = 0;
        }
		return FALSE;
	}
}

void packet_queue_destroy(SAPacketQueue *q) {
	AVPacket packet;
    
	while ( q->nb_packets > 0 ) {
		packet_queue_get_packet(q, &packet);
        av_packet_unref( &packet );
	}
    q->pts = 0;
}

void packet_queue_copy(SAPacketQueue *source, SAPacketQueue *dest) {
    AVPacket packet;
    av_init_packet(&packet);
    while (packet_queue_get_packet(source, &packet)) {
        packet_queue_put_packet(dest, &packet);
    }
}

