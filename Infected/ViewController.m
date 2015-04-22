//
//  ViewController.m
//  Infected
//
//  Created by Matt Schulte on 4/22/15.
//
//

#import "ViewController.h"
NSString *const PERIPHERAL_MANAGER_IDENTIFIER = @"myPeripheralManagerIdentifier";
NSString *const CENTRAL_MANAGER_IDENTIFIER    = @"myCentralMangerIdentifier";
NSString *const INFECTED_SERVICE_UUID = @"5E216DCB-0474-4A37-8935-64856A405569";
NSString *const INFECTED_CHARACTERISTIC_UUID = @"BB6537C6-0622-416C-BB54-79A3911897D0";

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *startBtn;
@property (weak, nonatomic) IBOutlet UISegmentedControl *healthyInfectedSegment;
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;
@property (strong, nonatomic) CBPeripheral          *connectedPeripheral;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    if (self.myPeripheralManager == nil) {
        self.myPeripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:@{CBPeripheralManagerOptionShowPowerAlertKey:@YES, CBPeripheralManagerOptionRestoreIdentifierKey:PERIPHERAL_MANAGER_IDENTIFIER}];
    }
    
    if (self.myCentralManager == nil) {
        self.myCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey:@YES, CBCentralManagerOptionRestoreIdentifierKey:CENTRAL_MANAGER_IDENTIFIER}];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) startAdvertisingAndScanning {
    // Advertising
    CBUUID *const infectedServiceUUID = [CBUUID UUIDWithString:INFECTED_SERVICE_UUID];
    CBUUID *const infectedCharacteristicUUID = [CBUUID UUIDWithString:INFECTED_CHARACTERISTIC_UUID];
    CBMutableCharacteristic *infectedCharacteristic = [[CBMutableCharacteristic alloc] initWithType:infectedCharacteristicUUID properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    CBMutableService *infectedService = [[CBMutableService alloc] initWithType:infectedServiceUUID primary:YES];
    infectedService.characteristics  = @[infectedCharacteristic];
    
    [self.myPeripheralManager addService:infectedService];
    
    [self.myPeripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[infectedServiceUUID]}];
    
    // Scanning
    [self.myCentralManager scanForPeripheralsWithServices:@[infectedServiceUUID] options:nil];
}

- (IBAction)start:(id)sender {
    [self startAdvertisingAndScanning];
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

- (void) peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Error publishing service: %@", [error localizedDescription]);
    }
}

- (void) peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    if (error) {
        NSLog(@"Error starting advertising: %@", [error localizedDescription]);
    }
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    NSLog(@"Received Read Request");
    request.value = [@"1" dataUsingEncoding:NSUTF8StringEncoding];
    [self.myPeripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
}

#pragma mark - CBCentralManagerDelegate Functions
- (void) centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBCentralManagerStatePoweredOn) {
        self.startBtn.enabled = YES;
    } else {
        self.startBtn.enabled = NO;
    }
}

- (void) centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {
    NSArray* peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
    NSArray *scanServices = dict[CBCentralManagerRestoredStateScanServicesKey];
    NSDictionary *scanOptions = dict[CBCentralManagerRestoredStateScanOptionsKey];
    
    for (CBPeripheral* peripheral in peripherals) {
        [self.myCentralManager connectPeripheral:peripheral options:nil];
    }
    
    [self.myCentralManager scanForPeripheralsWithServices:scanServices options:scanOptions];
}

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"Discovered Infected Device: %@ with %@ RSSI", peripheral.identifier, RSSI);
    
    if (advertisementData[CBAdvertisementDataIsConnectable]) {
        self.discoveredPeripheral = peripheral;
        [self.myCentralManager connectPeripheral:self.discoveredPeripheral options:nil];
        NSLog(@"Attempting to connect");
    } else {
        NSLog(@"Not Connectable");
    }
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect to %@: %@", peripheral.identifier, error.description);
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected to %@", peripheral.identifier);
    
    self.connectedPeripheral = peripheral;
    
    self.connectedPeripheral.delegate = self;
    
    [self.connectedPeripheral discoverServices:@[[CBUUID UUIDWithString:INFECTED_SERVICE_UUID]]];
}

-(void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Disconnected from %@ because %@", peripheral.identifier, error.description);
    
    self.connectedPeripheral = nil;
}

# pragma mark - CBPeripheralDelegate Funcs
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"Error: Could not discover services: %@", error.description);
        [self.myCentralManager cancelPeripheralConnection:peripheral];
        self.connectedPeripheral = nil;
        return;
    }
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:INFECTED_CHARACTERISTIC_UUID]] forService:service];
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Error: Could not discover characteristics from service: %@", error.description);
        [self.myCentralManager cancelPeripheralConnection:peripheral];
        self.connectedPeripheral = nil;
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        [peripheral readValueForCharacteristic:characteristic];
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error: Could not update value for characteristic: %@", error.description);
        [self.myCentralManager cancelPeripheralConnection:peripheral];
        self.connectedPeripheral = nil;
        return;
    }
    
    NSLog(@"Read Characteristic: %@", characteristic.value);
    [self.myCentralManager cancelPeripheralConnection:peripheral];
    self.connectedPeripheral = nil;
}

@end
