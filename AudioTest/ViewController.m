
#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#include "wav_to_flac.h"

@implementation ViewController
@synthesize recButton, textView, spinner;

-(IBAction)recording{
    if(isNotRecording){
        isNotRecording = NO;
        [recButton setTitle:@"STOP" forState:UIControlStateNormal];
        
        [textView setEditable:NO];
        textView.textColor = [UIColor grayColor];
        textView.text=@"Идет запись голоса...";
        
        [recorder record];
        
    }
    else{
        spinner.hidden = NO;
        [spinner startAnimating];
        isNotRecording = YES;
        [recButton setTitle:@"REC" forState:UIControlStateNormal];
        
        [recorder stop];
        long totalAudioLen = 0;
        long totalDataLen = 0;
        long longSampleRate = 16000.0;
        int channels = 2;
        long byteRate = 16*16000.0*channels/8;
        
        [textView setEditable:YES];
        textView.textColor = [UIColor grayColor];
        textView.text=@"Обработка...";
        
        //take data from caf file
        
        NSMutableData * soundData = [NSMutableData dataWithContentsOfFile:[cafURL path]];
        const char * soundBytes = (const char*)[soundData bytes];
        int dataStartIndex = 0;
        //search for data chunk
        for (int i = 0; i<[soundData length]-4; i++) 
        {
            if (soundBytes[i] == 'd' && soundBytes[i+1] == 'a' && soundBytes[i+2] == 't' && soundBytes[i+3] == 'a')
                dataStartIndex = i;
        }
        //take raw audio
        NSData *rawSound = [NSMutableData dataWithData:[soundData subdataWithRange:NSMakeRange(dataStartIndex+10, [soundData length] - dataStartIndex - 10)]];
        
        totalAudioLen=[rawSound length];
        
        totalDataLen=totalAudioLen + 44;
        
        Byte *header = (Byte*)malloc(44);
        header[0]='R';
        header[1]='I';
        header[2]='F';
        header[3]='F';
        header[4]=(Byte) (totalDataLen & 0xff);
        header[5]=(Byte) ((totalDataLen >> 8) & 0xff);
        header[6]=(Byte) ((totalDataLen >> 16) & 0xff);
        header[7]=(Byte) ((totalDataLen >> 24) & 0xff);
        header[8]='W';
        header[9]='A';
        header[10]='V';
        header[11]='E';
        header[12]='f';
        header[13]='m';
        header[14]='t';
        header[15]=' ';
        header[16] = 16;  // 4 bytes: size of 'fmt ' chunk
        header[17] = 0;
        header[18] = 0;
        header[19] = 0;
        header[20] = 1;  // format = 1
        header[21] = 0;
        header[22] = (Byte) channels;
        header[23] = 0;
        header[24] = (Byte) (longSampleRate & 0xff);
        header[25] = (Byte) ((longSampleRate >> 8) & 0xff);
        header[26] = (Byte) ((longSampleRate >> 16) & 0xff);
        header[27] = (Byte) ((longSampleRate >> 24) & 0xff);
        header[28] = (Byte) (byteRate & 0xff);
        header[29] = (Byte) ((byteRate >> 8) & 0xff);
        header[30] = (Byte) ((byteRate >> 16) & 0xff);
        header[31] = (Byte) ((byteRate >> 24) & 0xff);
        header[32] = (Byte) (2 * 16 / 8);  // block align
        header[33] = 0;
        header[34] = 16;  // bits per sample
        header[35] = 0;
        header[36] = 'd';
        header[37] = 'a';
        header[38] = 't';
        header[39] = 'a';
        header[40] = (Byte) (totalAudioLen & 0xff);
        header[41] = (Byte) ((totalAudioLen >> 8) & 0xff);
        header[42] = (Byte) ((totalAudioLen >> 16) & 0xff);
        header[43] = (Byte) ((totalAudioLen >> 24) & 0xff);
        
        NSData *headerData = [NSData dataWithBytes:header length:44];
        NSMutableData * wavFileData = [NSMutableData alloc];
        [wavFileData appendData:headerData];
        [wavFileData appendData:rawSound];
        wavPath = [NSArray arrayWithObjects:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], @"MyAudio.wav", nil];
        wavURL = [NSURL fileURLWithPathComponents:wavPath];
        [[NSFileManager defaultManager] createFileAtPath:[wavURL path] contents:wavFileData attributes:nil];
        //convert to flac
        flacPath = [NSArray arrayWithObjects:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], @"MyAudio.flac", nil];
        flacURL = [NSURL fileURLWithPathComponents:flacPath];
        const char *wave_file = [[wavURL path] UTF8String];
        const char *flac_file = [[flacURL path] UTF8String];
        convertWavToFlac(wave_file, flac_file);
        //send flac to Google
        
        NSData *myData = [NSData dataWithContentsOfFile:[flacURL path]];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                        initWithURL:[NSURL
                                                     URLWithString:@"https://www.google.com/speech-api/v1/recognize?xjerr=1&client=chromium&lang=ru-RU"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
        [request setHTTPMethod:@"POST"];
        //set headers
        
        [request addValue:@"Content-Type" forHTTPHeaderField:@"audio/x-flac; rate=16000"];
        
        [request addValue:@"audio/x-flac; rate=16000" forHTTPHeaderField:@"Content-Type"];
        
        [request setHTTPBody:myData];
        
        [request setValue:[NSString stringWithFormat:@"%d",[myData length]] forHTTPHeaderField:@"Content-length"];
        NSHTTPURLResponse* urlResponse = nil;
        NSError *error = [[NSError alloc] init];
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse  error:&error];
        //catch if we have internet connection
        if (responseData != nil)
        {
            NSString *result = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
            NSLog(@"The answer is: %@",result);
            NSArray *parsedJSON = (NSArray*)[json objectForKey:@"hypotheses"]; 
            //catch if we recognized text
            if ([parsedJSON count] == nil)
            {
                textView.textColor = [UIColor colorWithRed:122.0f/255.0f green:24.0f/255.0f blue:16.0f/255.0f alpha:1.0f];
                textView.text = @"Не удалось распознать. Попробуйте еще раз.";
            }
            else
            {
                NSString *textToShow = [(NSDictionary*)[parsedJSON objectAtIndex:0] objectForKey:@"utterance"];
                
                NSLog(@"JSON answer is: %@", textToShow);
                textView.textColor = [UIColor blackColor];
                textView.text = textToShow;
            }   
        }
        else
        {
            textView.textColor = [UIColor colorWithRed:122.0f/255.0f green:24.0f/255.0f blue:16.0f/255.0f alpha:1.0f];
            textView.text = @"Ошибка сети. Попробуйте еще раз.";
        }
        
        [spinner stopAnimating];
    }
}

