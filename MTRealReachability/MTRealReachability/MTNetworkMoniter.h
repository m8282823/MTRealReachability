//
//  MTNetworkMoniter.h
//  MTRealReachability
//
//  Created by martin on 2016/10/26.
//  Copyright © 2016年 martin. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, MTNetworkType) {
    MTNetworkUnknown            = -1,
    MTNetworkNotReachable       = 0,
    MTNetworkViaWiFi            = 2,
    MTNetworkViaWWAN            = 3
};



extern NSString *MTNetworkChangedNotification;


@interface MTNetworkMoniter : NSObject

@property (nonatomic, copy, readonly) void(^notifyBlock)(MTNetworkType networkType);

+ (instancetype)moniterWithHostName:(NSString *)hostName;

+ (instancetype)moniterWithAddress:(const struct sockaddr *)hostAddress;

+ (instancetype)moniterForInternetConnection;

- (instancetype)init NS_UNAVAILABLE;

- (BOOL)startNotifier:(void (^)(MTNetworkType networkType))networkMoniter;

- (void)stopNotifier;

- (MTNetworkType)currentNetworkStatus;




@end
