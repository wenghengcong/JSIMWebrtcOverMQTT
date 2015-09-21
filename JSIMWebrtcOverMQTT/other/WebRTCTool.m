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
        [self startEngine];
        self.stunServerConfig = [[ServerConfig alloc]init];
        self.turnServerConfig = [[ServerConfig alloc]init];
    }
    return self;
}
#pragma mark- 初始化RTC

- (void)startEngine {
    
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

- (void)startWebrtcConnection {
    
    NSArray *servers = [self getICEServer];
    
    self.peerConnection = [self.peerConnectionFactory peerConnectionWithICEServers:servers constraints:self.pcConstraints delegate:self];
    
    RTCMediaStream *lms = [self.peerConnectionFactory mediaStreamWithLabel:@"ARDAMS"];
    
    //获取视频源
    if (!self.localVideoCapture) {
        NSString *cameraID = nil;
     
        for (AVCaptureDevice *device  in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
            if (!cameraID || device.position == AVCaptureDevicePositionFront) {
                cameraID = [device localizedName];
            }
        }
        self.localVideoCapture = [RTCVideoCapturer capturerWithDeviceName:cameraID];
    }
    
    if (!self.localVideoSource) {
        self.localVideoSource = [self.peerConnectionFactory videoSourceWithCapturer:self.localVideoCapture constraints:self.videoConstraints];
    }
    
    
    //建立视频流，并加入到媒体流
    if (!self.localVideoTrack) {
        self.localVideoTrack = [self.peerConnectionFactory videoTrackWithID:@"ARDAMSv0" source:self.localVideoSource];
    }
    if (self.localVideoTrack) {
        [lms addVideoTrack:self.localVideoTrack];
    }
    
    //获取音频流
    if (!self.localAudioTrack) {
        self.localAudioTrack = [self.peerConnectionFactory audioTrackWithID:@"ARDAMSa0"];
    }
    if (self.localAudioTrack) {
        [lms addAudioTrack:self.localAudioTrack];
    }
    
    [self.peerConnection addStream:lms];
    
}


- (void)startAsCaller {
    
    [self startWebrtcConnection];
    [self.peerConnection createOfferWithDelegate:self constraints:self.sdpConstraints];
    
}

- (void)startAsCallee {
    
    [self startWebrtcConnection];
    
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
