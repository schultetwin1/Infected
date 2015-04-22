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

@interface ViewController : UIViewController <CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager *myPeripheralManager;

@end

