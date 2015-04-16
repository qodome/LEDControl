//
//  ViewController.h
//  LEDControl
//
//  Created by Ting Wang on 1/7/15.
//  Copyright (c) 2015 Ting Wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEUtility.h"

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (weak, nonatomic) IBOutlet UISlider *warm1;
@property (weak, nonatomic) IBOutlet UISlider *warm2;
@property (weak, nonatomic) IBOutlet UISlider *warm3;
@property (weak, nonatomic) IBOutlet UISlider *warm4;
@property (weak, nonatomic) IBOutlet UITextField *connStatus;


@end

