//
//  MTRealReachability.h
//  MTRealReachability
//
//  Created by martin on 2016/10/26.
//  Copyright © 2016年 martin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

extern NSString *MTRealReachabilityChangedNotification;

typedef NS_ENUM(NSInteger, MTWWANState) {
    MTWWANStateUnknow = -1,
    MTWWANState2G     = 2,
    MTWWANState3G     = 3,
    MTWWANState4G     = 4
};

typedef NS_ENUM(NSInteger, MTNetworkStatus) {
    MTNetworkStatusUnknow         = -1,
    MTNetworkStatusNoReachable,
    MTNetworkStatusWifiNormal,
    MTNetworkStatusWWANNormal,
    MTNetworkStatusWifiLowSpeed,
    MTNetworkStatusWWANLowSpeed
};

@interface MTRealReachability : NSObject

/**
 default is 3.0 minutes
 */
@property (nonatomic, assign) CGFloat timeout;

/**
 default is 30.0 minutes
 */
@property (nonatomic, assign) CGFloat autoReconnectinterval;

/**
 pingValue in second
 */
@property (nonatomic, assign, readonly) CFTimeInterval pingValue;

@property (nonatomic, assign, readonly) MTNetworkStatus networkStatus;

@property (nonatomic, assign, readonly) MTWWANState wwanState NS_AVAILABLE_IOS(7.0);


/**
 default  hostname is "www.apple.com"
 
 @return <#return value description#>
 */
+ (instancetype)shareManager;

+ (instancetype)manager;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithHost:(NSString *)hostName;

- (void)startNetworkNotify:(void (^)(MTNetworkStatus networkStatus))status;

/**
 *must call stopNotify after you finished using startNotify
 *otherwise the object can not be deallocted
 */
- (void)stopNotify;


@end
