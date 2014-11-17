//
//  ViewController.m
//  qualityEnergyMeter
//
//  Created by Jorge Macias on 5/6/14.
//  Copyright (c) 2014 Diincasa. All rights reserved.
//

#import "ViewController.h"
#import "fileManager.h"

typedef enum
{
    IDLE = 0,
    SCANNING,
    CONNECTED,
} ConnectionState;

@interface ViewController ()

@end


@implementation ViewController


@synthesize txCharacteristic = _txCharacteristic;
@synthesize rxCharacteristic = _rxCharacteristic;

NSString *lastcommand;
int recordCounter=0;
+ (CBUUID *) uartServiceUUID
{
    return [CBUUID UUIDWithString:@"6e400001-b5a3-f393-e0a9-e50e24dcca9e"];
}


+ (CBUUID *) txCharacteristicUUID
{
    return [CBUUID UUIDWithString:@"6e400002-b5a3-f393-e0a9-e50e24dcca9e"];
}

+ (CBUUID *) rxCharacteristicUUID
{
    return [CBUUID UUIDWithString:@"6e400003-b5a3-f393-e0a9-e50e24dcca9e"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
// 1) Create Object
- (void)viewDidLoad
{
    [super viewDidLoad];
	//
    // Initialize de Corebluetooth central manager object
    //
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    //Initialize last command
    lastcommand=@"none";
    
    // Disable buttons before connected
    [self.vrmsButton setEnabled:NO];
    [self.currentButton setEnabled:NO];
    [self.fileTransferButton setEnabled:NO];
    [self.emailButton setEnabled:NO];
}
// 2) Central Manager update
- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    //NSLog(@"centralManagerDidUpdateState");
    if (central.state == CBCentralManagerStatePoweredOn)
    {
       // [self.connectButton setEnabled:YES];

    }
    
}

// 3) Connect button pressed
// 4) start scan
- (IBAction)connectButtonPressed:(id)sender {
    switch (self.state) {
        case IDLE:
            self.state = SCANNING;
            //NSLog(@"Started scan ...");
            [self updateConsole:@"Started Scan..."];

            [self.connectButton setTitle:@"Scanning ..." forState:UIControlStateNormal];
            
             [self.manager scanForPeripheralsWithServices:@[ViewController.uartServiceUUID] options:@{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:NO]}];
             break;

        case SCANNING:
            self.state = IDLE;
            //NSLog(@"Stopped scan");
            [self updateConsole:@"Stopped Scan"];

            [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
            
            [self.manager stopScan];
            break;
            
        case CONNECTED:
            //NSLog(@"Disconnect peripheral %@", self.peripheral.name);
            //[self updateConsole:@"Disconnect peripheral"];

            [self.manager cancelPeripheralConnection:self.peripheral];
            [self.vrmsButton setEnabled:YES];
            [self.currentButton setEnabled:YES];
            [self.fileTransferButton setEnabled:YES];
            [self.emailButton setEnabled:YES];
            break;
    }
}


//5) Did Discover Peripheral
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    //NSLog(@"Did discover peripheral %@", peripheral.name);
    [self.manager stopScan];
     // Core Bluetooth does not know whether you are interested in this peripheral when it is discovered. Connecting to it is not enough, you need to retain it.
    [central connectPeripheral:peripheral options:nil];
    self.peripheral = peripheral;
   
    [self.manager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: [NSNumber numberWithBool:YES]}];
}
// 6,7 8) Did Connect Peripheral start service descovery

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //NSLog(@"Did connect peripheral %@", peripheral.name);
    [self updateConsole:@"Connected!"];
    self.state = CONNECTED;
    [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    // Sets the peripheral delegate
    [self.peripheral setDelegate:self];
   
        [self.peripheral discoverServices:@[ViewController.uartServiceUUID]];
    // Activate buttons
    [self.vrmsButton setEnabled:YES];
    [self.currentButton setEnabled:YES];
    [self.powerButton setEnabled:YES];
    [self.fileTransferButton setEnabled:YES];
    [self.emailButton setEnabled:YES];

}

