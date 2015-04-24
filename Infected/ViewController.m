//
//  ViewController.m
//  Infected
//
//  Created by Matt Schulte on 4/22/15.
//
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *startBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.myLibInfected = [LibInfected  sharedLibInfected];
    self.myLibInfected.delegate = self;
    
    if ([self.myLibInfected enabled]) {
        [self.startBtn setEnabled:YES];
    } else {
        [self.startBtn setEnabled:NO];
    }
    
    if ([self.myLibInfected running]) {
        [self.startBtn setTitle:@"STOP" forState:UIControlStateNormal];
    } else {
        [self.startBtn setTitle:@"START" forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)start:(id)sender {
    [self.myLibInfected start];
}

#pragma mark - BLEGraphDelegate
-(void) bleOff {
    [self.startBtn setEnabled:NO];
}

-(void) bleOn {
    [self.startBtn setEnabled:YES];
}

-(CBATTRequest*)receivedReadRequest:(CBATTRequest *)request {
    uuid_t uuid;
    [[UIDevice currentDevice].identifierForVendor getUUIDBytes:uuid];
    NSData *vendorData = [NSData dataWithBytes:uuid length:16];
    request.value = vendorData;
    return request;
}

-(void) receivedReadResponse:(NSData *)data {
    NSLog(@"Received Read Response: %@", data);
}


@end
