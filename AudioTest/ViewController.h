
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "Reachability.h"
@interface ViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate, UITextViewDelegate>
{
    IBOutlet UIButton *recButton;
    IBOutlet UITextView *textView;
    IBOutlet UIActivityIndicatorView *spinner;
    
    BOOL isNotRecording;
    
    AVAudioRecorder *recorder;
    
    NSArray *cafPath, *wavPath, *flacPath;
    
    NSURL *cafURL, *wavURL, *flacURL;
    
    Reachability *internetReachable;
    Reachability *hostReachable;
}

@property (nonatomic, retain) IBOutlet UIButton *recButton;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@property BOOL hostActive;

-(IBAction)recording;

@end