// 9,10  Discover Services found correct service
- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        //NSLog(@"Error discovering services: %@", error);
        [self updateConsole:@"Error Discovering Services"];

        return;
    }
    //NSLog(@"Searching services: %@", error);
     [self updateConsole:@"Searching services"];
    for (CBService *s in [peripheral services])
    {
        if ([s.UUID isEqual:ViewController.uartServiceUUID])
        {
            //NSLog(@"Found correct service");
            [self updateConsole:@"Found service"];
            self.uartService = s;
            
            [self.peripheral discoverCharacteristics:@[ViewController.txCharacteristicUUID, ViewController.rxCharacteristicUUID] forService:self.uartService];
        }
    }
}
//11,12 y 13 Discover Characteristics
- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        [self updateConsole:@"Error Discovering characteristics"];
       // NSLog(@"Error discovering characteristics: %@", error);
        return;
    }
    //NSLog(@"DidDiscoverCharacteristicsForServices");
    for (CBCharacteristic *c in [service characteristics])
    {
        if ([c.UUID isEqual:self.class.rxCharacteristicUUID])
        {
            //NSLog(@"Found RX characteristic")
            [self updateConsole:@"Found RX characteristic"];
            self.rxCharacteristic = c;     // store rx charactistici found in rxCharacteristic variable for later use
            [self.peripheral setNotifyValue:YES forCharacteristic:c];
        }
        else if ([c.UUID isEqual:self.class.txCharacteristicUUID])
        {
            //NSLog(@"Found TX characteristic");
            [self updateConsole:@"Found TX characteristic"];
            self.txCharacteristic = c;  //store tx characteristicin variable for later use
        }
    }
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    //NSLog(@"Did disconnect peripheral %@", peripheral.name);
    [self updateConsole:@"Disconnected peripheral"];
    self.state = IDLE;
    [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    // De activate buttons
    [self.vrmsButton setEnabled:NO];
    [self.currentButton setEnabled:NO];
    [self.powerButton setEnabled:NO];
    [self.fileTransferButton setEnabled:NO];
    [self.emailButton setEnabled:NO];
   

}

// Update Value for Characteristic
- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error receiving notification for characteristic %@: %@", characteristic, error);
        return;
    }
    
    if (characteristic == self.rxCharacteristic)
    {
        
        NSString *string = [NSString stringWithUTF8String:[[characteristic value] bytes]];
        //NSLog(@"Data: %@",string);

        //[self updateConsole:string];  // update console
        if ([lastcommand isEqualToString:@"r"])
        {
            recordCounter++;
            self.console.text=[NSString stringWithFormat:@"Packet:%d\n",recordCounter];
            [self writeRecord:string]; // Request another read
        }
        if ([lastcommand isEqualToString:@"v"])
        {
            self.console.text=[NSString stringWithFormat:@"%@\n",string];
        }
        if ([lastcommand isEqualToString:@"i"])
        {
            self.console.text=[NSString stringWithFormat:@"%@\n",string];
        }
        if ([lastcommand isEqualToString:@"p"])
        {
            self.console.text=[NSString stringWithFormat:@"%@\n",string];
        }

    }

    if ([lastcommand isEqualToString:@"r"])
      [self writeString:@"r"]; // Request another read
    /*
     The reading will stop when the command r replies nothing
     then will be no event to read
     */
  }

//Write Characteristic
- (void) writeString:(NSString *) string
{
    NSData *data = [NSData dataWithBytes:string.UTF8String length:string.length];
    if ((self.txCharacteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) != 0)
    {
        [self.peripheral writeValue:data forCharacteristic:self.txCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
    else if ((self.txCharacteristic.properties & CBCharacteristicPropertyWrite) != 0)
    {
        [self.peripheral writeValue:data forCharacteristic:self.txCharacteristic type:CBCharacteristicWriteWithResponse];
    }
    else
    {
        [self updateConsole:@"No write property on TX characteristic"];
        //NSLog(@"No write property on TX characteristic, %d.", self.txCharacteristic.properties);
    }
}
// File Save
-(void) writeRecord:(NSString *) string
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"mytextfile.txt"];
    
    // create if needed
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]){
        [[NSData data] writeToFile:path atomically:YES];
    }
    
    // append
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
    [handle truncateFileAtOffset:[handle seekToEndOfFile]];
    [handle writeData:[[string mutableCopy] dataUsingEncoding:NSUnicodeStringEncoding]];
}
- (void) deleteFile
{
    NSString *docPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"mytextfile.txt"];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
}

- (IBAction)fileTransferButtonPressed:(id)sender {
    //NSLog(@"Write Button Pressed");
    [self writeString:@"o"];
    [self writeString:@"r"];
    lastcommand=@"r";
    [self deleteFile];
    recordCounter=0;
    self.console.text=@"";  // Clear Console
}
- (IBAction)vrmsButtonPressed:(id)sender {
    [self writeString:@"v"];
    self.console.text=@"";  // Clear Console
    lastcommand=@"v";
}

