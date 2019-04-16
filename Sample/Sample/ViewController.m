//
//  ViewController.m
//  Sample
//
//  Created by DebugHolic on 27/03/2019.
//  Copyright © 2019 Sidekick-Academy. All rights reserved.
//

#import "ViewController.h"
#import "Player.h"

@interface ViewController ()

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Canon in D" ofType:@"mp3"];
    Player *player = [[Player alloc] init];
    [player insertTrackWithURL:path withSuccess:^(BOOL success, NSError *error) {
        NSLog(@"INSERT");
        if (success) {
            [player playTrackWithSuccess:^(BOOL success, NSError *error) {
                NSLog(@"PLAY");
            }];
        } else {
            NSLog(@"%@", error);
        }
    }];
}

@end
