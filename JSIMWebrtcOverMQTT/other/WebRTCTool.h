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

/**
 *  当用户（caller/callee）触发按钮，进行通话操作，首先进入到这里
 *
 *  @param flag               yes时，是以caller进入，no即为callee
 *  @param queueSingleMessage 消息队列
 */
- (void)startRTCWorkerAsInitiator:(BOOL)flag queuedSignalMessage:(NSMutableArray *)queueSingleMessage;

/**
 *  callee接收到信令传过来的offer，将caller的offer设置为自己的remote description
 *
 *  @param type  offer
 *  @param offer caller offer(caller local description)
 */
- (void)calleeHandleOfferWithType:(NSString *)type offer:(NSString *)offer;
/**
 *  caller接受到信令传送过来的answer，将callee的offer设置为自己的remote description
 *
 *  @param type   answer
 *  @param answer callee answer(callee local description)
 */
- (void)callerHandleAnswerWithType:(NSString *)type answer:(NSString *)answer;
/**
 *  不管作为caller，还是callee，在通过ICE服务器设置完peerConnection后，一直会搜寻ice伺服器。
 *
 *  @param ID    <#ID description#>
 *  @param label <#label description#>
 *  @param sdp   <#sdp description#>
 */
- (void)handleIceCandidateWithID:(NSString *)ID label:(NSNumber *)label candidate:(NSString *)candidate;


@end

/**
 *  实现webrtcTool代理，需要有以下功能
 */
@protocol WebRTCToolDelegate <NSObject>

@optional
/**
 *  发送Sdp
 */
- (void)sendSdpWithData:(NSData *)data;
/**
 *  发送ICE信息
 */
- (void)sendICECandidate:(NSData *)data;
/**
 *  处理rtc通信中的信息，并将处理后的结果返回给WebrtcTool
 *
 *  @param rtcDic 需要处理的RTC信息
 */
- (void)handleRTCMessage:(NSDictionary *)rtcDic;
/**
 *  处理RTC信息完毕信息后调用
 */
- (void)handleRTCMessageDone;
/**
 *  打开视频窗口，并进行初始化
 */
- (void)addVideoView;
/**
 *  处理从peerConnection传过来的媒体数据流
 *
 *  @param mediaStream 传送的媒体数据流
 */
- (void)receiveStreamWithPeerConnection:(RTCMediaStream *)mediaStream;


@end
