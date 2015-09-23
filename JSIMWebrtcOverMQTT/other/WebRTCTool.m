//
//  WebRTCManager.m
//  JSIMWebrtcOverMQTT
//
//  Created by WHC on 15/9/21.
//  Copyright © 2015年 weaver software. All rights reserved.
//

#import "WebRTCTool.h"
#import <AVFoundation/AVFoundation.h>

@implementation WebRTCTool

- (instancetype)init{
    self = [super init];
    if (self) {
        
        self.stunServerConfig = [[ServerConfig alloc]init];
        self.turnServerConfig = [[ServerConfig alloc]init];
        self.mqttSessionTool = [[MQTTSessionTool alloc]init];
        [self startEngine];

    }
    return self;
}

#pragma mark- 初始化RTC

/**
 *  开启webrtc会话
 */
- (void)startEngine {
    
    RTCSetMinDebugLogLevel(kRTCLoggingSeverityError);
    
    [RTCPeerConnectionFactory initializeSSL];
    self.peerConnectionFactory = [[RTCPeerConnectionFactory alloc]init];
    
    //设置约束
    [self setConstraints];
}

/**
 *  设置webrtc相关参数
 */
- (void)setConstraints {
    
    //设置RTCPeerConnection的约束
    self.pcConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@[[[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"], [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]] optionalConstraints:@[[[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"false"]]];
    
    
    //设置SDP的约束，用于在offer/answer中
    self.sdpConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@[[[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"], [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]] optionalConstraints:nil];
    
    
    //用于设置视频的相关约束
    RTCPair *maxAspectRatio = [[RTCPair alloc] initWithKey:@"maxAspectRatio" value:@"4:3"];
    
    //when maxWidth=640,maxHeight=480,the video transmission is slow
    RTCPair *maxWidth = [[RTCPair alloc] initWithKey:@"maxWidth" value:@"320"];
    RTCPair *minWidth = [[RTCPair alloc] initWithKey:@"minWidth" value:@"160"];
    
    RTCPair *maxHeight = [[RTCPair alloc] initWithKey:@"maxHeight" value:@"240"];
    RTCPair *minHeight = [[RTCPair alloc] initWithKey:@"minHeight" value:@"120"];
    
    RTCPair *maxFrameRate = [[RTCPair alloc] initWithKey:@"maxFrameRate" value:@"30"];
    RTCPair *minFrameRate = [[RTCPair alloc] initWithKey:@"minFrameRate" value:@"24"];
    
    NSArray *mandatory = @[maxAspectRatio,maxWidth,minWidth,maxHeight,minHeight, maxFrameRate ,minFrameRate];
    self.videoConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatory optionalConstraints:nil];
    
}

#pragma mark- view controller调用

/**
 *  当用户（caller/callee）触发按钮，进行通话操作，首先进入到这里
 *
 *  @param flag               yes时，是以caller进入，no即为callee
 *  @param queueSingleMessage 消息队列
 */
- (void)startRTCWorkerAsInitiator:(BOOL)flag queuedSignalMessage:(NSMutableArray *)queueSingleMessage{
    
    self.isInitiator = flag;
    NSArray *servers = [self getICEServer];
    
    self.peerConnection = [self.peerConnectionFactory peerConnectionWithICEServers:servers constraints:self.pcConstraints delegate:self];
    
    self.hasCreatedPeerConnection = YES;

    
    //setup local media stream
    RTCMediaStream *lms = [self.peerConnectionFactory mediaStreamWithLabel:@"ARDAMS"];
    
    //add local video track
    if (!self.localVideoCapture) {
        NSString *cameraID = nil;
        //** front camera
        for (AVCaptureDevice *captureDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] ) {
            if (!cameraID || captureDevice.position == AVCaptureDevicePositionFront) {
                cameraID = [captureDevice localizedName];
            }
        }
        self.localVideoCapture = [RTCVideoCapturer capturerWithDeviceName:cameraID];
    }
    if (!self.localVideoSource) {
        self.localVideoSource = [self.peerConnectionFactory videoSourceWithCapturer:self.localVideoCapture constraints:self.videoConstraints];
    }
    if (!self.localVideoTrack) {
        self.localVideoTrack = [self.peerConnectionFactory videoTrackWithID:@"ARDAMSv0" source:self.localVideoSource];
    }
#warning TODO:video
    if (self.localVideoTrack) {
//        [lms addVideoTrack:self.localVideoTrack];
    }
    
    //add local audio track
    if(!self.localAudioTrack){
        self.localAudioTrack = [self.peerConnectionFactory audioTrackWithID:@"ARDAMSa0"];
    }
    if(self.localAudioTrack){
        [lms addAudioTrack:self.localAudioTrack];
    }
    
    //add local stream
    [self.peerConnection addStream:lms];

    if (self.isInitiator) {
        [self startAsCaller];
    }else{
        [self startAsCallee:queueSingleMessage];
    }
    
    [self notifyAddVideoView];
    
}
/**
 *  在webrtc peerConnection初始化之后，通知代理，打开视频窗口（此时，没有数据流，一直要等到p2p通道建立后，才有数据流传送）
 */
- (void)notifyAddVideoView {
    
    if ([self.webDelegate respondsToSelector:@selector(addVideoView)]) {
        [self.webDelegate addVideoView];
    }
}

- (void)startAsCaller {
    /**
     *  作为caller，第一步就是创建offer，offer创建成功后，会调用didCreateSessionDescription方法
     *  在回调方法中，将offer发送
     */
    [self.peerConnection createOfferWithDelegate:self constraints:self.sdpConstraints];
}

- (void)startAsCallee:(NSMutableArray *)queueSingleMessage {

    if ([self.webDelegate respondsToSelector:@selector(handleRTCMessage:)]) {
        
        for (int i = 0; i < queueSingleMessage.count; i++) {
            NSDictionary *rtcDic = queueSingleMessage[i];
            [self.webDelegate handleRTCMessage:rtcDic];
        }
    }
    //处理完信息之后
    if ([self.webDelegate respondsToSelector:@selector(handleRTCMessageDone)]) {
        [self.webDelegate handleRTCMessageDone];
    }
}


/**
 *  callee接收到信令传过来的offer，将caller的offer设置为自己的remote description
 *
 *  @param type  offer
 *  @param offer caller offer(caller local description)
 */
- (void)calleeHandleOfferWithType:(NSString *)type offer:(NSString *)offer {
    
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
                                  initWithType:type sdp:[self preferISAC:offer]];
    //设置remote description时，会调用didSetSessionDescriptionWithError回调方法
    [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:sdp];

}
/**
 *  caller接受到信令传送过来的answer，将callee的offer设置为自己的remote description
 *
 *  @param type   answer
 *  @param answer callee answer(callee local description)
 */
- (void)callerHandleAnswerWithType:(NSString *)type answer:(NSString *)answer {
    
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
                                  initWithType:type sdp:[self preferISAC:answer]];
    [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:sdp];

}
/**
 *  不管作为caller，还是callee，在通过ICE服务器设置完peerConnection后，一直会搜寻ice伺服器。
 *
 *  @param ID    <#ID description#>
 *  @param label <#label description#>
 *  @param sdp   <#sdp description#>
 */
- (void)handleIceCandidateWithID:(NSString *)ID label:(NSNumber *)label candidate:(NSString *)sdp {
    
    RTCICECandidate *candidate =
    [[RTCICECandidate alloc] initWithMid:ID
                                   index:label.intValue
                                     sdp:sdp];
    
    [self.peerConnection addICECandidate:candidate];
}

#pragma mark- RTCPeerConnectionDelegate
/**
 *  新的ice伺服器被发现
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection gotICECandidate:(RTCICECandidate *)candidate {
    
    NSDictionary *jsonDict =
    @{ @"type" : @"candidate",
       @"label" : [NSNumber numberWithInteger:candidate.sdpMLineIndex],
       @"id" : candidate.sdpMid,
       @"candidate" : candidate.sdp };
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&error];
    
    if (!error) {
        if ([self.webDelegate respondsToSelector:@selector(sendICECandidate:)]) {
            [self.webDelegate sendICECandidate:jsonData];
        }
    } else {

    }
}

/**
 *  新的dataChannel通道打开
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didOpenDataChannel:(RTCDataChannel *)dataChannel {
//    [JSIMTool logOutContent:@"didOpenDataChannel"];
    
}

/**
 *  在任何时间内，只要 ICEGatheringState 状态改变时调用
 *  @param newState       ICE侦听状态
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection iceGatheringChanged:(RTCICEGatheringState)newState {
//    [JSIMTool logOutContent:@"iceGatheringChanged"];
}

/**
 *  在任何时间内，只要 RTCICEConnectionState 状态改变时调用
 *  @param newState       ICE连接状态
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection iceConnectionChanged:(RTCICEConnectionState)newState {
//    [JSIMTool logOutContent:@"iceConnectionChanged"];

}

/**
 *  在peerConnection信令通道状态改变时，触发该方法
 *  @param stateChanged   信令通道状态
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection signalingStateChanged:(RTCSignalingState)stateChanged{
    
    NSString *state = @"";
    switch (stateChanged) {
        case RTCSignalingStable:
            state = @"RTCSignalingStable";
            break;
            
        case RTCSignalingHaveLocalOffer:
            state = @"RTCSignalingHaveLocalOffer";
            break;
            
        case RTCSignalingHaveLocalPrAnswer:
            state = @"RTCSignalingHaveLocalPrAnswer";
            break;
            
        case RTCSignalingHaveRemoteOffer:
            state = @"RTCSignalingHaveRemoteOffer";
            break;
            
        case RTCSignalingHaveRemotePrAnswer:
            state = @"RTCSignalingHaveRemotePrAnswer";
            break;
            
        case RTCSignalingClosed:
            state = @"RTCSignalingClosed";
            break;
        default:
            break;
    }
    
    NSString *logStr = [NSString stringWithFormat:@"signallingState--%@",state];
    
    [JSIMTool logOutContent:logStr];

}

- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection {
//    [JSIMTool logOutContent:@"peerConnectionOnRenegotiationNeeded"];

}

/**
 *  从peerConnection接收到新的媒体流调用
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection addedStream:(RTCMediaStream *)stream {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([self.webDelegate respondsToSelector:@selector(receiveStreamWithPeerConnection:)]) {
            [self.webDelegate receiveStreamWithPeerConnection:stream];
        }
    });

}
/**
 *  从peerConnection移除媒体流
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection removedStream:(RTCMediaStream *)stream {
//    [JSIMTool logOutContent:@"removedStream"];

}
/**
 *  peerConnection连接发送错误是触发
 */
- (void)peerConnectionOnError:(RTCPeerConnection *)peerConnection {
//    [JSIMTool logOutContent:@"peerConnectionOnError"];

}

#pragma mark- RTCSessionDescriptonDelegate

/**
 *  一旦创建offer/answer会调用此方法
 *
 *  @param peerConnection
 *  @param sdp            local/remote description
 *  @param error
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp error:(NSError *)error{
    
    /**
     *两种情况下，会设置local description，并且通过信令通道发送
     *1.caller创建offer成功后，设置local description，并且发送
     *2.callee创建answer成功后，同样会设置local description，并且发送（在这之前，callee已将remote description设置完毕）
     */
    
    RTCSessionDescription *localSdp = [[RTCSessionDescription alloc]initWithType:sdp.type sdp:[self preferISAC:sdp.description]];
    [self.peerConnection setLocalDescriptionWithDelegate:self sessionDescription:localSdp];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *jsonDic = @{@"type":sdp.type,@"sdp":sdp.description};
        NSError *error;
        NSData *mesData = [NSJSONSerialization dataWithJSONObject:jsonDic options:NSJSONWritingPrettyPrinted error:&error];
        
        if ([self.webDelegate respondsToSelector:@selector(sendSdpWithData:)]) {
            [self.webDelegate sendSdpWithData:mesData];
        }
        
    });
    
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error{
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        
        // If we have a local offer OR answer we should signal it
        // Send offer/answer through the signaling channel of our application

        
        if (self.peerConnection.signalingState == RTCSignalingHaveLocalOffer ) {
            
        } else if (self.peerConnection.signalingState == RTCSignalingHaveLocalPrAnswer) {

//            [self.peerConnection createAnswerWithDelegate:self constraints:self.sdpConstraints];
            
            
        }else if (self.peerConnection.signalingState == RTCSignalingHaveRemoteOffer){
            
            /**
             *  callee在接到caller的offer后，且将callee的remote description设置完之后，创建answer
             *  创建answer之后，调用didCreateSessionDescription回调处理，在回调中发送answer
             */
            [self.peerConnection createAnswerWithDelegate:self constraints:self.sdpConstraints];
            
            
        }else if (self.peerConnection.signalingState == RTCSignalingHaveRemotePrAnswer){

        }
    });

}


