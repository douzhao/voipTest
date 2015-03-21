//
//  ViewController.h
//  voipTest
//
//  Created by Dmitriy on 20.03.15.
//  Copyright (c) 2015 Dmitriy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *txtIP;
@property (strong, nonatomic) IBOutlet UITextField *txtPort;
@property (strong, nonatomic) IBOutlet UITextView *txtReceivedData;

@end

