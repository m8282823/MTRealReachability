# MTRealReachability
# 结合simplePing和reachability来检测网络状况

# 使用方法:
```Objective-C
    1.block 
    [[MTRealReachability shareManager] startNetworkNotify:^(MTNetworkStatus networkStatus) {
        \\\add your code
    }];
    
    2.notification 
    [[MTRealReachability shareManager] startNetworkNotify:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logNetworkStatus:)             name:MTRealReachabilityChangedNotification object:nil];
```       

# 使用 cocoapods
* pod 'MTRealReachability'   
* platform :ios, '8.0'
 
# Manual
手动拖拽`MTRealReachability`文件夹下的6个文件


## 目前的版本:0.0.4
请使用最新版本
####历史版本: 0.0.3

### 参考
@dustturtle的[RealReachability](https://github.com/dustturtle/RealReachability#demo)

# LiCENSE
使用MIT许可协议,详情请见LICENSE文件
