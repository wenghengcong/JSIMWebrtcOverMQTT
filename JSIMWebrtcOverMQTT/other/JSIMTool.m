//
//  JSIMTool.m
//  JSIMWebrtcOverMQTT
//
//  Created by WHC on 15/9/18.
//  Copyright (c) 2015年 weaver software. All rights reserved.
//

#import "JSIMTool.h"

@implementation JSIMTool



+ (void)logOutWithStep:(NSInteger)setp Content:(NSString *)content
{
    RTCLog(@"第%d步---%@",setp,content);
}

+ (void)logOutContent:(NSString *)content{
    
    RTCLog(@"Content---%@",content);
}
@end