- (void)keyboardWillShow:(NSNotification *)notif
{
    [textView setFrame:CGRectMake(40, 148, 240, 80)];
}

- (void)keyboardWillHide:(NSNotification *)notif
{
    [textView setFrame:CGRectMake(40, 148, 240, 275)];
}

-(IBAction)touchBackground:(id)sender;
{
    [textView resignFirstResponder];
}

-(void)viewDidLoad{
    [super viewDidLoad];
    self.title = @"Speech to text";
    [self.view addSubview:spinner];
    textView.delegate = self;
    textView.layer.borderWidth = 2.0f;
    textView.layer.borderColor = [[UIColor grayColor] CGColor];
    textView.layer.cornerRadius = 8;
    textView.layer.backgroundColor = [[UIColor whiteColor] CGColor];
    
    isNotRecording = YES;
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    cafPath = [NSArray arrayWithObjects:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], @"MyAudio", nil];
        
    cafURL = [NSURL fileURLWithPathComponents:cafPath];
    
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt: kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:16000.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    [recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityLow] forKey:AVEncoderAudioQualityKey];
    
    recorder = [[AVAudioRecorder alloc] initWithURL:cafURL settings:recordSetting error:nil];
    recorder.delegate = self;
    recorder.meteringEnabled = YES;
    [recorder prepareToRecord];
    
    //keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

}

-(void)viewDidUnload{
    recorder=nil;
    recButton=nil;
    textView=nil;
}

-(void)dealloc{
    [recorder release];
    [recButton release];
    [textView release];
    [super dealloc];
}

@end
