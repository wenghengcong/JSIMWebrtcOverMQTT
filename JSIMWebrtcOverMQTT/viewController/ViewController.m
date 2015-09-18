//
//  ViewController.m
//  JSIMWebrtcOverMQTT
//
//  Created by WHC on 15/9/17.
//  Copyright (c) 2015年 weaver software. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()<UIActionSheetDelegate>

@property (strong ,nonatomic)UIActionSheet      *chooseMyIDAS;
@property (strong ,nonatomic)UIActionSheet      *chooseOtherIDAS;
@property (strong ,nonatomic)UIActionSheet      *chooseICEAS;
@property (strong ,nonatomic)UIActionSheet      *chooseMQTTAS;


@property (strong ,nonatomic)ServerConfig       *stunServerConfig;
@property (strong ,nonatomic)ServerConfig       *turnerverConfig;
@property (strong ,nonatomic)ServerConfig       *mqttServerConfig;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initAndAlloc];
}


#pragma mark- init property
- (void)initAndAlloc {
    
    self.mySelf = [[ClientUser alloc]init];
    self.otherUser = [[ClientUser alloc]init];
    
    self.stunServerConfig = [[ServerConfig alloc]init];
    self.turnerverConfig = [[ServerConfig alloc]init];
    self.mqttServerConfig = [[ServerConfig alloc]init];
    
    self.chooseUserSeg.selectedSegmentIndex = 0;
    [self chooseUser:self.chooseUserSeg];

}


- (IBAction)warmUpAction:(id)sender {
    
    
}

- (IBAction)connectAction:(id)sender {
    
    
}

#pragma mark- 配置

- (IBAction)chooseMyID:(id)sender {
    
    self.chooseMyIDAS = [[UIActionSheet alloc]initWithTitle:@"选择你的ID" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:UserAliceName,UserBobName, nil];
    [self.chooseMyIDAS showInView:self.view];
    
}

- (IBAction)chooseUID:(id)sender {
    
    self.chooseOtherIDAS = [[UIActionSheet alloc]initWithTitle:@"选择对方的ID" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:UserAliceName,UserBobName, nil];
    [self.chooseOtherIDAS showInView:self.view];
    
}

- (IBAction)chooseICEServer:(id)sender {
    
    self.chooseICEAS = [[UIActionSheet alloc]initWithTitle:@"选择ICE服务器" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:SERVERNAME_DNJ,SERVERNAME_OTHER, nil];
    [self.chooseICEAS showInView:self.view];
    
}

- (IBAction)chooseMqttServer:(id)sender {
    
    self.chooseMQTTAS = [[UIActionSheet alloc]initWithTitle:@"选择MQTT服务器" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:SERVERNAME_DNJ,SERVERNAME_IBM,SERVERNAME_MOSQUITTOR, nil];
    [self.chooseMQTTAS showInView:self.view];
}

- (IBAction)chooseUser:(id)sender {
    
    UISegmentedControl *segC = (UISegmentedControl *)sender;
    if (segC.selectedSegmentIndex == 0) {
        
        self.mySelf.userName = UserAliceName;
        self.otherUser.userName = UserBobName;
        
        self.stunServerConfig.serverName = SERVERNAME_DNJ;
        self.stunServerConfig.url = ICESERVER_DNJ_STUN_HOST;
        self.turnerverConfig.url = ICESERVER_DNJ_TURN_HOST;
        self.turnerverConfig.username = ICESERVER_DNJ_TURN_USERNAME;
        self.turnerverConfig.credential = ICESERVER_DNJ_TURN_CREDENTIAL;
        
        self.mqttServerConfig.serverName = SERVERNAME_IBM;
        self.mqttServerConfig.url = MQTTSERVER_IBMHOST;
        self.mqttServerConfig.port = MQTTSERVER_IBMPORT;
        
    }else{
        self.mySelf.userName = UserBobName;
        self.otherUser.userName = UserAliceName;
        
        self.stunServerConfig.serverName = SERVERNAME_DNJ;
        self.stunServerConfig.url = ICESERVER_DNJ_STUN_HOST;
        self.turnerverConfig.url = ICESERVER_DNJ_TURN_HOST;
        self.turnerverConfig.username = ICESERVER_DNJ_TURN_USERNAME;
        self.turnerverConfig.credential = ICESERVER_DNJ_TURN_CREDENTIAL;
        
        self.mqttServerConfig.serverName = SERVERNAME_IBM;
        self.mqttServerConfig.url = MQTTSERVER_IBMHOST;
        self.mqttServerConfig.port = MQTTSERVER_IBMPORT;
        
    }
    
    [self updateTextFieldContent];
    
}

- (void)updateTextFieldContent {
    
    self.myIDTextField.text = self.mySelf.userName;
    self.otherIDTextField.text = self.otherUser.userName;
    self.mqttServerTextField.text = self.mqttServerConfig.serverName;
    self.iceServerTextField.text = self.stunServerConfig.serverName;
}

#pragma mark- action sheet delegate 

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (actionSheet == self.chooseMyIDAS) {
        
        self.mySelf.userName = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        if (buttonIndex == 2) {
            self.mySelf.userName = [actionSheet buttonTitleAtIndex:0];
        }

    }else if (actionSheet == self.chooseOtherIDAS){
        
        self.otherUser.userName = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        if (buttonIndex==2) {
            self.otherUser.userName = [actionSheet buttonTitleAtIndex:1];
        }

    }else if (actionSheet == self.chooseICEAS){
        
        self.stunServerConfig.serverName = [actionSheet buttonTitleAtIndex:buttonIndex];

        if (buttonIndex == 0) {
            
            self.stunServerConfig.url = ICESERVER_DNJ_STUN_HOST;
            
            self.turnerverConfig.url = ICESERVER_DNJ_TURN_HOST;
            self.turnerverConfig.username = ICESERVER_DNJ_TURN_USERNAME;
            self.turnerverConfig.credential = ICESERVER_DNJ_TURN_CREDENTIAL;
            
        }else if(buttonIndex == 1){
            //no
            
        }else if (buttonIndex == 2){
            
            self.stunServerConfig.url = ICESERVER_DNJ_STUN_HOST;
            
            self.turnerverConfig.url = ICESERVER_DNJ_TURN_HOST;
            self.turnerverConfig.username = ICESERVER_DNJ_TURN_USERNAME;
            self.turnerverConfig.credential = ICESERVER_DNJ_TURN_CREDENTIAL;
            

        }
        
    }else if(actionSheet == self.chooseMQTTAS){
        
        self.mqttServerConfig.serverName = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        if (buttonIndex == 0) {
            self.mqttServerConfig.url = MQTTSERVER_DNJHOSt;
            self.mqttServerConfig.port = MQTTSERVER_DNJPORT;
        }else if(buttonIndex == 1){
            self.mqttServerConfig.url = MQTTSERVER_IBMHOST;
            self.mqttServerConfig.port = MQTTSERVER_IBMPORT;
            
        }else if (buttonIndex == 2){
            self.mqttServerConfig.url = MQTTSERVER_MOSQUITTOHOST;
            self.mqttServerConfig.port = MQTTSERVER_MOSQUITTOPORT;
            
        }else if(buttonIndex == 3){
            //默认
            self.mqttServerConfig.url = MQTTSERVER_DNJHOSt;
            self.mqttServerConfig.port = MQTTSERVER_DNJPORT;
        }
        
    }
    
    [self updateTextFieldContent];
    
}

@end
