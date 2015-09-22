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

- (void)startEngine {
    
    RTCSetMinDebugLogLevel(kRTCLoggingSeverityError);
    
    [RTCPeerConnectionFactory initializeSSL];
    self.peerConnectionFactory = [[RTCPeerConnectionFactory alloc]init];
    
    //设置约束
    [self setConstraints];
}

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

#pragma mark- viewcontroller调用

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

- (void)startAsCaller {
    
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

- (void)notifyAddVideoView {
    
    if ([self.webDelegate respondsToSelector:@selector(addVideoView)]) {
        [self.webDelegate addVideoView];
    }
}

- (void)callerHandleOfferWithType:(NSString *)type offer:(NSString *)offer {
    
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
                                  initWithType:type sdp:[self preferISAC:offer]];
    [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:sdp];

}

- (void)callerHandleAnswerWithType:(NSString *)type answer:(NSString *)answer {
    
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc]
                                  initWithType:type sdp:[self preferISAC:answer]];
    [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:sdp];

}

- (void)handleIceCandidateWithID:(NSString *)ID label:(NSNumber *)label candidate:(NSString *)sdp {
    
    RTCICECandidate *candidate =
    [[RTCICECandidate alloc] initWithMid:ID
                                   index:label.intValue
                                     sdp:sdp];
    
    [self.peerConnection addICECandidate:candidate];
}

#pragma mark- RTCPeerConnectionDelegate
/** *  当ICE被发现时，调用 */
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

- (void)peerConnection:(RTCPeerConnection *)peerConnection didOpenDataChannel:(RTCDataChannel *)dataChannel {
//    [JSIMTool logOutContent:@"didOpenDataChannel"];
    
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection iceGatheringChanged:(RTCICEGatheringState)newState {
//    [JSIMTool logOutContent:@"iceGatheringChanged"];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection iceConnectionChanged:(RTCICEConnectionState)newState {
//    [JSIMTool logOutContent:@"iceConnectionChanged"];

}

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
- (void)peerConnection:(RTCPeerConnection *)peerConnection removedStream:(RTCMediaStream *)stream {
//    [JSIMTool logOutContent:@"removedStream"];

}

- (void)peerConnectionOnError:(RTCPeerConnection *)peerConnection {
//    [JSIMTool logOutContent:@"peerConnectionOnError"];

}

#pragma mark- RTCSessionDescriptonDelegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp error:(NSError *)error{
    
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
        if (self.peerConnection.signalingState == RTCSignalingHaveLocalOffer ) {
            // Send offer/answer through the signaling channel of our application
            
        } else if (self.peerConnection.signalingState == RTCSignalingHaveLocalPrAnswer) {
            // If we have a remote offer we should add it to the peer connection
            [self.peerConnection createAnswerWithDelegate:self constraints:self.sdpConstraints];
        }else if (self.peerConnection.signalingState == RTCSignalingHaveRemoteOffer){
            [self.peerConnection createAnswerWithDelegate:self constraints:self.sdpConstraints];
        }else if (self.peerConnection.signalingState == RTCSignalingHaveRemotePrAnswer){

        }
    });

}


#pragma mark-

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
