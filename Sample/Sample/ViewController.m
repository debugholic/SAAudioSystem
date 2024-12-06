//
//  ViewController.m
//  Sample
//
//  Created by DebugHolic on 27/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import "ViewController.h"
#import "Player.h"

@interface ViewController () <PlayerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *albumArtView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UISlider *durationSlider;
@property (weak, nonatomic) IBOutlet UILabel *curDurationLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalDurationLabel;
@property (weak, nonatomic) IBOutlet UIButton *playPauseBtn;
@property (weak, nonatomic) IBOutlet UIButton *prevBtn;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;

@property (strong, nonatomic) Player *player;
@property (assign, nonatomic) AudioQueuePlayerState state;
@property (strong, nonatomic) NSArray *playQueue;
@property (assign, nonatomic) NSUInteger playNumber;

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.player = [[Player alloc] init];
    self.player.delegate = self;
    self.playQueue = @[[[NSBundle mainBundle] pathForResource:@"Pavane for Dead Princess" ofType:@"mp3"],
                       [[NSBundle mainBundle] pathForResource:@"Nocturne in C# minor" ofType:@"mp3"],
                       [[NSBundle mainBundle] pathForResource:@"Canon in D" ofType:@"mp3"],
                       [[NSBundle mainBundle] pathForResource:@"Carmen Habanera" ofType:@"mp3"],
                       [[NSBundle mainBundle] pathForResource:@"Minuet in G" ofType:@"mp3"]];
    self.playNumber = 0;
    NSString *path = self.playQueue[self.playNumber];
    [self.player insertTrackWithPath:path withSuccess:^(BOOL success, NSError *error) {
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_albumArtView.image = self.player.curTrack.albumArt;
                self->_artistLabel.text = self.player.curTrack.artist;
                self->_infoLabel.text = [NSString stringWithFormat:@"%lubit / %.1fkHz", self.player.curTrack.bitdepth,
                                         (Float64)self.player.curTrack.samplerate/1000];
                self->_titleLabel.text = self.player.curTrack.title;
                if (!self->_durationSlider.isHighlighted) {
                    self->_durationSlider.value = (Float64)self.player.curDuration / self.player.curTrack.duration;
                }
                self->_totalDurationLabel.text = DurationInNumToString(self.player.curTrack.duration);
            });
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (IBAction)touchUpPlayPause:(id)sender {
    if (self.state == AudioQueuePlayerStatePlaying) {
        [self.player pauseTrackWithSuccess:nil];

    } else {
        if (self.state == AudioQueuePlayerStateStopped || self.state == AudioQueuePlayerStateInitialized) {
            NSString *path = self.playQueue[self.playNumber];
            [self.player insertTrackWithPath:path withSuccess:^(BOOL success, NSError *error) {
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self->_albumArtView.image = self.player.curTrack.albumArt;
                        self->_artistLabel.text = self.player.curTrack.artist;
                        self->_infoLabel.text = [NSString stringWithFormat:@"%lubit / %.1fkHz", self.player.curTrack.bitdepth, (Float64)self.player.curTrack.samplerate/1000];
                        self->_titleLabel.text = self.player.curTrack.title;
                        if (!self->_durationSlider.isHighlighted) {
                            self->_durationSlider.value = (Float64)self.player.curDuration / self.player.curTrack.duration;
                        }
                        self->_totalDurationLabel.text = DurationInNumToString(self.player.curTrack.duration);
                    });
                    [self.player playTrackWithSuccess:nil];
                }
            }];
        } else {
            [self.player playTrackWithSuccess:nil];
        }
    }
}

- (IBAction)touchUpPrev:(id)sender {
    if (self.player.curDuration < 3) {
        [self.player stopTrackWithSuccess:^(BOOL success, NSError *error) {
            if (success) {
                NSString *path = self.playQueue[self.playNumber];
                [self.player insertTrackWithPath:path withSuccess:^(BOOL success, NSError *error) {
                    if (success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self->_albumArtView.image = self.player.curTrack.albumArt;
                            self->_artistLabel.text = self.player.curTrack.artist;
                            self->_infoLabel.text = [NSString stringWithFormat:@"%lubit / %.1fkHz", self.player.curTrack.bitdepth, (Float64)self.player.curTrack.samplerate/1000];
                            self->_titleLabel.text = self.player.curTrack.title;
                            if (!self->_durationSlider.isHighlighted) {
                                self->_durationSlider.value = (Float64)self.player.curDuration / self.player.curTrack.duration;
                            }
                            self->_totalDurationLabel.text = DurationInNumToString(self.player.curTrack.duration);
                        });
                        [self.player playTrackWithSuccess:nil];
                    }
                }];
            }
        }];
    } else {
        [self.player stopTrackWithSuccess:^(BOOL success, NSError *error) {
            if (success) {
                self.playNumber--;
                if (self.playNumber == 0) {
                    self.playNumber = 4;
                }
                NSString *path = self.playQueue[self.playNumber];
                [self.player insertTrackWithPath:path withSuccess:^(BOOL success, NSError *error) {
                    if (success) {
                        [self.player playTrackWithSuccess:nil];
                    }
                }];
            }
        }];
    }
}

