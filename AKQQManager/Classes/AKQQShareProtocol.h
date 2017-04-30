//
//  AKQQShareProtocol.h
//  Pods
//
//  Created by 李翔宇 on 2017/1/17.
//
//

#import <Foundation/Foundation.h>
#import <AKQQSDK/QQApiInterfaceObject.h>

typedef NS_ENUM(NSUInteger, AKQQShareScene) {
    AKQQShareSceneNone = 0,
    AKQQShareSceneQQ,//QQ
    AKQQShareSceneQZone,//空间
};

@protocol AKQQShareProtocol <NSObject>

- (SendMessageToQQReq *)request;

@end
