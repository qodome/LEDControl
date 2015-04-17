//
//  ViewController.m
//  LEDControl
//
//  Created by Ting Wang on 1/7/15.
//  Copyright (c) 2015 Ting Wang. All rights reserved.
//

#import "ViewController.h"
#import <iOS-Color-Picker/FCColorPickerViewController.h>

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate, FCColorPickerViewControllerDelegate>
{
    UInt8 rgba[4][4];
}

@property (nonatomic, strong) CBPeripheral *p;
@property (strong, nonatomic) CBCentralManager *central;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic) UInt8 colorIdx;
@property (weak, nonatomic) IBOutlet UISwitch *switch1;
@property (weak, nonatomic) IBOutlet UISwitch *switch2;
@property (weak, nonatomic) IBOutlet UISwitch *switch3;
@property (weak, nonatomic) IBOutlet UISwitch *switch4;
@property (weak, nonatomic) IBOutlet UITextField *sampleColor1;
@property (weak, nonatomic) IBOutlet UITextField *sampleColor2;
@property (weak, nonatomic) IBOutlet UITextField *sampleColor3;
@property (weak, nonatomic) IBOutlet UITextField *sampleColor4;
@property (weak, nonatomic) IBOutlet UITextField *ssid;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UITextField *wifiStatus;
@property (weak, nonatomic) IBOutlet UITextField *peerStatus;
@property (nonatomic) UInt8 initDone;
@property (nonatomic) NSString *ssidStr;
@property (nonatomic) NSString *passwordStr;
@property (nonatomic) int setWIFI;

@property (strong, nonatomic) NSThread *workingThread;
@property (nonatomic) int iQoConnected;

- (void)sendUpdate:(UInt8)r G:(UInt8)g B:(UInt8)b W:(UInt8)w;
- (void)doTask;

@end

@implementation ViewController

- (void)viewDidLoad {
    NSData *d;
    UInt8 b[4];
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.central = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    self.p = nil;
    
    // Settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"COLOR1"] != nil) {
        d = [defaults objectForKey:@"COLOR1"];
        [d getBytes:b length:4];
        self.sampleColor1.backgroundColor = [[UIColor alloc] initWithRed:((CGFloat)b[0]/255.0) green:((CGFloat)b[1]/255.0) blue:((CGFloat)b[2]/255.0) alpha:((CGFloat)b[3]/255.0)];
        rgba[0][0] = b[0];
        rgba[0][1] = b[1];
        rgba[0][2] = b[2];
    }
    if ([defaults objectForKey:@"COLOR2"] != nil) {
        d = [defaults objectForKey:@"COLOR2"];
        [d getBytes:b length:4];
        self.sampleColor2.backgroundColor = [[UIColor alloc] initWithRed:((CGFloat)b[0]/255.0) green:((CGFloat)b[1]/255.0) blue:((CGFloat)b[2]/255.0) alpha:((CGFloat)b[3]/255.0)];
        rgba[1][0] = b[0];
        rgba[1][1] = b[1];
        rgba[1][2] = b[2];
    }
    if ([defaults objectForKey:@"COLOR3"] != nil) {
        d = [defaults objectForKey:@"COLOR3"];
        [d getBytes:b length:4];
        self.sampleColor3.backgroundColor = [[UIColor alloc] initWithRed:((CGFloat)b[0]/255.0) green:((CGFloat)b[1]/255.0) blue:((CGFloat)b[2]/255.0) alpha:((CGFloat)b[3]/255.0)];
        rgba[2][0] = b[0];
        rgba[2][1] = b[1];
        rgba[2][2] = b[2];
    }
    if ([defaults objectForKey:@"COLOR4"] != nil) {
        d = [defaults objectForKey:@"COLOR4"];
        [d getBytes:b length:4];
        self.sampleColor4.backgroundColor = [[UIColor alloc] initWithRed:((CGFloat)b[0]/255.0) green:((CGFloat)b[1]/255.0) blue:((CGFloat)b[2]/255.0) alpha:((CGFloat)b[3]/255.0)];
        rgba[3][0] = b[0];
        rgba[3][1] = b[1];
        rgba[3][2] = b[2];
    }

    self.initDone = 0x55;
    self.iQoConnected = 0;
    self.setWIFI = 0;
    
    self.workingThread = [[NSThread alloc] initWithTarget:self selector:@selector(doTask) object:nil];
    [self.workingThread start];
}

