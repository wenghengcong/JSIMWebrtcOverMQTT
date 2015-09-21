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

#define UserAliceName                   @"User/Alice"
#define UserBobName                     @"User/Bob"

//server name
#define SERVERNAME_DNJ                  @"dnj server"
#define SERVERNAME_IBM                  @"ibm server"
#define SERVERNAME_MOSQUITTOR           @"mosquitto server"
#define SERVERNAME_OTHER                @"other server"


//mqtt server config
#define MQTTSERVER_DNJHOSt              @"183.131.153.252"
#define MQTTSERVER_DNJPORT              @"1883"

#define MQTTSERVER_IBMHOST              @"messagesight.demos.ibm.com"
#define MQTTSERVER_IBMPORT              @"1883"

#define MQTTSERVER_MOSQUITTOHOST        @"test.mosquitto.org"
#define MQTTSERVER_MOSQUITTOPORT        @"1883"


//ice
#define ICESERVER_DNJ_STUN_HOST                 @"stun:183.131.153.252:3478"
#define ICESERVER_DNJ_STUN_PORT                 @""

#define ICESERVER_DNJ_TURN_HOST                 @"turn:183.131.153.252:3478"
#define ICESERVER_DNJ_TURN_PORT                 @""
#define ICESERVER_DNJ_TURN_USERNAME             @"wujin099"
#define ICESERVER_DNJ_TURN_CREDENTIAL           @"13936513"



#define JSIMRTCLOG

#ifdef JSIMRTCLOG
#define JSIMRTCLOG(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define JSIMRTCLOG(format, ...)
#endif