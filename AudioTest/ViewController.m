
#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#include "wav_to_flac.h"

@implementation ViewController
@synthesize playButton, recButton;

-(IBAction)recording{
    if(isNotRecording){
        isNotRecording = NO;
        [recButton setTitle:@"STOP" forState:UIControlStateNormal];
        playButton.enabled = NO;
        recStateLabel.text = @"Recording";
        
        [recorder record];
        
    }
    else{
        isNotRecording = YES;
        [recButton setTitle:@"REC" forState:UIControlStateNormal];
        playButton.enabled = YES;
        recStateLabel.text = @"Not Recording";
        
        [recorder stop];
        
        //const char *wave_file = [[waveURL path] UTF8String];
        //const char *flac_file = [[flacURL path] UTF8String];
        
    }
}

-(IBAction)playback{
    recButton.enabled=NO;
    playStateLabel.text=@"Playing";
    
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:recorder.url error:nil];
    [player setDelegate:self];
    [player prepareToPlay];
    [player play];
    
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    recButton.enabled=YES;
    playStateLabel.text=@"Not Playing";
}

-(void)viewDidLoad{
     [super viewDidLoad];
    
    isNotRecording = YES;
    [playButton setEnabled:NO];
    [recStateLabel setText:@"Not recording"];
    [playStateLabel setText:@"Not playing"];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    wavePath = [NSArray arrayWithObjects:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], @"MyAudio.wav", nil];
    flacPath = [NSArray arrayWithObjects:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], @"MyAudioFlac", nil];
    
    waveURL = [NSURL fileURLWithPathComponents:wavePath];
    flacURL = [NSURL fileURLWithPathComponents:flacPath];
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    NSLog([waveURL path]);
    
    [recordSetting setValue:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:16000.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    [recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityLow] forKey:AVEncoderAudioQualityKey];
    
    recorder = [[AVAudioRecorder alloc] initWithURL:waveURL settings:recordSetting error:nil];
    recorder.delegate = self;
    recorder.meteringEnabled = YES;
    [recorder prepareToRecord];

}

-(void)viewDidUnload{
    player=nil;
    recorder=nil;
    playButton=nil;
    recButton=nil;
}

-(void)dealloc{
    [recorder release];
    [player release];
    [playButton release];
    [recButton release];
    [super dealloc];
}

@end