- (void)viewWillAppear:(BOOL)animated {
 
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)doTask
{
    int tickCount = 0;
    uint8_t cmd[1];
    
    while (1) {
        sleep(1);
        if (self.iQoConnected == 1) {
            if (tickCount == 0) {
                [BLEUtility readCharacteristic:self.p sUUID:@"90D0" cUUID:@"9004"];
            } else if (tickCount == 1) {
                [BLEUtility readCharacteristic:self.p sUUID:@"90D0" cUUID:@"9005"];
            }
            tickCount++;
            if (tickCount >= 2) {
                tickCount = 0;
            }
            if (self.setWIFI == 1) {
                self.setWIFI = 0;
                cmd[0] = 0x02;
                NSData *cmdData = [NSData dataWithBytes:cmd length:1];
                NSMutableData *completeData = [cmdData mutableCopy];
                [completeData appendData:[self.ssidStr dataUsingEncoding:NSUTF8StringEncoding]];
                [BLEUtility writeCharacteristic:self.p sUUID:@"90D0" cUUID:@"9002" data:completeData];
                
                sleep(2);
                
                cmd[0] = 0x03;
                cmdData = [NSData dataWithBytes:cmd length:1];
                completeData = [cmdData mutableCopy];
                [completeData appendData:[self.passwordStr dataUsingEncoding:NSUTF8StringEncoding]];
                [BLEUtility writeCharacteristic:self.p sUUID:@"90D0" cUUID:@"9002" data:completeData];
            }
        }
    }
}

- (void)sendUpdate:(UInt8)r G:(UInt8)g B:(UInt8)b W:(UInt8)w {
    uint8_t settings[4] = {0};
    
    settings[0] = r;
    settings[1] = g;
    settings[2] = b;
    settings[3] = w;
    NSLog(@"Update: %d %d %d %d\n", r, g, b, w);
    if (self.p != nil) {
        [BLEUtility writeCharacteristic:self.p sUUID:@"2014" cUUID:@"1212" data:[NSData dataWithBytes:settings length:4]];
    }
}

- (IBAction)switch1:(id)sender {
    if (self.switch1.on == true) {
        self.switch2.on = false;
        self.switch3.on = false;
        self.switch4.on = false;
        [self sendUpdate:rgba[0][0] G:rgba[0][1] B:rgba[0][2] W:rgba[0][3]];
    } else {
        [self sendUpdate:0 G:0 B:0 W:0];
    }
}

- (IBAction)switch2:(id)sender {
    if (self.switch2.on == true) {
        self.switch1.on = false;
        self.switch3.on = false;
        self.switch4.on = false;
        [self sendUpdate:rgba[1][0] G:rgba[1][1] B:rgba[1][2] W:rgba[1][3]];
    } else {
        [self sendUpdate:0 G:0 B:0 W:0];
    }
}

- (IBAction)switch3:(id)sender {
    if (self.switch3.on == true) {
        self.switch1.on = false;
        self.switch2.on = false;
        self.switch4.on = false;
        [self sendUpdate:rgba[2][0] G:rgba[2][1] B:rgba[2][2] W:rgba[2][3]];
    } else {
        [self sendUpdate:0 G:0 B:0 W:0];
    }
}

- (IBAction)switch4:(id)sender {
    if (self.switch4.on == true) {
        self.switch1.on = false;
        self.switch2.on = false;
        self.switch3.on = false;
        [self sendUpdate:rgba[3][0] G:rgba[3][1] B:rgba[3][2] W:rgba[3][3]];
    } else {
        [self sendUpdate:0 G:0 B:0 W:0];
    }
}

-(IBAction)chooseColor1:(id)sender {
    self.colorIdx = 0;
    FCColorPickerViewController *colorPicker = [FCColorPickerViewController colorPicker];
    colorPicker.color = self.color;
    colorPicker.delegate = self;
    
    [colorPicker setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentViewController:colorPicker animated:YES completion:nil];
}

-(IBAction)chooseColor2:(id)sender {
    self.colorIdx = 1;
    FCColorPickerViewController *colorPicker = [FCColorPickerViewController colorPicker];
    colorPicker.color = self.color;
    colorPicker.delegate = self;
    
    [colorPicker setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentViewController:colorPicker animated:YES completion:nil];
}

-(IBAction)chooseColor3:(id)sender {
    self.colorIdx = 2;
    FCColorPickerViewController *colorPicker = [FCColorPickerViewController colorPicker];
    colorPicker.color = self.color;
    colorPicker.delegate = self;
    
    [colorPicker setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentViewController:colorPicker animated:YES completion:nil];
}

-(IBAction)chooseColor4:(id)sender {
    self.colorIdx = 3;
    FCColorPickerViewController *colorPicker = [FCColorPickerViewController colorPicker];
    colorPicker.color = self.color;
    colorPicker.delegate = self;
    
    [colorPicker setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentViewController:colorPicker animated:YES completion:nil];
}

