//
//  ClientUser.h
//  JSIMWebrtcOverMQTT
//
//  Created by WHC on 15/9/18.
//  Copyright (c) 2015年 weaver software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClientUser : NSObject<NSCoding>

@property (assign ,nonatomic)NSInteger      userID;
@property (copy ,nonatomic)NSString         *userName;
@property (copy ,nonatomic)NSString         *userPassword;
@property (copy ,nonatomic)NSString         *iceServerUrl;
@property (copy ,nonatomic)NSString         *mqttServerUrl;

@end
