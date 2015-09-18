//
//  ViewController.h
//  JSIMWebrtcOverMQTT
//
//  Created by WHC on 15/9/17.
//  Copyright (c) 2015年 weaver software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClientUser.h"
#import "ChatMessage.h"
#import "ServerConfig.h"
#import "ConfigSet.h"

@interface ViewController : UIViewController


@property (strong ,nonatomic)ClientUser     *mySelf;


@property (strong ,nonatomic)ClientUser     *otherUser;



@property (weak, nonatomic) IBOutlet UISegmentedControl *chooseUserSeg;

@property (weak, nonatomic) IBOutlet UITextField *myIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *otherIDTextField;

@property (weak, nonatomic) IBOutlet UITextField *iceServerTextField;

@property (weak, nonatomic) IBOutlet UITextField *mqttServerTextField;


- (IBAction)chooseMyID:(id)sender;
- (IBAction)chooseUID:(id)sender;

- (IBAction)chooseICEServer:(id)sender;
- (IBAction)chooseMqttServer:(id)sender;
- (IBAction)chooseUser:(id)sender;

/**
 *  连接前发布消息
 *
 *  @param sender <#sender description#>
 */
- (IBAction)warmUpAction:(id)sender;
/**
 *  发起连接
 *
 *  @param sender <#sender description#>
 */
- (IBAction)connectAction:(id)sender;
@end

