//
//  MoviePlayerViewController.m
//  Universal Video Downloader
//
//  Created by Harrison White on 7/19/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import "MoviePlayerViewController.h"

#define PLAYBACK_TIME_OFFSET_IN_SECONDS 15

@interface MoviePlayerViewController ()

- (void)playbackDidFinish:(NSNotification *)notification;

@end

@implementation MoviePlayerViewController

@synthesize delegate = _delegate;

- (id)initWithDelegate:(id <MoviePlayerViewControllerDelegate>)delegate contentURL:(NSURL *)contentURL initialPlaybackTime:(NSTimeInterval)initialPlaybackTime {
    self = [super init];
    if (self) {
        // This is used instead of [super initWithContentURL:contentURL] above because it is supposed to help to prevent the AVPlayerItem queue error.
        [self.moviePlayer setContentURL:contentURL];
        
        self.delegate = delegate;
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(playbackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
        
        self.moviePlayer.initialPlaybackTime = initialPlaybackTime;
    }
    return self;
}

- (void)playbackDidFinish:(NSNotification *)notification {
    NSTimeInterval currentPlaybackTime = self.moviePlayer.currentPlaybackTime;
    NSTimeInterval duration = self.moviePlayer.duration;
    
    if (_delegate) {
        if ([_delegate respondsToSelector:@selector(moviePlayerViewControllerDidFinishPlayingVideoAtPlaybackTime:)]) {
            NSTimeInterval playbackTime = 0;
            if (currentPlaybackTime > 0) {
                if ((currentPlaybackTime + PLAYBACK_TIME_OFFSET_IN_SECONDS) < duration) {
                    playbackTime = currentPlaybackTime;
                }
            }
            
            [_delegate moviePlayerViewControllerDidFinishPlayingVideoAtPlaybackTime:playbackTime];
        }
    }
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

// iOS 6 Rotation Methods

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
