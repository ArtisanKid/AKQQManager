//
//  AKQQManager.h
//  Pods
//
//  Created by 李翔宇 on 2017/1/22.
//
//

#import <Foundation/Foundation.h>
#import "AKQQUserProtocol.h"
#import "AKQQShareProtocol.h"

NS_ASSUME_NONNULL_BEGIN

extern const NSString * const AKQQManagerErrorCodeKey;
extern const NSString * const AKQQManagerErrorMessageKey;
extern const NSString * const AKQQManagerErrorDetailKey;

typedef void (^AKQQManagerSuccess)();
typedef void (^AKQQManagerFailure)(NSError *error);

typedef void (^AKQQManagerLoginSuccess)(id<AKQQUserProtocol> user);

/**
 SDK文档：http://wiki.open.qq.com/wiki/IOS_API%E8%B0%83%E7%94%A8%E8%AF%B4%E6%98%8E
 API列表：http://wiki.open.qq.com/wiki/API%E5%88%97%E8%A1%A8
 */

@interface AKQQManager : NSObject

/**
 标准单例模式
 
 @return AKQQManager
 */
+ (AKQQManager *)manager;

@property (class, nonatomic, assign, getter=isDebug) BOOL debug;

+ (void)setAppID:(NSString *)appID secretKey:(NSString *)secretKey;

//设置商家ID
+ (void)setPartnerID:(NSString *)partnerID;

//处理从Application回调方法获取的URL
+ (BOOL)handleOpenURL:(NSURL *)url;

/**
 联合登录

 @param success 成功的Block
 @param failure 失败的Block
 */
+ (void)loginSuccess:(AKQQManagerLoginSuccess)success
             failure:(AKQQManagerFailure)failure;

/**
 分享文字，图片，视频等到QQ或者QZone

 @param item 遵循AKQQShareProtocol协议的分享对象
 @param scene AKQQShareScene 分享到的位置
 @param success 成功的Block
 @param failure 失败的Block
 */
+ (void)share:(id<AKQQShareProtocol>)item
        scene:(AKQQShareScene)scene
      success:(AKQQManagerSuccess _Nullable)success
      failure:(AKQQManagerFailure _Nullable)failure;

/**
 支付

 @param orderID 订单号
 @param source 支付来源信息
 @param success 成功的Block
 @param failure 失败的Block
 */
+ (void)pay:(NSString *)orderID
     source:(NSString *)source
    success:(AKQQManagerSuccess _Nullable)success
    failure:(AKQQManagerFailure _Nullable)failure;

@end

NS_ASSUME_NONNULL_END
