//
//  ChatMessage.m
//  JSIMWebrtcOverMQTT
//
//  Created by WHC on 15/9/18.
//  Copyright (c) 2015年 weaver software. All rights reserved.
//

#import "ChatMessage.h"

@implementation ChatMessage

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    if (self) {
        self.fromUser = [aDecoder decodeObjectForKey:@"formUser"];
        self.toUser = [aDecoder decodeObjectForKey:@"toUser"];
        self.mesID = [aDecoder decodeIntegerForKey:@"mesID"];
        self.content = [aDecoder decodeObjectForKey:@"content"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.fromUser forKey:@"formUser"];
    [aCoder encodeObject:self.toUser forKey:@"toUser"];
    [aCoder encodeInteger:self.mesID forKey:@"mesID"];
    [aCoder encodeObject:self.content forKey:@"content"];

}

@end
