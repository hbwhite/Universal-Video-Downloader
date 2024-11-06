//
//  MoviePlayerViewController.h
//  Universal Video Downloader
//
//  Created by Harrison White on 7/19/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

@protocol MoviePlayerViewControllerDelegate;

@interface MoviePlayerViewController : MPMoviePlayerViewController {
    id <MoviePlayerViewControllerDelegate> _delegate;
}

@property (nonatomic, assign) id <MoviePlayerViewControllerDelegate> delegate;

- (id)initWithDelegate:(id <MoviePlayerViewControllerDelegate>)delegate contentURL:(NSURL *)contentURL initialPlaybackTime:(NSTimeInterval)initialPlaybackTime;

@end

@protocol MoviePlayerViewControllerDelegate <NSObject>

@optional
- (void)moviePlayerViewControllerDidFinishPlayingVideoAtPlaybackTime:(NSTimeInterval)playbackTime;

@end