- (IBAction)setWarm1:(UISlider *)sender {
    if (self.initDone == 0x55) {
        rgba[0][3] = (UInt8)([sender value] * 255.0);
        
        if (self.switch1.on == true) {
            [self sendUpdate:rgba[0][0] G:rgba[0][1] B:rgba[0][2] W:rgba[0][3]];
        }
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        UInt8 saveData[4];
        saveData[0] = rgba[0][3];
        NSData *savePtr = [[NSData alloc] initWithBytes:saveData length:4];
        [defaults setObject:savePtr forKey:@"WARM1"];
        [defaults synchronize];
    } else {
        NSData *d;
        UInt8 b[4];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults objectForKey:@"WARM1"] != nil) {
            d = [defaults objectForKey:@"WARM1"];
            [d getBytes:b length:4];
            [sender setValue:((CGFloat)b[0]/255.0) animated:true];
            rgba[0][3] = b[0];
        }
    }
}
- (IBAction)setWarm2:(UISlider *)sender {
    if (self.initDone == 0x55) {
        rgba[1][3] = (UInt8)([sender value] * 255.0);
        
        if (self.switch2.on == true) {
            [self sendUpdate:rgba[1][0] G:rgba[1][1] B:rgba[1][2] W:rgba[1][3]];
        }
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        UInt8 saveData[4];
        saveData[0] = rgba[1][3];
        NSData *savePtr = [[NSData alloc] initWithBytes:saveData length:4];
        [defaults setObject:savePtr forKey:@"WARM2"];
        [defaults synchronize];
    } else {
        NSData *d;
        UInt8 b[4];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults objectForKey:@"WARM2"] != nil) {
            d = [defaults objectForKey:@"WARM2"];
            [d getBytes:b length:4];
            [sender setValue:((CGFloat)b[0]/255.0) animated:true];
            rgba[1][3] = b[0];
        }
    }
}
- (IBAction)setWarm3:(UISlider *)sender {
    if (self.initDone == 0x55) {
        rgba[2][3] = (UInt8)([sender value] * 255.0);
        
        if (self.switch3.on == true) {
            [self sendUpdate:rgba[2][0] G:rgba[2][1] B:rgba[2][2] W:rgba[2][3]];
        }
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        UInt8 saveData[4];
        saveData[0] = rgba[2][3];
        NSData *savePtr = [[NSData alloc] initWithBytes:saveData length:4];
        [defaults setObject:savePtr forKey:@"WARM3"];
        [defaults synchronize];
    } else {
        NSData *d;
        UInt8 b[4];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults objectForKey:@"WARM3"] != nil) {
            d = [defaults objectForKey:@"WARM3"];
            [d getBytes:b length:4];
            [sender setValue:((CGFloat)b[0]/255.0) animated:true];
            rgba[2][3] = b[0];
        }
    }
}
- (IBAction)setWarm4:(UISlider *)sender {
    if (self.initDone == 0x55) {
        rgba[3][3] = (UInt8)([sender value] * 255.0);
        
        if (self.switch4.on == true) {
            [self sendUpdate:rgba[3][0] G:rgba[3][1] B:rgba[3][2] W:rgba[3][3]];
        }
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        UInt8 saveData[4];
        saveData[0] = rgba[3][3];
        NSData *savePtr = [[NSData alloc] initWithBytes:saveData length:4];
        [defaults setObject:savePtr forKey:@"WARM4"];
        [defaults synchronize];
    } else {
        NSData *d;
        UInt8 b[4];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults objectForKey:@"WARM4"] != nil) {
            d = [defaults objectForKey:@"WARM4"];
            [d getBytes:b length:4];
            [sender setValue:((CGFloat)b[0]/255.0) animated:true];
            rgba[3][3] = b[0];
        }
    }
}

- (IBAction)setWiFiCredential:(UIButton *)sender {
    NSLog(@"set credential!");
    
    self.ssidStr = self.ssid.text;
    self.passwordStr = self.password.text;
    self.setWIFI = 1;
}

- (IBAction)resetWiFi:(id)sender {
    uint8_t cmd[1] = {0x04};
    [BLEUtility writeCharacteristic:self.p sUUID:@"90D0" cUUID:@"9002" data:[NSData dataWithBytes:cmd length:1]];
}

- (IBAction)connectPeer:(id)sender {
    uint8_t cmd[1] = {0x00};
    [BLEUtility writeCharacteristic:self.p sUUID:@"90D0" cUUID:@"9002" data:[NSData dataWithBytes:cmd length:1]];
}

