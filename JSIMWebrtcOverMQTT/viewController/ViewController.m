//
//  ViewController.m
//  JSIMWebrtcOverMQTT
//
//  Created by WHC on 15/9/17.
//  Copyright (c) 2015年 weaver software. All rights reserved.
//

#import "ViewController.h"
#define TestConnectionMessContent @"测试mqtt连接"
#define ALERTVIEWCALLER     10
#define ALERTVIEWCALLEE     100

@interface ViewController ()<UIActionSheetDelegate>

@property (strong ,nonatomic)UIActionSheet      *chooseMyIDAS;
@property (strong ,nonatomic)UIActionSheet      *chooseOtherIDAS;
@property (strong ,nonatomic)UIActionSheet      *chooseICEAS;
@property (strong ,nonatomic)UIActionSheet      *chooseMQTTAS;


@property (strong ,nonatomic)ServerConfig       *stunServerConfig;
@property (strong ,nonatomic)ServerConfig       *turnerverConfig;
@property (strong ,nonatomic)ServerConfig       *mqttServerConfig;

@property (strong ,nonatomic)MQTTSessionTool        *mqttSessionTool;
@property (strong ,nonatomic)WebRTCTool             *webrtcTool;

@property (strong ,nonatomic)NSMutableArray         *queuedSignalingMessages;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initAndAlloc];
}


#pragma mark- init property
- (void)initAndAlloc {
    
    self.queuedSignalingMessages = [NSMutableArray array];
    
    self.mqttSessionTool = [[MQTTSessionTool alloc]init];
    self.webrtcTool = [[WebRTCTool alloc]init];
    self.webrtcTool.webDelegate = self;
    
    self.myIDTextField.delegate = self;
    self.otherIDTextField.delegate = self;
    self.iceServerTextField.delegate = self;
    self.mqttServerTextField.delegate = self;
    
    self.mySelf = [[ClientUser alloc]init];
    self.otherUser = [[ClientUser alloc]init];
    
    self.stunServerConfig = [[ServerConfig alloc]init];
    self.turnerverConfig = [[ServerConfig alloc]init];
    self.mqttServerConfig = [[ServerConfig alloc]init];
    
    self.chooseUserSeg.selectedSegmentIndex = 0;
    [self chooseUser:self.chooseUserSeg];
    [self updateICEServer];
}

- (void)updateICEServer {
    self.webrtcTool.stunServerConfig = self.stunServerConfig;
    self.webrtcTool.turnServerConfig = self.turnerverConfig;
}

- (void)updateMQTTSessionConnection {
    
    if (self.mqttSessionTool.mqttSession.status == MQTTSessionStatusConnected) {
//        [self.mqttSessionTool.mqttSession close];
//        [self.mqttSessionTool sessionConnectToHost:self.mqttServerConfig.url Port:[self.mqttServerConfig.port integerValue]];
    }else{
        [self.mqttSessionTool sessionConnectToHost:self.mqttServerConfig.url Port:[self.mqttServerConfig.port integerValue]];
    }
    [self.mqttSessionTool.mqttSession addObserver:self
                                       forKeyPath:@"status"
                                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                          context:nil];
    self.mqttSessionTool.mqttSession.delegate = self;
    self.webrtcTool.mqttSessionTool = self.mqttSessionTool;

}

- (void)updateMQTTSessionTopic {
    //先设置sub topic/pub topic
    
    if (self.mqttSessionTool.subTopic == nil) {
        //如果为空，就是第一次订阅
        self.mqttSessionTool.subTopic = self.mySelf.userName;
        self.mqttSessionTool.pubTopic = self.otherUser.userName;
        [self.mqttSessionTool subscriberTopic];
    }else if (self.mqttSessionTool.subTopic != self.mySelf.userName) {
        //如果当前订阅主题跟当前用户名不同，先取消订阅，再重新订阅
        [self.mqttSessionTool unSubscriberTopic];
        self.mqttSessionTool.subTopic = self.mySelf.userName;
        self.mqttSessionTool.pubTopic = self.otherUser.userName;
        [self.mqttSessionTool subscriberTopic];
    }else{
        //否则，订阅的主题相同
    }

}

#pragma mark- 按钮

- (IBAction)warmUpAction:(id)sender {
    [self.mqttSessionTool sendChatMessage:[self buildChatMessageWithContent:TestConnectionMessContent]];
//    [self.mqttSessionTool sendMessageWithString:TestConnectionMessContent];
}

