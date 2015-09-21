//
//  MQTTSessionManager.m
//  JSIMWebrtcOverMQTT
//
//  Created by WHC on 15/9/21.
//  Copyright © 2015年 weaver software. All rights reserved.
//

#import "MQTTSessionTool.h"

@implementation MQTTSessionTool

#pragma mark- init
+ (instancetype)sharedInstance{
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc]init];
    });
    
    return sharedInstance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.mqttSession = [[MQTTSession alloc] initWithClientId:nil
                                                        userName:nil
                                                        password:nil
                                                       keepAlive:60
                                                    cleanSession:true
                                                            will:YES
                                                       willTopic:@"online"
                                                         willMsg:[@"offline" dataUsingEncoding:NSUTF8StringEncoding]
                                                         willQoS:MQTTQosLevelAtMostOnce
                                                  willRetainFlag:FALSE
                                                   protocolLevel:4
                                                         runLoop:[NSRunLoop currentRunLoop]
                                                         forMode:NSDefaultRunLoopMode];
    }

    return self;
}

#pragma mark- setter/getter


#pragma mark- connect
- (void)sessionConnectToHost:(NSString *)host Port:(NSInteger )port {
    [self.mqttSession connectToHost:host port:port];
    [JSIMTool logOutContent:@"mqtt 连接中..."];
}


#pragma mark- subscribe

- (void)subscriberTopic{
    [self.mqttSession subscribeTopic:self.subTopic];
    NSString *str = [NSString stringWithFormat:@"订阅：%@",self.subTopic];
    [JSIMTool logOutContent:str];
}

- (void)subscriberTopicsWithDic:(NSArray *)topics{
    
}

#pragma mark- unsubscribe
- (void)unSubscriberTopic{
    [self.mqttSession unsubscribeTopic:self.subTopic];
    NSString *str = [NSString stringWithFormat:@"取消订阅：%@",self.subTopic];
    [JSIMTool logOutContent:str];
}

- (void)unSubscriberTopicsWithArray:(NSArray *)topics{
    
}

- (void)unSubscriberAllTopic{
    
}

#pragma mark- send meessage

- (void)sendMessageWithData:(NSData *)data{
    [self.mqttSession publishData:data onTopic:self.pubTopic];

    ChatMessage *chatMes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSString *str = [NSString stringWithFormat:@"发送消息，主题：%@--内容：%@",self.pubTopic,chatMes.content];
    [JSIMTool logOutContent:str];
}

- (void)sendMessageWithDic:(NSDictionary *)dic{
    
    [self.mqttSession publishJson:dic onTopic:self.pubTopic];
}

- (void)sendMessageWithString:(NSString *)string{
    
    NSDictionary *dicFormStr = [self dictionaryWithJsonString:string];
    [self sendMessageWithDic:dicFormStr];
}

- (void)sendChatMessage:(ChatMessage*)chatMessage{
    NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:chatMessage];
    [self sendMessageWithData:messageData];
}

#pragma mark- other

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
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}
@end