- (IBAction)currenButtonPressed:(id)sender {
    [self writeString:@"i"];
    self.console.text=@"";  // Clear Console
    lastcommand=@"i";
}

- (IBAction)powerButtonPressed:(id)sender {
    [self writeString:@"p"];
    self.console.text=@"";  // Clear Console
    lastcommand=@"p";
}
- (void) updateConsole:(NSString *)string {
  [self.console setText:[NSString stringWithFormat:@"%@%@\r\n",self.console.text,string]];
}
/*
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
[[UINavigationBar appearance] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
}
*/
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result {
   // UIImage *backgroundImage = [UIImage imageNamed:@"Navigation Bar"];
   // [[UINavigationBar appearance] setBackgroundImage:backgroundImage forBarMetrics:UIBarMetricsDefault];
  //  [[UINavigationBar appearance] setBarTintColor:[UIColor blueColor]];
  //    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
   // [self dismissViewControllerAnimated:YES completion:nil];

}
- (IBAction)emailFileLogButtonPressed:(id)sender {
    if ([MFMailComposeViewController canSendMail]) {
        
        fileManager *files = [[fileManager alloc] init];

       // [[UINavigationBar appearance] setBarTintColor:[UIColor blueColor]];
       //  [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

        //[self presentViewController:messageComposer animated:YES completion:nil];
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
        shadow.shadowOffset = CGSizeMake(0, 1);
        [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                               [UIColor whiteColor], NSForegroundColorAttributeName,
                                                               shadow, NSShadowAttributeName,
                                                               [UIFont fontWithName:@"HelveticaNeue" size:21.0], NSFontAttributeName, nil]];
         MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        [[picker navigationBar] setTintColor:[UIColor blackColor]];
        //[[UINavigationBar appearance] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        
        //[picker.navigationBar setTintColor:[UIColor yellowColor]];
        //[picker.navigationBar setBackgroundColor:[UIColor orangeColor]];

        //[[UINavigationBar appearanceWhenContainedIn:[picker class], nil]
        // setBarTintColor:[UIColor colorWithRed:54./255 green:165./255 blue:53./255 alpha:1]];

       // //
        ///[[UINavigationBar appearance] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        [picker.navigationBar setTranslucent:NO];
        [picker.navigationBar setBarTintColor:[UIColor blueColor]];
         picker.navigationBar.barTintColor = [UIColor greenColor];
         [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
        [picker.navigationBar setTintColor:[UIColor yellowColor]];
        [self.navigationController.navigationBar setTranslucent:NO];
        //[self.navigationController.navigationBar setBarTintColor:[UIColor blackColor]];
        //[[UINavigationBar appearance] setBarTintColor:[UIColor greenColor]];
        [self presentViewController:picker animated:YES completion:nil];

        [picker setSubject:@"QeMeter"];

        NSString *mio;
        NSString *ruta;
        mio=[files GetDocumentDirectory];
        ruta=[mio stringByAppendingPathComponent:@"mytextfile.txt"];
        
        NSData *myData = [NSData dataWithContentsOfFile:ruta];
        [picker addAttachmentData:myData mimeType:@""
                         fileName:@"mytextfile.txt"];
        
        // Fill out the email body text.
        NSString *emailBody = @"Temperature and humidity log";
        [picker setMessageBody:emailBody isHTML:NO];
        
        // Present the mail composition interface.
        [self presentViewController:picker animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                        message:@"Your device doesn't support the composer sheet or you haven't enter email credentials"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}


// mail composer controller method
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            [self updateConsole:@"Mail cancelled: you cancelled the operation and no email message was queued."];
            //NSLog(@"Mail cancelled: you cancelled the operation and no email message was queued.");
            break;
        case MFMailComposeResultSaved:
            [self updateConsole:@"Mail saved: you saved the email message in the drafts folder."];
            //NSLog(@"Mail saved: you saved the email message in the drafts folder.");
            break;
        case MFMailComposeResultSent:
            [self updateConsole:@"Mail send: the email message is queued in the outbox. It is ready to send."];
            //NSLog(@"Mail send: the email message is queued in the outbox. It is ready to send.");
            break;
        case MFMailComposeResultFailed:
            [self updateConsole:@"Mail failed: the email message was not saved or queued, possibly due to an error."];
            //NSLog(@"Mail failed: the email message was not saved or queued, possibly due to an error.");
            break;
        default:
            [self updateConsole:@"Mail not sent."];
            //NSLog(@"Mail not sent.");
            break;
    }
    
    // Remove the mail view
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
