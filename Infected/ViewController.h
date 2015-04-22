//
//  ViewController.h
//  Infected
//
//  Created by Matt Schulte on 4/22/15.
//
//

#import <CoreBluetooth/CoreBluetooth.h>

#import <UIKit/UIKit.h>

extern NSString *const PERIPHERAL_MANAGER_IDENTIFIER;
extern NSString *const CENTRAL_MANAGER_IDENTIFIER;

@interface ViewController : UIViewController <CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBPeripheralManager *myPeripheralManager;
@property (strong, nonatomic) CBCentralManager *myCentralManager;

@end

