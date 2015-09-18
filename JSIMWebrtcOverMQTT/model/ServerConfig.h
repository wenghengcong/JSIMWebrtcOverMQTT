//
//  ServerConfig.h
//  JSIMWebrtcOverMQTT
//
//  Created by WHC on 15/9/18.
//  Copyright (c) 2015年 weaver software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServerConfig : NSObject

@property (copy ,nonatomic)NSString     *url;
@property (copy ,nonatomic)NSString     *port;

@property (copy ,nonatomic)NSString     *serverName;

@property (copy ,nonatomic)NSString     *username;
@property (copy ,nonatomic)NSString     *credential;

@end
