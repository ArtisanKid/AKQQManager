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

extern const NSString * const AKQQManagerErrorKeyCode;
extern const NSString * const AKQQManagerErrorKeyAlert;
extern const NSString * const AKQQManagerErrorKeyDetail;

typedef void (^AKQQManagerSuccess)();
typedef void (^AKQQManagerLoginSuccess)(id<AKQQUserProtocol> user);
typedef void (^AKQQManagerFailure)(NSError *error);

@interface AKQQManager : NSObject

+ (void)setAppID:(NSString *)appID secretKey:(NSString *)secretKey;

//设置商家ID
+ (void)setPartnerID:(NSString *)partnerID;

/**
 标准单例模式
 
 @return AKQQManager
 */
+ (AKQQManager *)manager;

//处理从Application回调方法获取的URL
+ (BOOL)handleOpenURL:(NSURL *)url;

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
