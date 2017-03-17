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
#import <MediaPlayer/MediaPlayer.h>


static void *AVSEPlayerItemStatusContext = &AVSEPlayerItemStatusContext;
static void *AVSEPlayerLayerReadyForDisplay = &AVSEPlayerLayerReadyForDisplay;

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>



@property (strong, nonatomic) AVPlayer *player;



@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) NSURL *audioURL;
@property (strong, nonatomic) NSURL *exportURL;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Create a AVAsset for the given video from the main bundle
    self.videoURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Movie" ofType:@"m4v"]];
    self.audioURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Music" ofType:@"m4a"]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.exportURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@.mp4", [paths objectAtIndex:0], @"postvideo"]];
}



- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initializePlayerWithURL:self.videoURL];
}

#pragma mark - Actions
- (IBAction)openCameraAction:(id)sender {
    UIImagePickerController *videoPicker = [[UIImagePickerController alloc] init];
    videoPicker.delegate = self;
    videoPicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    videoPicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    //    videoPicker.mediaTypes = @[(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4];
    videoPicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self presentViewController:videoPicker animated:YES completion:nil];
}


- (IBAction)exportAction:(id)sender {
    [self editVideo];
}


- (void)initializePlayerWithURL:(NSURL *)url
{
    self.player = [[AVPlayer alloc] initWithURL:url];
    AVPlayerLayer *videoLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    videoLayer.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64);
    videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:videoLayer];
    
//    self.player.
    
    [self.player play];
}


#pragma mark - Edit Video
- (void)editVideo
{
    NSFileManager* fileManager=[NSFileManager defaultManager];
    [fileManager removeItemAtURL:self.exportURL error:nil];
    
    AVAsset *asset = [[AVURLAsset alloc] initWithURL:self.videoURL options:nil];
    AVAssetTrack *assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    AVAssetTrack *assetAudioTrack =  [asset tracksWithMediaType:AVMediaTypeAudio][0];
    
    AVMutableComposition* mutableComposition = [AVMutableComposition composition];
    NSError *error = nil;
    AVMutableCompositionTrack *compositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *compositionAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // setup video lenght
    CMTime position5 = CMTimeMakeWithSeconds(5, 1);
    CMTime position10 = CMTimeMakeWithSeconds(10, 1);
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetAudioTrack atTime:kCMTimeZero error:&error];
    for(int i=1;i<3;i++){
        CMTime pos = CMTimeMakeWithSeconds(i*5+10, 1);
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(position10,position5) ofTrack:assetVideoTrack atTime:pos error:&error];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(position10,position5) ofTrack:assetAudioTrack atTime:pos error:&error];
    }
    
    
    // add audio
    
    AVAsset *audioAsset = [[AVURLAsset alloc] initWithURL:self.audioURL options:nil];
    AVAssetTrack *newAudioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
    AVMutableCompositionTrack *customAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [customAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [audioAsset duration]) ofTrack:newAudioTrack atTime:position10 error:&error];
    
    
    
    AVAssetExportSession* exportSession = [[AVAssetExportSession alloc] initWithAsset:[mutableComposition copy] presetName:AVAssetExportPresetMediumQuality];
    
    CGAffineTransform t = assetVideoTrack.preferredTransform;
    AVMutableVideoComposition* mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
    mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    
    
    AVMutableVideoCompositionInstruction* instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mutableComposition duration]);
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:(mutableComposition.tracks)[0]];
    [layerInstruction setTransform:t atTime:kCMTimeZero];
    instruction.layerInstructions = @[layerInstruction];
    mutableVideoComposition.instructions = @[instruction];
    
    
    // add animation
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath: @"contents"];
    
    animation.calculationMode = kCAAnimationDiscrete;
    animation.duration = 7.0;
    animation.repeatCount = 1;
    animation.beginTime = 3;
    //animation.values = @[[[UIImage imageNamed:@"smile"] CGImage]]; // NSArray of CGImageRefs
    
    
    CGSize size = assetVideoTrack.naturalSize;
    CALayer *animationLayer = [CALayer layer];
    animationLayer.frame = CGRectMake(0, 0, 550, 400);
    [animationLayer setMasksToBounds:YES];
    [animationLayer addAnimation: animation forKey: @"contents"];
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    
    parentLayer.frame = CGRectMake(0, 0, size.height, size.width);
    videoLayer.frame = CGRectMake(0, 0, size.height, size.width);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:animationLayer];
    
    
    
    mutableVideoComposition.animationTool = [AVVideoCompositionCoreAnimationTool
                                             videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    
    
    exportSession.videoComposition = mutableVideoComposition;
    exportSession.outputURL = self.exportURL;
    exportSession.outputFileType=AVFileTypeMPEG4;
    
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void){
        switch (exportSession.status) {
            case AVAssetExportSessionStatusCompleted:
                //[self saveToPhtotLibrary:exportURL];
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Failed:%@",exportSession.error);
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Canceled:%@",exportSession.error);
                break;
            default:
                break;
        }
        NSFileManager* fileManager=[NSFileManager defaultManager];
        [fileManager removeItemAtURL:self.videoURL error:nil];
    }];
}


#pragma mark - Image Picker Delega
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    [self initializePlayerWithURL:self.videoURL];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
