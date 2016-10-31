//
//  MTRealReachability.m
//  MTRealReachability
//
//  Created by martin on 2016/10/26.
//  Copyright © 2016年 martin. All rights reserved.
//

#import "MTRealReachability.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "MTNetworkMoniter.h"
#import "MTSimplePing.h"

NSString *MTRealReachabilityChangedNotification = @"MTRealReachabilityChangedNotification";

static CGFloat      const kMinTimeout        = 0.3f;
static CGFloat      const kMaxTimeout        = 60.0f;
static CGFloat      const kDefaultTimeout    = 5.0f;
static CGFloat      const kMinInterval       = 2.0f;
static CGFloat      const kDefaultInterval   = 15.0f;
static NSString     *const kDefaultHostName  = @"www.apple.com";

static MTWWANState wwanStateFromCT(NSString *CTTelephoneType) {
    NSArray *wwan2GArray = @[CTRadioAccessTechnologyEdge,
                             CTRadioAccessTechnologyGPRS,
                             CTRadioAccessTechnologyCDMA1x];
    NSArray *wwan3GArray = @[CTRadioAccessTechnologyHSDPA,
                             CTRadioAccessTechnologyWCDMA,
                             CTRadioAccessTechnologyHSUPA,
                             CTRadioAccessTechnologyCDMAEVDORev0,
                             CTRadioAccessTechnologyCDMAEVDORevA,
                             CTRadioAccessTechnologyCDMAEVDORevB,
                             CTRadioAccessTechnologyeHRPD];
    NSArray *wwan4GArray = @[CTRadioAccessTechnologyLTE];
    if ([wwan2GArray containsObject:CTTelephoneType]) {
        return MTWWANState2G;
    } else if ([wwan3GArray containsObject:CTTelephoneType]) {
        return MTWWANState3G;
    } else if ([wwan4GArray containsObject:CTTelephoneType]) {
        return MTWWANState4G;
    } else {
        return MTWWANStateUnknow;
    }
}

@interface MTRealReachability ()<MTSimplePingDelegate>

@property (nonatomic, strong) MTSimplePing *ping;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) MTNetworkMoniter *moniter;

@property (nonatomic, assign) CFTimeInterval pingTime;

@property (nonatomic, assign) MTNetworkType moniterType;

@property (nonatomic, assign, readwrite) CFTimeInterval pingValue;

@property (nonatomic, copy) void(^notify)(MTNetworkStatus);

@end

@implementation MTRealReachability {
    CTTelephonyNetworkInfo *_networkInfo;
//    MTNetworkStatus _networkStatus;
    NSString *_hostName;
    BOOL _isReachable;
}

+ (instancetype)shareManager {
    static id _manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [self manager];
    });
    return _manager;
}

+ (instancetype)manager {
    return [[self alloc] initWithHost:nil];
}

- (instancetype)initWithHost:(NSString *)hostName {
    self = [super init];
    if (self) {
        if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0) {
            _networkInfo = [[CTTelephonyNetworkInfo alloc] init];
        }
        if (hostName) {
            _hostName = hostName;
        } else {
            _hostName = kDefaultHostName;
        }
        _moniter = [MTNetworkMoniter moniterWithHostName:_hostName];
        self.ping = [[MTSimplePing alloc] initWithHostName:_hostName];
        self.ping.delegate = self;
        _isReachable = NO;
        _pingValue = -1.0;
        _moniterType = MTNetworkUnknown;
        _networkStatus = MTNetworkStatusUnknow;
        _autoReconnectinterval = kDefaultInterval;
        _timeout = kDefaultTimeout;
    }
    return self;
}

- (void)dealloc {
    
}

- (void)startNetworkNotify:(void (^)(MTNetworkStatus networkStatus))status {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.autoReconnectinterval target:self selector:@selector(repeatPing) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    [self.timer fire];
    
    self.notify = [status copy];
    __weak typeof(self) weakSelf = self;
    [self.moniter startNotifier:^(MTNetworkType moniter) {
        [weakSelf callBlockWithPostNoteStatus:moniter];
    }];
}

