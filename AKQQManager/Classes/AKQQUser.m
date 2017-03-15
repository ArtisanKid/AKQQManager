//
//  AKQQUser.m
//  Pods
//
//  Created by 李翔宇 on 2017/1/17.
//
//

#import "AKQQUser.h"

@implementation AKQQUser
    
- (void)invalid {
    self.accessToken = nil;
    self.refreshToken = nil;
    self.expiredTime = 0;
    self.openID = nil;
    self.unionID = nil;
    self.nickname = nil;
    self.portrait = nil;
    self.mobile = nil;
    self.motto = nil;
}

@end