#pragma mark - FCColorPickerViewControllerDelegate Methods

-(void)colorPickerViewController:(FCColorPickerViewController *)colorPicker didSelectColor:(UIColor *)color {
    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    rgba[self.colorIdx][0] = (UInt8)(r * 255.0);
    rgba[self.colorIdx][1] = (UInt8)(g * 255.0);
    rgba[self.colorIdx][2] = (UInt8)(b * 255.0);
    rgba[self.colorIdx][3] = 0;
    NSLog(@"%d %d %d\n", rgba[self.colorIdx][0], rgba[self.colorIdx][1], rgba[self.colorIdx][2]);
    self.color = color;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UInt8 saveData[4];
    saveData[0] = rgba[self.colorIdx][0];
    saveData[1] = rgba[self.colorIdx][1];
    saveData[2] = rgba[self.colorIdx][2];
    saveData[3] = (UInt8)(a * 255.0);
    NSData *savePtr = [[NSData alloc] initWithBytes:saveData length:4];
    
    if (self.colorIdx == 0) {
        self.sampleColor1.backgroundColor = color;
        [defaults setObject:savePtr forKey:@"COLOR1"];
    } else if (self.colorIdx == 1) {
        self.sampleColor2.backgroundColor = color;
        [defaults setObject:savePtr forKey:@"COLOR2"];
    } else if (self.colorIdx == 2) {
        self.sampleColor3.backgroundColor = color;
        [defaults setObject:savePtr forKey:@"COLOR3"];
    } else if (self.colorIdx == 3) {
        self.sampleColor4.backgroundColor = color;
        [defaults setObject:savePtr forKey:@"COLOR4"];
    }
    [defaults synchronize];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)colorPickerViewControllerDidCancel:(FCColorPickerViewController *)colorPicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CBCentralManagerDelegate

// First time invoke at app launch
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        NSLog(@"Scanning...");
        [central scanForPeripheralsWithServices:nil options:nil];
    }
}

// Invoke when resumed app
- (void)centralManager:(CBCentralManager *)central
      willRestoreState:(NSDictionary *)state
{
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if ([peripheral.name isEqualToString:@"iQo"]) {
        NSLog(@"Found iQo, try to connect with that");
        [central connectPeripheral:peripheral options:nil];
        self.p = peripheral;
        [central stopScan];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Disconnected!");
    self.iQoConnected = 0;
    [self.connStatus setText:@"Disconnected"];
    [central connectPeripheral:self.p options:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect");
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"connected");
    peripheral.delegate = self;
    [peripheral discoverServices:@[[CBUUID UUIDWithString:@"2014"], [CBUUID UUIDWithString:@"90D0"]]];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (!error) {
        NSLog(@"didDiscoverServices");
        for (CBService *service in peripheral.services) {
            NSLog(@"%@", service.UUID);
            [peripheral discoverCharacteristics:nil forService:service];
        }
    } else {
        NSLog(@"discover service error");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        self.iQoConnected = 1;
        NSLog(@"didDiscoverCharacteristicsForService");
        for (CBCharacteristic *chr in service.characteristics) {
            NSLog(@"%@", chr.UUID);
            [self.connStatus setText:@"Connected"];
        }
    } else {
        NSLog(@"discover char for service error");
    }
}

 - (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"write to char failed");
        NSLog(@"%@", error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"read char failed");
        NSLog(@"%@", error);
    } else {
        if ([[BLEUtility CBUUIDToString:characteristic.UUID] isEqualToString:@"9004"]) {
            if ([characteristic.value length] > 1) {
                NSString *s = @"IP Addr: ";
                self.wifiStatus.text = [s stringByAppendingString:[[NSString alloc] initWithData:characteristic.value encoding:NSASCIIStringEncoding]];
            } else {
                if (((char *)[characteristic.value bytes])[0] == 0) {
                    self.wifiStatus.text = @"Not started";
                } else if (((char *)[characteristic.value bytes])[0] == 1) {
                    self.wifiStatus.text = @"Standby";
                }
            }
        } else if ([[BLEUtility CBUUIDToString:characteristic.UUID] isEqualToString:@"9005"]) {
            if (((char *)[characteristic.value bytes])[0] == 0) {
                self.peerStatus.text = @"Not connected";
            } else if (((char *)[characteristic.value bytes])[0] == 1) {
                self.peerStatus.text = @"Service discovered";
            } else if (((char *)[characteristic.value bytes])[0] == 2) {
                self.peerStatus.text = @"Service enabled";
            } else if (((char *)[characteristic.value bytes])[0] == 3) {
                self.peerStatus.text = @"Got ACC notify";
            }
        }
    }
}

@end
