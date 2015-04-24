//
//  ViewController.h
//  Infected
//
//  Created by Matt Schulte on 4/22/15.
//
//

#import <UIKit/UIKit.h>

#import "LibInfected/LibInfected.h"

@interface ViewController : UIViewController <LibInfectedDelgate>

@property (strong, nonatomic) LibInfected* myLibInfected;

@end

