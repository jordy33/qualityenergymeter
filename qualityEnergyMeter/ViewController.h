//
//  ViewController.h
//  qualityEnergyMeter
//
//  Created by Jorge Macias on 5/6/14.
//  Copyright (c) 2014 Diincasa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <MessageUI/MessageUI.h>

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate,MFMailComposeViewControllerDelegate>

 @property (nonatomic, strong) CBCentralManager *manager;
 @property (nonatomic, strong) NSMutableData *data;
 @property (nonatomic,strong) CBPeripheral *peripheral;
 @property (nonatomic) CBPeripheralState state;
 @property (nonatomic,strong) CBCharacteristic *characteristic;
 @property (weak, nonatomic) IBOutlet UITextView *console;
 @property (weak, nonatomic) IBOutlet UIButton *connectButton;
 @property CBService *uartService;  //pointer to discovered service
 @property CBCharacteristic *rxCharacteristic;  //pointer to  discovered rx characteristic
 @property CBCharacteristic *txCharacteristic;  //pointer to discovered tx characteristic

+ (CBUUID *) rxCharacteristicUUID;
+ (CBUUID *) txCharacteristicUUID;
+ (CBUUID *) uartServiceUUID;


- (void) deleteFile;
- (void) writeString:(NSString *) string;
- (void) writeRecord:(NSString *) string;
- (void) updateConsole:(NSString *) string;
@property (weak, nonatomic) IBOutlet UIButton *vrmsButton;
@property (weak, nonatomic) IBOutlet UIButton *currentButton;
@property (weak, nonatomic) IBOutlet UIButton *fileTransferButton;
@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@property (weak, nonatomic) IBOutlet UIButton *powerButton;

- (IBAction)connectButtonPressed:(id)sender;
- (IBAction)fileTransferButtonPressed:(id)sender;
- (IBAction)emailFileLogButtonPressed:(id)sender;
- (IBAction)vrmsButtonPressed:(id)sender;
- (IBAction)currenButtonPressed:(id)sender;
- (IBAction)powerButtonPressed:(id)sender;
@end

