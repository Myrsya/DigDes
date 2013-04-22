
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface ViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate>
{
    IBOutlet UIButton *playButton;
    IBOutlet UIButton *recButton;
    
    IBOutlet UILabel *recStateLabel;
    IBOutlet UILabel *playStateLabel;
    
    BOOL isNotRecording;
    
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
    
    NSArray *wavePath, *flacPath;
    
    NSURL *waveURL, *flacURL;
}

@property (nonatomic, retain) IBOutlet UIButton *recButton;
@property (nonatomic, retain) IBOutlet UIButton *playButton;

-(IBAction)recording;
-(IBAction)playback;

@end
