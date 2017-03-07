//
//  ConfigSet.h
//  JSIMWebrtcOverMQTT
//
//  Created by WHC on 15/9/18.
//  Copyright (c) 2015年 weaver software. All rights reserved.
//

#ifndef JSIMWebrtcOverMQTT_ConfigSet_h
#define JSIMWebrtcOverMQTT_ConfigSet_h


#endif

#define UserAliceName                   @"JSIMUser/Alice"
#define UserBobName                     @"JSIMUser/Bob"

//server name
#define SERVERNAME_IPTEL                        @"iptel server"
#define SERVERNAME_SOFTJOYS                     @"softjoys server"
#define SERVERNAME_IBM                          @"ibm server"
#define SERVERNAME_MOSQUITTOR                   @"mosquitto server"
#define SERVERNAME_OTHER                        @"other server"


//mqtt server config

#define MQTTSERVER_IBMHOST              @"messagesight.demos.ibm.com"
#define MQTTSERVER_IBMPORT              @"1883"

#define MQTTSERVER_MOSQUITTOHOST        @"test.mosquitto.org"
#define MQTTSERVER_MOSQUITTOPORT        @"1883"


//ice
#define ICESERVER_IPTEL_STUN_HOST                 @"stun:stun.iptel.org"
#define ICESERVER_IPTEL_STUN_PORT                 @""

#define ICESERVER_IPTEL_TURN_HOST                 @"stun:stun.iptel.org"
#define ICESERVER_IPTEL_TURN_PORT                 @""
#define ICESERVER_IPTEL_TURN_USERNAME             @""
#define ICESERVER_IPTEL_TURN_CREDENTIAL           @""

#define ICESERVER_SOFTJOYS_STUN_HOST                 @"stun:stun.softjoys.com"
#define ICESERVER_SOFTJOYS_STUN_PORT                 @""

#define ICESERVER_SOFTJOYS_TURN_HOST                 @"stun:stun.softjoys.com"
#define ICESERVER_SOFTJOYS_TURN_PORT                 @""
#define ICESERVER_SOFTJOYS_TURN_USERNAME             @""
#define ICESERVER_SOFTJOYS_TURN_CREDENTIAL           @""


#define JSIMRTCLOG

#ifdef JSIMRTCLOG
#define JSIMRTCLOG(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define JSIMRTCLOG(format, ...)
#endif