- (void)stopNotify {
    [self.timer invalidate];
    self.timer = nil;
    [self.ping stop];
    [self.moniter stopNotifier];
}

- (void)callBlockWithPostNoteStatus:(MTNetworkType)type {
    if (self.moniterType != type) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pingFeedback) object:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self repeatPing];
        });
    }
    
    self.moniterType = type;
    if (type == MTNetworkNotReachable) {
        [self handleStatus:MTNetworkStatusNoReachable];
    }
}

- (void)handleStatus:(MTNetworkStatus)status {
    if (_networkStatus == status) {
        return;
    }
    
    _networkStatus = status;
    !self.notify ?: self.notify (status);
    [[NSNotificationCenter defaultCenter] postNotificationName:MTRealReachabilityChangedNotification object:@(status)];
}

- (void)sendPing {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pingFeedback) object:nil];
    if (self.moniterType == MTNetworkNotReachable) {
        return;
    }
    _isReachable = NO;
    [self performSelector:@selector(pingFeedback) withObject:nil afterDelay:self.timeout];
    [self.ping sendPingWithData:nil];
}


- (void)pingFeedback {
    
    if (self.moniterType == MTNetworkViaWiFi) {
        if (_isReachable) {
            [self handleStatus:MTNetworkStatusWifiNormal];
        } else {
            [self handleStatus:MTNetworkStatusWifiLowSpeed];
        }
    }
    
    if (self.moniterType == MTNetworkViaWWAN) {
        if (_isReachable) {
            [self handleStatus:MTNetworkStatusWWANNormal];
        } else {
            [self handleStatus:MTNetworkStatusWWANLowSpeed];
        }
    }
}

- (void)repeatPing {
    [self.ping stop];
    if (self.moniterType != MTNetworkNotReachable) {
        [self startPing];
    } else {
        [self handleStatus:MTNetworkStatusNoReachable];
    }
}

- (void)startPing {
    [self.ping start];
    _isReachable = NO;
    [self performSelector:@selector(pingFeedback) withObject:nil afterDelay:self.timeout];
}

- (void)pingFailured:(MTSimplePing *)pinger {
    _isReachable = NO;
    self.pingValue = -1.0;
    [self pingFeedback];
}

#pragma mark - PingFoundationDelegate


- (void)mtsimplePing:(MTSimplePing *)pinger didStartWithAddress:(NSData *)address {
    [self sendPing];
}

- (void)mtsimplePing:(MTSimplePing *)pinger didFailWithError:(NSError *)error {
    [self pingFailured:pinger];
}

- (void)mtsimplePing:(MTSimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
    self.pingTime = CACurrentMediaTime();
}

- (void)mtsimplePing:(MTSimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error {
    [self pingFailured:pinger];
}

- (void)mtsimplePing:(MTSimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
    
    self.pingValue = (CACurrentMediaTime() - self.pingTime) * 1000.0;
    _isReachable = YES;
    [self pingFeedback];
}

- (void)mtsimplePing:(MTSimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet {
    
}


- (void)setTimeout:(CGFloat)timeout {
    if (timeout >= kMinTimeout && timeout <= kMaxTimeout) {
        _timeout = timeout;
    } else {
        _timeout = kDefaultTimeout;
    }
    if (_timeout > _autoReconnectinterval) {
        _timeout = _autoReconnectinterval - 1.0;
    }
}

- (void)setAutoReconnectinterval:(CGFloat)autoReconnectinterval {
    _autoReconnectinterval = autoReconnectinterval;
    if (autoReconnectinterval < kMinInterval) {
        _autoReconnectinterval = kMinInterval;
    }
    if (_timeout > _autoReconnectinterval) {
        _autoReconnectinterval = _timeout + 1.0;
    }
}

- (MTWWANState)wwanState {
    if (!_networkInfo) {
        return MTWWANStateUnknow;
    }
    NSString *ctNetworkState = _networkInfo.currentRadioAccessTechnology;
    if (!ctNetworkState) {
        return MTWWANStateUnknow;
    }
    MTWWANState currentState = wwanStateFromCT(ctNetworkState);
    return currentState;
}



@end