- (IBAction)touchUpNext:(id)sender {
    [self.player stopTrackWithSuccess:^(BOOL success, NSError *error) {
        if (success) {
            self.playNumber++;
            if (self.playNumber >= self.playQueue.count) {
                self.playNumber = 0;
            }
            NSString *path = self.playQueue[self.playNumber];
            [self.player insertTrackWithPath:path withSuccess:^(BOOL success, NSError *error) {
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self->_albumArtView.image = self.player.curTrack.albumArt;
                        self->_artistLabel.text = self.player.curTrack.artist;
                        self->_infoLabel.text = [NSString stringWithFormat:@"%lubit / %.1fkHz",
                                                self.player.curTrack.bitdepth, (Float64)self.player.curTrack.samplerate/1000];
                        self->_titleLabel.text = self.player.curTrack.title;
                        if (!self->_durationSlider.isHighlighted) {
                            self->_durationSlider.value = (Float64)self.player.curDuration / self.player.curTrack.duration;
                        }
                        self->_totalDurationLabel.text = DurationInNumToString(self.player.curTrack.duration);
                    });
                    [self.player playTrackWithSuccess:nil];
                }
            }];
        }
    }];
}

- (IBAction)touchUpSlider:(id)sender {
    NSUInteger duration = self->_durationSlider.value * self.player.curTrack.duration;
    [self.player seekToDuration:duration withSuccess:nil];
}

- (IBAction)changeSlider:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger duration = self->_durationSlider.value * self.player.curTrack.duration;
        self->_curDurationLabel.text = DurationInNumToString(duration);
    });
}

NSUInteger DurationInStringToNum (NSString *duration) {
    NSUInteger durationInNum = 0;
    NSArray *durationComponents = [duration componentsSeparatedByString:@":"];
    
    NSEnumerator *e = durationComponents.objectEnumerator;
    durationInNum += [(NSString *)e.nextObject integerValue] * 60 * 60; // H
    durationInNum += [(NSString *)e.nextObject integerValue] * 60;      // M
    durationInNum += [(NSString *)e.nextObject integerValue];           // S
    return durationInNum;
}

NSString * DurationInNumToString (NSUInteger duration) {
    NSUInteger h = duration / (60 * 60);
    duration -= h * 60 *60;
    NSUInteger m = duration / 60;
    duration -= m * 60;
    NSUInteger s = duration;
    
    if (h >= 1) {
        return [NSString stringWithFormat:@"%lu:%02lu:%02lu", (unsigned long)h, (unsigned long)m, (unsigned long)s];
    } else {
        return [NSString stringWithFormat:@"%02lu:%02lu", (unsigned long)m, (unsigned long)s];
    }
}

- (void)player:(Player *)player didChangeState:(AudioQueuePlayerState)state {
    if (state == AudioQueuePlayerStatePlaying) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_playPauseBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
            [self->_playPauseBtn setImage:[UIImage imageNamed:@"pause_p"] forState:UIControlStateFocused];
        });
        self.state = state;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_playPauseBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
            [self->_playPauseBtn setImage:[UIImage imageNamed:@"play_p"] forState:UIControlStateFocused];
        });
        self.state = state;
    }
}

- (void)player:(Player *)player didTrackPlayingForDuration:(Float64)duration {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self->_durationSlider.isHighlighted) {
            self->_durationSlider.value = (Float64)self.player.curDuration / self.player.curTrack.duration;
            self->_curDurationLabel.text = DurationInNumToString(self.player.curDuration);
        }
        if (self->_durationSlider.value == 1) {
            [self.player stopTrackWithSuccess:^(BOOL success, NSError *error) {
                if (success) {
                    self.playNumber++;
                    if (self.playNumber >= self.playQueue.count) {
                        self.playNumber = 0;
                    }
                    NSString *path = self.playQueue[self.playNumber];
                    [self.player insertTrackWithPath:path withSuccess:^(BOOL success, NSError *error) {
                        if (success) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self->_albumArtView.image = self.player.curTrack.albumArt;
                                self->_artistLabel.text = self.player.curTrack.artist;
                                self->_infoLabel.text = [NSString stringWithFormat:@"%lubit / %.1fkHz", self.player.curTrack.bitdepth, (Float64)self.player.curTrack.samplerate/1000];
                                self->_titleLabel.text = self.player.curTrack.title;
                                if (!self->_durationSlider.isHighlighted) {
                                    self->_durationSlider.value = (Float64)self.player.curDuration / self.player.curTrack.duration;
                                }
                                self->_totalDurationLabel.text = DurationInNumToString(self.player.curTrack.duration);
                            });
                            [self.player playTrackWithSuccess:nil];
                        }
                    }];
                }
            }];
        }
    });
}

@end
