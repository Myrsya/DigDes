
#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

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
    
    NSArray *pathComponents = [NSArray arrayWithObjects:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], @"MyAudio.m4a", nil];
    
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    NSLog([outputFileURL path]);
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    
    recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:nil];
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
