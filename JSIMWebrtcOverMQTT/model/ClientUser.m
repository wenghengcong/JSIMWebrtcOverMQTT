//
//  ClientUser.m
//  JSIMWebrtcOverMQTT
//
//  Created by WHC on 15/9/18.
//  Copyright (c) 2015年 weaver software. All rights reserved.
//

#import "ClientUser.h"

@implementation ClientUser

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    if (self) {
        self.userID = [aDecoder decodeIntegerForKey:@"userID"];
        self.userName = [aDecoder decodeObjectForKey:@"userName"];
        self.userPassword = [aDecoder decodeObjectForKey:@"userPassword"];
        self.iceServerUrl = [aDecoder decodeObjectForKey:@"iceServerUrl"];
        self.mqttServerUrl = [aDecoder decodeObjectForKey:@"mqttServerUrl"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.userPassword forKey:@"userPassword"];
    [aCoder encodeObject:self.userName forKey:@"userName"];
    [aCoder encodeInteger:self.userID forKey:@"userID"];
    [aCoder encodeObject:self.iceServerUrl forKey:@"iceServerUrl"];
    [aCoder encodeObject:self.mqttServerUrl forKey:@"mqttServerUrl"];
    
}

@end
