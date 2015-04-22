//
//  ViewController.m
//  Infected
//
//  Created by Matt Schulte on 4/22/15.
//
//

#import "ViewController.h"
NSString *const PERIPHERAL_MANAGER_IDENTIFIER = @"myPeripheralManagerIdentifier";

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *startBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    if (self.myPeripheralManager == nil) {
        self.myPeripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:@{CBPeripheralManagerOptionShowPowerAlertKey:@YES, CBPeripheralManagerOptionRestoreIdentifierKey:PERIPHERAL_MANAGER_IDENTIFIER}];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)start:(id)sender {
}

#pragma mark - CBPeripheralManagerDelegate Functions

- (void) peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        self.startBtn.enabled = YES;
    } else {
        self.startBtn.enabled = NO;
    }
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict {
    NSDictionary *advData = dict[CBPeripheralManagerRestoredStateAdvertisementDataKey];
    [self.myPeripheralManager startAdvertising:advData];
    
    NSArray* services = dict[CBPeripheralManagerRestoredStateServicesKey];
    
    for (CBMutableService *service in services) {
        [self.myPeripheralManager addService:service];
    }
}

@end