#pragma mark- get ice server

- (NSArray *)getICEServer {
    
    NSMutableArray *iceServers = [[NSMutableArray alloc]init];
    
    RTCICEServer *turnServer = [[RTCICEServer alloc]initWithURI: [NSURL URLWithString:self.turnServerConfig.url]  username:self.turnServerConfig.username password:self.turnServerConfig.credential];
    [iceServers addObject:turnServer];
    
    RTCICEServer *stunServer = [[RTCICEServer alloc]initWithURI:[NSURL URLWithString:self.stunServerConfig.url] username:@"" password:@""];
    [iceServers addObject:stunServer];
    
    return iceServers;
}

#pragma mark- 终止rtc

- (void)stopEngine {
    
    [RTCPeerConnectionFactory deinitializeSSL];
    
    self.pcConstraints = nil;
    self.sdpConstraints = nil;
    self.videoConstraints = nil;
    
    self.peerConnectionFactory = nil;
    [JSIMTool logOutContent:@"断开peerConnection"];
}

#pragma mark- 工具方法

// Match |pattern| to |string| and return the first group of the first
// match, or nil if no match was found.
- (NSString *)firstMatch:(NSRegularExpression *)pattern
              withString:(NSString *)string
{
    NSTextCheckingResult* result =
    [pattern firstMatchInString:string
                        options:0
                          range:NSMakeRange(0, [string length])];
    if (!result)
        return nil;
    return [string substringWithRange:[result rangeAtIndex:1]];
}

