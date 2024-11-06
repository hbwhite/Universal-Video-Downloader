//
//  UVDVideoProcessor.h
//  Universal Video Downloader
//
//  Created by Harrison White on 7/25/12.
//  Copyright (c) 2012 Harrison Apps, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UVDVideoProcessorDelegate;

@interface UVDVideoProcessor : NSObject {
@public
    id <UVDVideoProcessorDelegate> _delegate;
@private
    BOOL defaultAudioTrackOnly;
    BOOL fullQualityVideoOnly;
    NSString *rootDownloadFilePath;
    
    NSMutableString *indexFile;
    NSMutableArray *audioTracksArray;
    NSMutableArray *videosArray;
    NSMutableArray *savedFileNamesArray;
    NSMutableDictionary *savedFileURLsDictionary;
}

@property (nonatomic, assign) id <UVDVideoProcessorDelegate> delegate;

- (id)initWithDelegate:(id <UVDVideoProcessorDelegate>)delegate;
- (void)saveVideoAtURL:(NSURL *)url;

@end

@protocol UVDVideoProcessorDelegate <NSObject>

@optional
- (void)videoProcessorDidFinishProcessing;

@end
