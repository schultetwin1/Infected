//
//  InfectedTableViewController.m
//  Infected
//
//  Created by Matt Schulte on 4/23/15.
//
//

#import "Sighting.h"
#import "LibInfected/LibInfected.h"
#import "InfectedTableViewController.h"

@interface InfectedTableViewController () <LibInfectedDelgate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *startBtn;

@property NSMutableArray *sightings;
@property (strong, nonatomic) LibInfected* myLibInfected;

@end

@implementation InfectedTableViewController

- (IBAction)startBtnPressed:(id)sender {
    [self.myLibInfected start];
}

- (NSData*) getUUID {
    NSUUID* nsuuid = [UIDevice currentDevice].identifierForVendor;
    NSString* uuidstr = [nsuuid UUIDString];
    
    
    NSData *vendorData = [uuidstr dataUsingEncoding:NSUTF8StringEncoding];
    return vendorData;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sightings = [[NSMutableArray alloc] init];
    
    self.myLibInfected = [LibInfected  sharedLibInfected];
    self.myLibInfected.delegate = self;
    
    if ([self.myLibInfected enabled]) {
        [self.startBtn setEnabled:YES];
    } else {
        [self.startBtn setEnabled:NO];
    }
    
    if ([self.myLibInfected running]) {
        [self.startBtn setTitle:@"STOP"];
    } else {
        [self.startBtn setTitle:@"START"];
    }
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    // 1 section for local encounters
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.sightings count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListPrototypeCell" forIndexPath:indexPath];
    
    // Configure the cell...
    Sighting *encouter = [self.sightings objectAtIndex:indexPath.row];
    
    cell.textLabel.text = encouter.sighted;
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) sendSighting:(Sighting *)sighting {
    double timestamp = [sighting.time timeIntervalSince1970];
    NSString *bodyData = [
        NSString stringWithFormat:@"{\"reporter\":\"%@\", \"sighted\":\"%@\", \"time\":\"%d\", \"rssi\":\"%@\"}",
                          sighting.reporter,
                          sighting.sighted,
                          (int)round(timestamp),
                          sighting.rssi
    ];
    NSString *url = @"https://infected.mjs.pw/infected/api/v1.0/sightings";
    
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    [postRequest setHTTPMethod:@"POST"];
    
    [postRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:strlen([bodyData UTF8String])]];
    [postRequest setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    
    [NSURLConnection sendAsynchronousRequest:postRequest queue:[NSOperationQueue mainQueue] completionHandler:
        ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if ([data length]> 0 && connectionError == nil) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                if (httpResponse.statusCode == 201) {
                    NSLog(@"Uploaded!");
                } else {
                    NSLog(@"Error Uploading: %ld", (long)httpResponse.statusCode);
                }
            } else {
                NSLog(@"Error posting: %@", connectionError.description);
            }
        }
     ];
}

#pragma mark - BLEGraphDelegate
-(void) bleOff {
    [self.startBtn setEnabled:NO];
}

-(void) bleOn {
    [self.startBtn setEnabled:YES];
}

-(CBATTRequest*)receivedReadRequest:(CBATTRequest *)request {
    request.value = [self getUUID];
    return request;
}

-(void) receivedReadResponse:(NSData *)data peripheralRSSI:(NSNumber*) rssi{
    NSLog(@"Received Read Response: %@", rssi);
    Sighting *sighting = [[Sighting alloc]init];
    sighting.reporter = [[NSString alloc] initWithData:[self getUUID] encoding:NSUTF8StringEncoding];
    sighting.sighted = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    sighting.time = [NSDate date];
    sighting.rssi = rssi;
    [self sendSighting:sighting];
    [self.sightings addObject:sighting];
    [self.tableView reloadData];
}

@end
