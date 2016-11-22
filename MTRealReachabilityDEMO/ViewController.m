//
//  ViewController.m
//  MTRealReachabilityDEMO
//
//  Created by martin on 2016/10/27.
//  Copyright © 2016年 martin. All rights reserved.
//

#import "ViewController.h"
#import "MTRealReachability/MTRealReachability.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[MTRealReachability shareManager] startNetworkNotify:^(MTNetworkStatus networkStatus) {
        NSLog(@"status = %li",networkStatus);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logNetworkStatus:) name:MTRealReachabilityChangedNotification object:nil];
}

- (void)logNetworkStatus:(NSNotification *)note {
    MTNetworkStatus status = [note.object integerValue];
    NSLog(@"noteStatus = %li",status);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
