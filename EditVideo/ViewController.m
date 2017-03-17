//
//  ViewController.m
//  EditVideo
//
//  Created by Ozzy   on 3/10/17.
//  Copyright © 2017 WallTree. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>


static void *AVSEPlayerItemStatusContext = &AVSEPlayerItemStatusContext;
static void *AVSEPlayerLayerReadyForDisplay = &AVSEPlayerLayerReadyForDisplay;

@interface ViewController ()



@property AVPlayer *player;
@property AVPlayerLayer *playerLayer;
@property double currentTime;
@property (readonly) double duration;






@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Create a AVAsset for the given video from the main bundle
    NSString *videoURL = [[NSBundle mainBundle] pathForResource:@"Movie" ofType:@"m4v"];
    AVAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoURL] options:nil];
    
    
    
}


#pragma mark - Playback




@end
