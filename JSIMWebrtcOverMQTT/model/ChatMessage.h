//
//  ChatMessage.h
//  JSIMWebrtcOverMQTT
//
//  Created by WHC on 15/9/18.
//  Copyright (c) 2015年 weaver software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClientUser.h"


@interface ChatMessage : NSObject<NSCoding>



@property   (assign ,nonatomic)NSInteger            mesID;

@property (strong ,nonatomic)ClientUser         *formUser;

@property (strong ,nonatomic)ClientUser         *toUser;

@property (copy ,nonatomic)NSString           *content;


@end
