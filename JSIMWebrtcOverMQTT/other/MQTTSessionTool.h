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
/**
 *  订阅主题
 */
- (void)subscriberTopic;
/**
 *  订阅多个主题
 *
 *  @param topics 主题数组
 */
- (void)subscriberTopicsWithDic:(NSArray *)topics;
/**
 *  取消订阅
 */
- (void)unSubscriberTopic;
/**
 *  取消订阅多个主题
 *
 *  @param topics 主题数组
 */
- (void)unSubscriberTopicsWithArray:(NSArray *)topics;
/**
 *  取消所有订阅
 */
- (void)unSubscriberAllTopic;

/**
 *  发送二进制消息
 *
 *  @param data <#data description#>
 */
- (void)sendMessageWithData:(NSData *)data;
/**
 *  发送字典消息（传送的仍然是二进制）
 *
 *  @param dic <#dic description#>
 */
- (void)sendMessageWithDic:(NSDictionary *)dic;
/**
 *  发送字符串消息（传送的仍然是二进制）
 *
 *  @param string <#string description#>
 */
- (void)sendMessageWithString:(NSString *)string;
/**
 *  发送自定义消息（传送的仍然是二进制）
 *
 *  @param chatMessage <#chatMessage description#>
 */
- (void)sendChatMessage:(ChatMessage*)chatMessage;
@end