// Mangle |origSDP| to prefer the ISAC/16k audio codec.
- (NSString *)preferISAC:(NSString *)origSDP
{
    int mLineIndex = -1;
    NSString* isac16kRtpMap = nil;
    NSArray* lines = [origSDP componentsSeparatedByString:@"\n"];
    NSRegularExpression* isac16kRegex = [NSRegularExpression
                                         regularExpressionWithPattern:@"^a=rtpmap:(\\d+) ISAC/16000[\r]?$"
                                         options:0
                                         error:nil];
    for (int i = 0;
         (i < [lines count]) && (mLineIndex == -1 || isac16kRtpMap == nil);
         ++i) {
        NSString* line = [lines objectAtIndex:i];
        if ([line hasPrefix:@"m=audio "]) {
            mLineIndex = i;
            continue;
        }
        isac16kRtpMap = [self firstMatch:isac16kRegex withString:line];
    }
    if (mLineIndex == -1) {
        return origSDP;
    }
    if (isac16kRtpMap == nil) {
        return origSDP;
    }
    NSArray* origMLineParts =
    [[lines objectAtIndex:mLineIndex] componentsSeparatedByString:@" "];
    NSMutableArray* newMLine =
    [NSMutableArray arrayWithCapacity:[origMLineParts count]];
    int origPartIndex = 0;
    // Format is: m=<media> <port> <proto> <fmt> ...
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:isac16kRtpMap];
    for (; origPartIndex < [origMLineParts count]; ++origPartIndex) {
        if ([isac16kRtpMap compare:[origMLineParts objectAtIndex:origPartIndex]]
            != NSOrderedSame) {
            [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex]];
        }
    }
    NSMutableArray* newLines = [NSMutableArray arrayWithCapacity:[lines count]];
    [newLines addObjectsFromArray:lines];
    [newLines replaceObjectAtIndex:mLineIndex
                        withObject:[newMLine componentsJoinedByString:@" "]];
    return [newLines componentsJoinedByString:@"\n"];
}

@end
