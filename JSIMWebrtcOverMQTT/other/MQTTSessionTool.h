//
//  MQTTSessionManager.h
//  JSIMWebrtcOverMQTT
//
//  Created by WHC on 15/9/21.
//  Copyright © 2015年 weaver software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MQTTSession.h>
#import "ChatMessage.h"
#import "JSIMTool.h"

@interface MQTTSessionTool : NSObject

@property (strong ,nonatomic)MQTTSession            *mqttSession;
@property (copy ,nonatomic)NSString                 *subTopic;
@property (copy ,nonatomic)NSString                 *pubTopic;

+ (instancetype)sharedInstance;

- (void)sessionConnectToHost:(NSString *)host Port:(NSInteger )port;

- (void)subscriberTopic;
- (void)subscriberTopicsWithDic:(NSArray *)topics;

- (void)unSubscriberTopic;
- (void)unSubscriberTopicsWithArray:(NSArray *)topics;
- (void)unSubscriberAllTopic;

- (void)sendMessageWithData:(NSData *)data;
- (void)sendMessageWithDic:(NSDictionary *)dic;
- (void)sendMessageWithString:(NSString *)string;
- (void)sendChatMessage:(ChatMessage*)chatMessage;
@end
