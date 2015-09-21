//
//  JSIMTool.h
//  JSIMWebrtcOverMQTT
//
//  Created by WHC on 15/9/18.
//  Copyright (c) 2015年 weaver software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConfigSet.h"

@interface JSIMTool : NSObject


/**
 *  按步骤打印log
 *
 *  @param setp    <#setp description#>
 *  @param content <#content description#>
 */
+ (void)logOutWithStep:(NSInteger)setp Content:(NSString *)content;

+ (void)logOutContent:(NSString *)content;

@end
