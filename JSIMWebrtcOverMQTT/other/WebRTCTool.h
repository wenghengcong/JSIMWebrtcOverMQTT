//
//  WebRTCManager.h
//  JSIMWebrtcOverMQTT
//
//  Created by WHC on 15/9/21.
//  Copyright © 2015年 weaver software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSIMTool.h"
#import "ServerConfig.h"
#import "MQTTSessionTool.h"

#import <RTCAVFoundationVideoSource.h>
#import <RTCAudioSource.h>
#import <RTCAudioTrack.h>
#import <RTCDataChannel.h>
#import <RTCEAGLVideoView.h>

#import <RTCFileLogger.h>
#import <RTCLogging.h>

#import <RTCI420Frame.h>

#import <RTCICECandidate.h>
#import <RTCICEServer.h>

#import <RTCMediaConstraints.h>
#import <RTCMediaStream.h>
#import <RTCMediaStreamTrack.h>
//#import <RTCNSGLVideoView.h>

#import <RTCOpenGLVideoRenderer.h>
#import <RTCPair.h>

#import <RTCPeerConnection.h>
#import <RTCPeerConnectionDelegate.h>
#import <RTCPeerConnectionFactory.h>
#import <RTCPeerConnectionInterface.h>

#import <RTCSessionDescription.h>
#import <RTCSessionDescriptionDelegate.h>

#import <RTCStatsDelegate.h>
#import <RTCStatsReport.h>

#import <RTCTypes.h>
#import <RTCVideoCapturer.h>
#import <RTCVideoRenderer.h>
#import <RTCVideoSource.h>
#import <RTCVideoTrack.h>

@protocol WebRTCToolDelegate;

@interface WebRTCTool : NSObject<RTCPeerConnectionDelegate,RTCSessionDescriptionDelegate>

@property (strong ,nonatomic)MQTTSessionTool                *mqttSessionTool;


@property (strong ,nonatomic)RTCPeerConnectionFactory       *peerConnectionFactory;

@property (strong ,nonatomic)RTCMediaConstraints            *pcConstraints;
@property (strong ,nonatomic) RTCMediaConstraints           *sdpConstraints;
@property (strong ,nonatomic)RTCMediaConstraints            *videoConstraints;


@property (strong ,nonatomic)RTCPeerConnection              *peerConnection;
@property (strong ,nonatomic)RTCVideoCapturer               *localVideoCapture;
@property (strong ,nonatomic)RTCVideoSource                 *localVideoSource;
@property (strong ,nonatomic)RTCAudioTrack                  *localAudioTrack;
@property (strong ,nonatomic)RTCVideoTrack                  *localVideoTrack;


@property (strong ,nonatomic)ServerConfig                   *stunServerConfig;
@property (strong ,nonatomic)ServerConfig                   *turnServerConfig;


@property (assign ,nonatomic)BOOL                           isInitiator;
@property(nonatomic, assign) BOOL                           hasCreatedPeerConnection;

@property (weak ,nonatomic)id<WebRTCToolDelegate>           webDelegate;

- (void)startRTCWorkerAsInitiator:(BOOL)flag queuedSignalMessage:(NSMutableArray *)queueSingleMessage;

- (void)callerHandleOfferWithType:(NSString *)type offer:(NSString *)offer;
- (void)callerHandleAnswerWithType:(NSString *)type answer:(NSString *)answer;
- (void)handleIceCandidateWithID:(NSString *)ID label:(NSNumber *)label candidate:(NSString *)candidate;


@end

@protocol WebRTCToolDelegate <NSObject>

@optional

- (void)sendSdpWithData:(NSData *)data;
- (void)sendICECandidate:(NSData *)data;

- (void)handleRTCMessage:(NSDictionary *)rtcDic;

- (void)handleRTCMessageDone;

- (void)addVideoView;

- (void)receiveStreamWithPeerConnection:(RTCMediaStream *)mediaStream;


@end
