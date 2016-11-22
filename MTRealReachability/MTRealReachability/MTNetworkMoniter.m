//
//  MTNetworkMoniter.m
//  MTRealReachability
//
//  Created by martin on 2016/10/26.
//  Copyright © 2016年 martin. All rights reserved.
//

#import "MTNetworkMoniter.h"
#import <arpa/inet.h>
#import <SystemConfiguration/SystemConfiguration.h>

NSString *MTNetworkChangedNotification = @"kNetworkChangedNotification";

static void MTNetworkMonitorCallBack(
                                     SCNetworkReachabilityRef target,
                                     SCNetworkReachabilityFlags flags,
                                     void * __nullable info)
{
    
    MTNetworkMoniter *noteObject = (__bridge MTNetworkMoniter *)info;
    dispatch_async(dispatch_get_main_queue(), ^{
        !noteObject.notifyBlock ?: noteObject.notifyBlock(noteObject.currentNetworkStatus);
        [[NSNotificationCenter defaultCenter] postNotificationName:MTNetworkChangedNotification object:noteObject];
    });
    
}

@interface MTNetworkMoniter ()

@property (nonatomic, copy, readwrite) void(^notifyBlock)(MTNetworkType networkType);

@end

@implementation MTNetworkMoniter {
    SCNetworkReachabilityRef _networkMoniterRef;
    
    
}

- (instancetype)initWithRef:(SCNetworkReachabilityRef )ref WithHost:(NSString *)hostName
{
    self = [super init];
    if (self) {
        if (!ref) {
            return nil;
        }
        _networkMoniterRef = ref;
        
    }
    return self;
}


+ (instancetype)moniterWithHostName:(NSString *)hostName {
    SCNetworkReachabilityRef networkMoniterRef = SCNetworkReachabilityCreateWithName(NULL, hostName.UTF8String);
    return [[self alloc] initWithRef:networkMoniterRef WithHost:hostName];
}

+ (instancetype)moniterWithAddress:(const struct sockaddr *)hostAddress {
    SCNetworkReachabilityRef networkMoniterRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, hostAddress);
    return [[self alloc] initWithRef:networkMoniterRef WithHost:@"www.apple.com"];
}

+ (instancetype)moniterForInternetConnection {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    return [self moniterWithAddress:(const struct sockaddr *)&zeroAddress];
}

- (void)dealloc {
    [self stopNotifier];
    if (_networkMoniterRef != NULL) {
        CFRelease(_networkMoniterRef);
        _networkMoniterRef = NULL;
    }
}

- (BOOL)startNotifier:(void (^)(MTNetworkType))networkType
{
    BOOL returnValue = NO;
    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    if (networkType) {
        self.notifyBlock = [networkType copy];
    }
    if (SCNetworkReachabilitySetCallback(_networkMoniterRef, MTNetworkMonitorCallBack, &context)) {
        if (SCNetworkReachabilityScheduleWithRunLoop(_networkMoniterRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes)) {
            SCNetworkReachabilitySetDispatchQueue(_networkMoniterRef, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
            returnValue = YES;
        }
    }
    
    return returnValue;
}

- (void)stopNotifier {
    if (_networkMoniterRef != NULL) {
        SCNetworkReachabilityUnscheduleFromRunLoop(_networkMoniterRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        SCNetworkReachabilitySetCallback(_networkMoniterRef, NULL, NULL);
        SCNetworkReachabilitySetDispatchQueue(_networkMoniterRef, NULL);
    }
}

- (MTNetworkType)currentNetworkStatus {
    MTNetworkType status = MTNetworkNotReachable;
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(_networkMoniterRef, &flags)) {
        
        if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
            return MTNetworkNotReachable;
        }
        if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
            status = MTNetworkViaWiFi;
            
        }
        if (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) ||
            (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0) {
            if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
                status = MTNetworkViaWiFi;
            }
        }
        if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
        {
            status = MTNetworkViaWWAN;
        }
    }
    
    return status;
}




@end