- (IBAction)connectAction:(id)sender {
    
    NSString *toUserStr = [NSString stringWithFormat:@"向%@发起通话",self.otherUser.userName];
    UIAlertView *alertV = [[UIAlertView alloc]initWithTitle:@"发起通话" message:toUserStr delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    alertV.tag = ALERTVIEWCALLER;
    [alertV show];
    
}


#pragma mark- 消息处理

- (ChatMessage *)buildChatMessageWithContent:(NSString *)content{
    ChatMessage *mes = [[ChatMessage alloc]init];
    mes.mesID = 0;
    mes.fromUser = self.mySelf;
    mes.toUser = self.otherUser;
    mes.content = content;
    return mes;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{

    NSString *state = @"";
    switch (self.mqttSessionTool.mqttSession.status) {
        case MQTTSessionStatusCreated:
            state = @"MQTTSessionStatusCreated";
            break;
            
        case MQTTSessionStatusConnecting:
            state = @"MQTTSessionStatusConnecting";
            break;
            
        case MQTTSessionStatusConnected:
        {
            //连接上MQTT之后更新topic
            state = @"MQTTSessionStatusConnected";
            NSString *content = [NSString stringWithFormat:@"Session State-%@",state];
            [JSIMTool logOutContent:content];
            [self updateMQTTSessionTopic];
            break;
        }
            
        case MQTTSessionStatusDisconnecting:
            state = @"MQTTSessionStatusDisconnecting";
            break;
            
        case MQTTSessionStatusClosed:
        {
            state = @"MQTTSessionStatusClosed";
            NSString *content = [NSString stringWithFormat:@"Session State-%@",state];
            [JSIMTool logOutContent:content];
            break;
        }
            
        case MQTTSessionStatusError:
        {
            state = @"MQTTSessionStatusError";
            NSString *content = [NSString stringWithFormat:@"Session State-%@",state];
            [JSIMTool logOutContent:content];
            break;
        }
        default:
            break;
    }
    self.mqttStateLabel.text = state;

}



- (void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid{
    
    ChatMessage *mes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
//    NSString *messageStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSString *str = [NSString stringWithFormat:@"接受消息,主题：%@，内容：%@",topic,mes.content];
    [JSIMTool logOutContent:str];

    //测试连接
    if ([mes.content isEqualToString:TestConnectionMessContent]) {
        UIAlertView  *al = [[UIAlertView alloc]initWithTitle:@"测试连接成功" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定" ,nil];
        [al show];
    }
    
    //处理rtc通话过程
    NSDictionary *rtcDic = [self dictionaryWithJsonString:mes.content];
    
    if (rtcDic != nil) {
        NSString *type = rtcDic[@"type"];
        
        //若仍然没有创建peerConnection，那么就是callee接收到offer
        //否则是，caller接受到信息
        if ((!self.webrtcTool.isInitiator) && (!self.webrtcTool.hasCreatedPeerConnection) ) {
            if ([type isEqualToString:@"offer"]) {

                [self.queuedSignalingMessages insertObject:rtcDic atIndex:0];
                
                //此处作为callee接收到的offer
                NSString *receiveStr = [NSString stringWithFormat:@"接受来自%@的通话",self.otherUser.userName];
                UIAlertView *alertV = [[UIAlertView alloc]initWithTitle:@"接受通话" message:receiveStr delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                alertV.tag = ALERTVIEWCALLEE;
                [alertV show];
            }else{
                [self.queuedSignalingMessages addObject:rtcDic];
            }
        }else{
            [self handleRTCMessage:rtcDic];
        }

    }
    
}


#pragma mark- webrtc代理方法
/***  发送本地sdp*/
- (void)sendSdpWithData:(NSData *)data {
    
    NSString *sdpStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    [self.mqttSessionTool sendChatMessage:[self buildChatMessageWithContent:sdpStr]];
//    [self.mqttSessionTool sendMessageWithString:sdpStr];
}

- (void)sendICECandidate:(NSData *)data {
    
    NSString *iceCandidate = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    [self.mqttSessionTool sendChatMessage:[self buildChatMessageWithContent:iceCandidate]];
//    [self.mqttSessionTool sendMessageWithString:iceCandidate];
}

- (void)handleRTCMessage:(NSDictionary *)rtcDic {
    
    if (!self.webrtcTool.hasCreatedPeerConnection) {
        return;
    }
    
    [JSIMTool logOutContent:@"处理rtc信息流"];
    
    NSString *type = rtcDic[@"type"];
    
    if ([type compare:@"offer"] == NSOrderedSame) {
        
        [JSIMTool logOutContent:@"处理rtc————offer"];
        
        NSString *sdpString = [rtcDic objectForKey:@"sdp"];
        [self.webrtcTool callerHandleOfferWithType:type offer:sdpString];
        
        
    }else if ([type compare:@"answer"] == NSOrderedSame) {
        
        [JSIMTool logOutContent:@"处理rtc————answer"];
        
        NSString *sdpString = [rtcDic objectForKey:@"sdp"];
        [self.webrtcTool callerHandleAnswerWithType:type answer:sdpString];
        
    }else if ([type compare:@"candidate"] == NSOrderedSame) {
        
        [JSIMTool logOutContent:@"处理rtc————candidate"];
        
        NSString *mid = [rtcDic objectForKey:@"id"];
        NSNumber *sdpLineIndex = [rtcDic objectForKey:@"label"];
        NSString *sdp = [rtcDic objectForKey:@"candidate"];
        [self.webrtcTool handleIceCandidateWithID:mid label:sdpLineIndex candidate:sdp];
        
    }else if ([type compare:@"bye"] == NSOrderedSame) {
        //        [self stopRTCTaskAsInitiator:NO];
    }
    
}

- (void)handleRTCMessageDone {
    [self.queuedSignalingMessages removeAllObjects];
}

- (void)addVideoView {
    
//    self.remoteVideoView = [[RTCEAGLVideoView alloc]initWithFrame:CGRectMake(10, 40, 300, 300)];
//    self.remoteVideoView.delegate = self;
//    self.remoteVideoView.transform = CGAffineTransformMakeScale(-1, 1);
//    [self.view addSubview:self.remoteVideoView];
    
    
//    self.rtcVideoView = [[RTCVideoView alloc]initWithFrame:CGRectMake(40, 50, 200, 200)];
//    self.rtcVideoView.layer.transform = CATransform3DMakeScale(1, -1, 1);
//    self.rtcVideoView.backgroundColor = [UIColor lightGrayColor];
//    [self.view addSubview:self.rtcVideoView];
    
}

- (void)receiveStreamWithPeerConnection:(RTCMediaStream *)mediaStream {
    
    [JSIMTool logOutContent:@"receive media stream..."];
    
    if ([mediaStream.videoTracks count] > 0) {
        RTCVideoTrack *track = [mediaStream.videoTracks lastObject];
//        [track addRenderer:self.rtcVideoView];
//        [track addRenderer:self.remoteVideoView];
    }
}

- (void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size {
    
}////////////////////////////

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
    }else{
        self.mySelf.userName = UserBobName;
        self.otherUser.userName = UserAliceName;
    }
    
    self.stunServerConfig.serverName = SERVERNAME_DNJ;
    self.stunServerConfig.url = ICESERVER_DNJ_STUN_HOST;
    self.turnerverConfig.url = ICESERVER_DNJ_TURN_HOST;
    self.turnerverConfig.username = ICESERVER_DNJ_TURN_USERNAME;
    self.turnerverConfig.credential = ICESERVER_DNJ_TURN_CREDENTIAL;
    
    self.mqttServerConfig.serverName = SERVERNAME_DNJ;
    self.mqttServerConfig.url = MQTTSERVER_DNJHOSt;
    self.mqttServerConfig.port = MQTTSERVER_DNJPORT;
    //更新文本框内容
    [self updateTextFieldContent];
    //更新连接
    [self updateMQTTSessionConnection];
}

- (void)updateTextFieldContent {
    
    self.myIDTextField.text = self.mySelf.userName;
    self.otherIDTextField.text = self.otherUser.userName;
    self.mqttServerTextField.text = self.mqttServerConfig.serverName;
    self.iceServerTextField.text = self.stunServerConfig.serverName;
}

#pragma mark- 系统控件 delegate

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
    [self updateMQTTSessionConnection];
    [self updateICEServer];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self.view endEditing:YES];
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 1) {
        if (alertView.tag == ALERTVIEWCALLER) {
            //确定发起通话
            [self.webrtcTool startRTCWorkerAsInitiator:YES queuedSignalMessage:self.queuedSignalingMessages];
        }else if (alertView.tag == ALERTVIEWCALLEE){
            //确定接受通话
            [self.webrtcTool startRTCWorkerAsInitiator:NO queuedSignalMessage:self.queuedSignalingMessages];
        }
    }

}

#pragma mark- json字符串转字典

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
        return nil;
    }
    return dic;
}
@end
