//
//  AKQQManager.m
//  Pods
//
//  Created by 李翔宇 on 2017/1/22.
//
//

#import "AKQQManager.h"
#import <AKQQSDK/TencentOAuth.h>
#import <AKQQSDK/QQApiInterface.h>
#import "AKQQManagerMacro.h"
#import "AKQQUser.h"

const NSString * const AKQQManagerErrorCodeKey = @"code";
const NSString * const AKQQManagerErrorMessageKey = @"message";
const NSString * const AKQQManagerErrorDetailKey = @"detail";

const NSString * const AKQQManagerMessageTypeKey = @"type";
typedef NS_ENUM(NSUInteger, AKQQMessageType) {
    AKQQMessageTypeNone = 0,
    AKQQMessageTypeShare = 1,
    AKQQMessageTypePay = 2
};

@interface AKQQManager () <TencentSessionDelegate, QQApiInterfaceDelegate>

@property (nonatomic, assign, getter=isDebug) BOOL debug;

@property (nonatomic, strong) NSString *appID;
@property (nonatomic, strong) NSString *secretKey;

@property (nonatomic, strong) NSString *partnerID;

@property (nonnull, strong) TencentOAuth *oauth;
@property (nonnull, strong) NSArray *permissions;
@property (nonatomic, strong) AKQQManagerLoginSuccess loginSuccess;
@property (nonatomic, strong) AKQQManagerFailure loginFailure;

@property (nonatomic, strong) AKQQManagerSuccess shareSuccess;
@property (nonatomic, strong) AKQQManagerFailure shareFailure;

@property (nonatomic, strong) AKQQManagerSuccess paySuccess;
@property (nonatomic, strong) AKQQManagerFailure payFailure;

@property (nonatomic, strong) AKQQUser *user;

@end

@implementation AKQQManager

+ (AKQQManager *)manager {
    static AKQQManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
        sharedInstance.user = [[AKQQUser alloc] init];
        sharedInstance.permissions = @[kOPEN_PERMISSION_ADD_TOPIC,
                                       kOPEN_PERMISSION_ADD_SHARE,
                                       kOPEN_PERMISSION_GET_INFO,
                                       kOPEN_PERMISSION_GET_OTHER_INFO,
                                       kOPEN_PERMISSION_GET_USER_INFO,
                                       kOPEN_PERMISSION_GET_SIMPLE_USER_INFO];
    });
    return sharedInstance;
}

+ (id)alloc {
    return [self manager];
}

+ (id)allocWithZone:(NSZone * _Nullable)zone {
    return [self manager];
}

- (id)copy {
    return self;
}

- (id)copyWithZone:(NSZone * _Nullable)zone {
    return self;
}

#pragma mark- Public Method
+ (void)setDebug:(BOOL)debug {
    self.manager.debug = debug;
}

+ (BOOL)isDebug {
    return self.manager.isDebug;
}

+ (void)setAppID:(NSString *)appID secretKey:(NSString *)secretKey {
    self.manager.appID = appID;
    self.manager.secretKey = secretKey;
    self.manager.oauth = [[TencentOAuth alloc] initWithAppId:appID andDelegate:self.manager];
}

+ (void)setPartnerID:(NSString *)partnerID {
    self.manager.partnerID = partnerID;
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    //首先由QQApiInterface来判断是不是OSS请求
    //如果不是那么再判断是不是TencentOAuth请求
    BOOL handle = [QQApiInterface handleOpenURL:url delegate:self.manager];
    if(!handle) {
        handle = [TencentOAuth HandleOpenURL:url];
    }
    return handle;
}

+ (void)loginSuccess:(AKQQManagerLoginSuccess)success
             failure:(AKQQManagerFailure)failure {
    if(![self.manager checkAppInstalled]) {
        [self.manager failure:failure message:@"未安装QQ"];
        return;
    }
    
    if(![self.manager checkAppVersion]) {
        [self.manager failure:failure message:@"QQ版本过低"];
        return;
    }
    
    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    if(self.manager.oauth.isSessionValid) {
        if(self.manager.user.expiredTime - now >= 60) {
            !success ? : success(self.manager.user);
            return;
        } else {
            BOOL result = [self.manager.oauth reauthorizeWithPermissions:self.manager.permissions];
            if(!result) {
                NSString *detail = [TencentOAuth getLastErrorMsg];
                [self.manager failure:failure code:0 message:@"ReAuth请求发送失败" detail:detail];
                return;
            }
        }
    } else {
        if(self.manager.user.accessToken.length) {
            BOOL result = [self.manager.oauth reauthorizeWithPermissions:self.manager.permissions];
            if(!result) {
                NSString *detail = [TencentOAuth getLastErrorMsg];
                [self.manager failure:failure code:0 message:@"ReAuth请求发送失败" detail:detail];
                return;
            }
        } else {
            BOOL result = [self.manager.oauth authorize:self.manager.permissions];
            if(!result) {
                NSString *detail = [TencentOAuth getLastErrorMsg];
                [self.manager failure:failure code:0 message:@"Auth请求发送失败" detail:detail];
                return;
            }
        }
    }
    
    self.manager.loginSuccess = success;
    self.manager.loginFailure = failure;
}

+ (void)share:(id<AKQQShareProtocol>)item
        scene:(AKQQShareScene)scene
      success:(AKQQManagerSuccess)success
      failure:(AKQQManagerFailure)failure {
    if(![self.manager checkAppInstalled]) {
        [self.manager failure:failure message:@"未安装QQ"];
        return;
    }
    
    if(![self.manager checkAppVersion]) {
        [self.manager failure:failure message:@"QQ版本过低"];
        return;
    }
    
    SendMessageToQQReq *request = [item request];
    QQApiSendResultCode code = EQQAPISENDSUCESS;
    if(scene == AKQQShareSceneQQ) {
        code = [QQApiInterface sendReq:request];
    } else {
        code = [QQApiInterface SendReqToQZone:request];
    }
    
    if(code != EQQAPISENDSUCESS) {
        NSString *message = [self.manager alertForSend:code];
        [self.manager failure:failure code:code message:message detail:nil];
        return;
    }
    
    self.manager.shareSuccess = success;
    self.manager.shareFailure = failure;
}

+ (void)pay:(NSString *)orderID
     source:(NSString *)source
    success:(AKQQManagerSuccess)success
    failure:(AKQQManagerFailure)failure {
    AKQQ_String_Nilable_Return(self.manager.partnerID, NO, {
        [self.manager failure:failure message:@"未设置partnerID"];
    });
    
    AKQQ_String_Nilable_Return(orderID, NO, {
        [self.manager failure:failure message:@"未设置orderID"];
    });
    
    AKQQ_String_Nilable_Return(source, NO, {
        [self.manager failure:failure message:@"未设置source"];
    });
    
    QQApiPayObject *pay = [[QQApiPayObject alloc] init];
    pay.OrderNo = orderID; ///<支付订单号，必填
    pay.AppInfo = source; ///<支付来源信息，必填
    
    SendMessageToQQReq *request = [SendMessageToQQReq reqWithContent:pay];
    
    QQApiSendResultCode code = [QQApiInterface sendReq:request];
    if(code != EQQAPISENDSUCESS) {
        NSString *message = [self.manager alertForSend:code];
        [self.manager failure:failure code:code message:message detail:nil];
        return;
    }
    
    self.manager.paySuccess = success;
    self.manager.payFailure = failure;
}

#pragma mark - TencentLoginDelegate

/**
 * 登录成功后的回调
 */
- (void)tencentDidLogin {
    self.user.accessToken = self.oauth.accessToken;
    self.user.refreshToken = nil;
    self.user.expiredTime = self.oauth.expirationDate.timeIntervalSince1970;
    self.user.openID = self.oauth.openId;
    self.user.unionID = self.oauth.unionid;
    
    if([self.oauth getUserInfo]) {
        if(AKQQManager.isDebug) {
            AKQQManagerLog(@"登录成功，正在获取用户信息...");
        }
        
        if([self.oauth RequestUnionId]) {
            if(AKQQManager.isDebug) {
                AKQQManagerLog(@"登录成功，正在获取UnionID...");
            }
        } else {
            if(AKQQManager.isDebug) {
                AKQQManagerLog(@"登录成功，获取UnionID失败");
            }
        }
    } else {
        NSInteger code = [[self.oauth getServerSideCode] integerValue];
        NSString *detail = [TencentOAuth getLastErrorMsg];
        [self failure:self.loginFailure code:code message:@"登录成功，获取用户信息失败" detail:detail];
        
        [self.user invalid];
        self.loginSuccess = nil;
        self.loginFailure = nil;
    }
}

/**
 * 登录失败后的回调
 * \param cancelled 代表用户是否主动退出登录
 */
- (void)tencentDidNotLogin:(BOOL)cancelled {
    NSInteger code = [[self.oauth getServerSideCode] integerValue];
    NSString *message = nil;
    if(cancelled) {
        message = @"取消登录";
    } else {
        message = @"登录失败";
    }
    NSString *detail = [TencentOAuth getLastErrorMsg];
    [self failure:self.loginFailure code:code message:message detail:detail];
    
    [self.user invalid];
    self.loginSuccess = nil;
    self.loginFailure = nil;
}

/**
 * 登录时网络有问题的回调
 */
- (void)tencentDidNotNetWork {
    NSInteger code = [[self.oauth getServerSideCode] integerValue];
    NSString *detail = [TencentOAuth getLastErrorMsg];
    [self failure:self.loginFailure code:code message:@"登录失败，网络异常" detail:detail];
    
    [self.user invalid];
    self.loginSuccess = nil;
    self.loginFailure = nil;
}

/**
 * 登录时权限信息的获得
 */
- (NSArray *)getAuthorizedPermissions:(NSArray *)permissions withExtraParams:(NSDictionary *)extraParams {
    return nil;
}

/**
 * unionID获得
 */
- (void)didGetUnionID {
    if(AKQQManager.isDebug) {
        AKQQManagerLog(@"获取unionID");
    }
    
    self.user.unionID = self.oauth.unionid;
}

#pragma mark - TencentSessionDelegate

/**
 * 退出登录的回调
 */
- (void)tencentDidLogout {
    if(AKQQManager.isDebug) {
        AKQQManagerLog(@"用户退出登录");
    }
    [self.user invalid];
}

/**
 * 因用户未授予相应权限而需要执行增量授权。在用户调用某个api接口时，如果服务器返回操作未被授权，则触发该回调协议接口，由第三方决定是否跳转到增量授权页面，让用户重新授权。
 * \param tencentOAuth 登录授权对象。
 * \param permissions 需增量授权的权限列表。
 * \return 是否仍然回调返回原始的api请求结果。
 * \note 不实现该协议接口则默认为不开启增量授权流程。若需要增量授权请调用\ref TencentOAuth#incrAuthWithPermissions: \n注意：增量授权时用户可能会修改登录的帐号
 */
- (BOOL)tencentNeedPerformIncrAuth:(TencentOAuth *)tencentOAuth withPermissions:(NSArray *)permissions {
    if(AKQQManager.isDebug) {
        AKQQManagerLog(@"授权范围不足，需扩大授权范围");
    }
    return YES;
}

/**
 * [该逻辑未实现]因token失效而需要执行重新登录授权。在用户调用某个api接口时，如果服务器返回token失效，则触发该回调协议接口，由第三方决定是否跳转到登录授权页面，让用户重新授权。
 * \param tencentOAuth 登录授权对象。
 * \return 是否仍然回调返回原始的api请求结果。
 * \note 不实现该协议接口则默认为不开启重新登录授权流程。若需要重新登录授权请调用\ref TencentOAuth#reauthorizeWithPermissions: \n注意：重新登录授权时用户可能会修改登录的帐号
 */
- (BOOL)tencentNeedPerformReAuth:(TencentOAuth *)tencentOAuth {
    if(AKQQManager.isDebug) {
        AKQQManagerLog(@"授权信息过期，需重新授权");
    }
    return YES;
}

/**
 * 用户通过增量授权流程重新授权登录，token及有效期限等信息已被更新。
 * \param tencentOAuth token及有效期限等信息更新后的授权实例对象
 * \note 第三方应用需更新已保存的token及有效期限等信息。
 */
- (void)tencentDidUpdate:(TencentOAuth *)tencentOAuth {
    if(AKQQManager.isDebug) {
        AKQQManagerLog(@"更新授权信息成功");
    }
}

/**
 * 用户增量授权过程中因取消或网络问题导致授权失败
 * \param reason 授权失败原因，具体失败原因参见sdkdef.h文件中\ref UpdateFailType
 */
- (void)tencentFailedUpdate:(UpdateFailType)reason {
    if(AKQQManager.isDebug) {
        AKQQManagerLog(@"更新授权信息失败");
    }
}

/**
 * 获取用户个人信息回调
 * \param response API返回结果，具体定义参见sdkdef.h文件中\ref APIResponse
 * \remarks 正确返回示例: \snippet example/getUserInfoResponse.exp success
 *          错误返回示例: \snippet example/getUserInfoResponse.exp fail
 */
- (void)getUserInfoResponse:(APIResponse *)response {
    if(response.retCode != URLREQUEST_SUCCEED) {
        NSString *message = [self alertForNetwork:response.retCode];
        [self failure:self.loginFailure code:response.retCode message:message detail:response.errorMsg];
        
        self.loginSuccess = nil;
        self.loginFailure = nil;
        return;
    }
    
    if(response.detailRetCode != kOpenSDKErrorSuccess) {
        NSString *message = [self alertForOpenAPI:response.detailRetCode];
        [self failure:self.loginFailure code:response.detailRetCode message:message detail:response.errorMsg];
        
        self.loginSuccess = nil;
        self.loginFailure = nil;
        return;
    }
    
    //这些做SDK的都是傻逼么...SDK文档缺失太严重了，没有返回的字段说明！！！
    //获取用户信息相关文档在这里：http://wiki.connect.qq.com/get_user_info
    
    NSString *nickname = response.jsonResponse[@"nickname"];
    if([nickname isKindOfClass:[NSString class]]
       && nickname.length) {
        self.user.nickname = nickname;
    }
    
    NSString *portrait = response.jsonResponse[@"figureurl_qq_2"];
    if(![portrait isKindOfClass:[NSString class]]
       || !portrait.length) {
        portrait = response.jsonResponse[@"figureurl_qq_1"];
    }
    if([portrait isKindOfClass:[NSString class]]
       && portrait.length) {
        self.user.portrait = portrait;
    }
    
    !self.loginSuccess ? : self.loginSuccess(self.user);
    
    self.loginSuccess = nil;
    self.loginFailure = nil;
}

#pragma mark - QQApiInterfaceDelegate
/*
 ESHOWMESSAGEFROMQQRESPTYPE = 0, ///< 第三方应用 -> 手Q，第三方应用应答消息展现结果
 EGETMESSAGEFROMQQRESPTYPE = 1,  ///< 第三方应用 -> 手Q，第三方应用回应发往手Q的消息
 ESENDMESSAGETOQQRESPTYPE = 2    ///< 手Q -> 第三方应用，手Q应答处理分享消息的结果
 */

/**
 处理来至QQ的响应
 */
- (void)onResp:(QQBaseResp *)resp {
    switch (resp.type) {
        case ESENDMESSAGETOQQRESPTYPE: {
            if(![resp isKindOfClass:[SendMessageToQQResp class]]) {
                return;
            }
            
            if(![resp.extendInfo isKindOfClass:[NSString class]]
               || !resp.extendInfo.length) {
                return;
            }
            
            NSData *jsonData = [resp.extendInfo dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error = nil;
            NSDictionary *extendDic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                      options:NSJSONReadingAllowFragments
                                                                        error:&error];
            if(error) {
                if(AKQQManager.isDebug) {
                    AKQQManagerLog(@"%@", error);
                }
                return;
            }
            
            AKQQMessageType type = [extendDic[AKQQManagerMessageTypeKey] integerValue];
            
#warning 这里是瞎写的，需要找到文档进行确认
            if(![resp.result isEqualToString:@"success"]) {
                switch (type) {
                    case AKQQMessageTypeShare: {
                        [self failure:self.shareFailure code:0 message:resp.result detail:resp.errorDescription];
                        
                        self.shareSuccess = nil;
                        self.shareFailure = nil;
                        break;
                    }
                    case AKQQMessageTypePay: {
                        [self failure:self.payFailure code:0 message:resp.result detail:resp.errorDescription];
                        
                        self.paySuccess = nil;
                        self.payFailure = nil;
                        break;
                    }
                        
                    default: break;
                }
                return;
            }
            
            switch (type) {
                case AKQQMessageTypeShare: {
                    !self.shareSuccess ? : self.shareSuccess();
                    
                    self.shareSuccess = nil;
                    self.shareFailure = nil;
                    break;
                }
                case AKQQMessageTypePay: {
                    !self.paySuccess ? : self.paySuccess();
                    
                    self.paySuccess = nil;
                    self.payFailure = nil;
                    break;
                }
                    
                default: break;
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark- Private Method
/*
 URLREQUEST_SUCCEED = 0, //网络请求成功发送至服务器，并且服务器返回数据格式正确。这里包括所请求业务操作失败的情况，例如没有授权等原因导致
 URLREQUEST_FAILED = 1, //网络异常，或服务器返回的数据格式不正确导致无法解析
 */
- (NSString *)alertForNetwork:(REPONSE_RESULT)networkCode {
    NSString *alert = nil;
    switch (networkCode) {
        case URLREQUEST_SUCCEED: { alert = @"请求成功"; break; }
        case URLREQUEST_FAILED: { alert = @"网络异常，或服务器返回的数据格式不正确导致无法解析"; break; }
        default: break;
    }
    return alert;
}

/*
 kOpenSDKInvalid = -1,                       ///< 无效的错误码
 kOpenSDKErrorUnsupportedAPI = -2,                ///< 不支持的接口
 
 ///公共错误码 CommonErrorCode
 kOpenSDKErrorSuccess = 0,                   ///< 成功
 kOpenSDKErrorUnknown,                       ///< 未知错误
 kOpenSDKErrorUserCancel,                    ///< 用户取消
 kOpenSDKErrorReLogin,                       ///< token无效或用户未授权相应权限需要重新登录
 kOpenSDKErrorOperationDeny,                 ///< 第三方应用没有该api操作的权限
 
 ///网络相关错误码 NetworkRelatedErrorCode
 kOpenSDKErrorNetwork,                       ///< 网络错误，网络不通或连接不到服务器
 kOpenSDKErrorURL,                           ///< URL格式或协议错误
 kOpenSDKErrorDataParse,                     ///< 数据解析错误，服务器返回的数据解析出错
 kOpenSDKErrorParam,                         ///< 传入参数错误
 kOpenSDKErrorConnTimeout,                   ///< http连接超时
 kOpenSDKErrorSecurity,                      ///< 安全问题
 kOpenSDKErrorIO,                            ///< 下载和文件IO错误
 kOpenSDKErrorServer,                        ///< 服务器端错误
 
 ///webview特有错误 WebViewRelatedError
 kOpenSDKErrorWebPage,                       ///< 页面错误
 
 ///设置头像自定义错误码段 SetUserHeadRelatedErrorCode
 kOpenSDKErrorUserHeadPicLarge = 0x010000,   ///< 图片过大 设置头像自定义错误码
 */
- (NSString *)alertForOpenAPI:(OpenSDKError)detailCode {
    NSString *alert = nil;
    switch (detailCode) {
        case kOpenSDKInvalid: alert = @"无效的错误码"; break;
        case kOpenSDKErrorUnsupportedAPI: alert = @"不支持的接口"; break;
            
            ///公共错误码 CommonErrorCode
        case kOpenSDKErrorSuccess: alert = @"成功"; break;
        case kOpenSDKErrorUnknown: alert = @"未知错误"; break;
        case kOpenSDKErrorUserCancel: alert = @"用户取消"; break;
        case kOpenSDKErrorReLogin: alert = @"token无效或用户未授权相应权限需要重新登录"; break;
        case kOpenSDKErrorOperationDeny: alert = @"第三方应用没有该api操作的权限"; break;
            
            ///网络相关错误码 NetworkRelatedErrorCode
        case kOpenSDKErrorNetwork: alert = @"网络错误，网络不通或连接不到服务器"; break;
        case kOpenSDKErrorURL: alert = @"URL格式或协议错误"; break;
        case kOpenSDKErrorDataParse: alert = @"数据解析错误，服务器返回的数据解析出错"; break;
        case kOpenSDKErrorParam: alert = @"传入参数错误"; break;
        case kOpenSDKErrorConnTimeout: alert = @"http连接超时"; break;
        case kOpenSDKErrorSecurity: alert = @"安全问题"; break;
        case kOpenSDKErrorIO: alert = @"下载和文件IO错误"; break;
        case kOpenSDKErrorServer: alert = @"服务器端错误"; break;
            
            ///webview特有错误 WebViewRelatedError
        case kOpenSDKErrorWebPage: alert = @"页面错误"; break;
            
            ///设置头像自定义错误码段 SetUserHeadRelatedErrorCode
        case kOpenSDKErrorUserHeadPicLarge: alert = @"图片过大 设置头像自定义错误码"; break;
            
        default: break;
    }
    return alert;
}

/*
 EQQAPISENDSUCESS = 0,
 EQQAPIQQNOTINSTALLED = 1,
 EQQAPIQQNOTSUPPORTAPI = 2,
 EQQAPIMESSAGETYPEINVALID = 3,
 EQQAPIMESSAGECONTENTNULL = 4,
 EQQAPIMESSAGECONTENTINVALID = 5,
 EQQAPIAPPNOTREGISTED = 6,
 EQQAPIAPPSHAREASYNC = 7,
 EQQAPIQQNOTSUPPORTAPI_WITH_ERRORSHOW = 8,
 EQQAPISENDFAILD = -1,
 EQQAPIQZONENOTSUPPORTTEXT = 10000,//qzone分享不支持text类型分享
 EQQAPIQZONENOTSUPPORTIMAGE = 10001,//qzone分享不支持image类型分享
 EQQAPIVERSIONNEEDUPDATE = 10002,//当前QQ版本太低，需要更新至新版本才可以支持
 */
- (NSString *)alertForSend:(QQApiSendResultCode)code {
    NSString *alert = nil;
    switch (code) {
        case EQQAPIQQNOTINSTALLED: alert = @"QQ未安装"; break;
        case EQQAPIQQNOTSUPPORTAPI: alert = @"QQ不支持此API"; break;
        case EQQAPIMESSAGETYPEINVALID: alert = @"消息类型无效"; break;
        case EQQAPIMESSAGECONTENTNULL: alert = @"内容为空"; break;
        case EQQAPIMESSAGECONTENTINVALID: alert = @"内容无效"; break;
        case EQQAPIAPPNOTREGISTED: alert = @"应用未注册"; break;
        case EQQAPIAPPSHAREASYNC: alert = @"同步分享操作"; break;
        case EQQAPIQQNOTSUPPORTAPI_WITH_ERRORSHOW: alert = @""; break;
        case EQQAPISENDFAILD: alert = @"发送失败"; break;
        case EQQAPIQZONENOTSUPPORTTEXT: alert = @"QZone分享不支持文本类型消息"; break;
        case EQQAPIQZONENOTSUPPORTIMAGE: alert = @"QZone分享不支持图片类型消息"; break;
        case EQQAPIVERSIONNEEDUPDATE: alert = @"当前QQ版本太低，需要更新至新版本才可以支持"; break;
        default: break;
    }
}

+ (NSString *)identifier {
    NSTimeInterval timestamp = [NSDate date].timeIntervalSince1970;
    return @(timestamp).description;
}

- (BOOL)checkAppInstalled {
    if([QQApiInterface isQQInstalled]) {
        return YES;
    }
    
    [self showAlert:@"当前您还没有安装QQ，是否安装QQ？"];
    return NO;
}

- (BOOL)checkAppVersion {
    if([QQApiInterface isQQSupportApi]) {
        return YES;
    }
    
    [self showAlert:@"当前QQ版本过低，是否升级？"];
    return NO;
}

- (void)showAlert:(NSString *)alertMessage {
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"提示"
                                          message:alertMessage
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *downloadAction = [UIAlertAction actionWithTitle:@"下载"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               [rootViewController dismissViewControllerAnimated:YES completion:^{
                                                                   NSString *appStoreURL = [QQApiInterface getQQInstallUrl];
                                                                   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appStoreURL]];
                                                               }];
                                                           }];
    UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:@"取消登录"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [rootViewController dismissViewControllerAnimated:YES completion:^{}];
                                                         }];
    [alertController addAction:downloadAction];
    [alertController addAction:cancleAction];
    [rootViewController presentViewController:alertController animated:YES completion:^{}];
}

- (void)failure:(AKQQManagerFailure)failure message:(NSString *)message {
    if(self.isDebug) {
        AKQQManagerLog(@"%@", message);
    }
    
    NSDictionary *userInfo = nil;
    if([message isKindOfClass:[NSString class]]
       && message.length) {
        userInfo = @{AKQQManagerErrorMessageKey : message};
    }
    
    NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                         code:0
                                     userInfo:userInfo];
    !failure ? : failure(error);
}

- (void)failure:(AKQQManagerFailure)failure code:(NSInteger)code message:(NSString *)message detail:(NSString *)detail {
    if(self.isDebug) {
        AKQQManagerLog(@"%@", message);
        AKQQManagerLog(@"%@", detail);
    }
    
    NSMutableDictionary *userInfo = [@{AKQQManagerErrorCodeKey : @(code)} mutableCopy];
    if([message isKindOfClass:[NSString class]]
       && message.length) {
        userInfo[AKQQManagerErrorMessageKey] = message;
    }
    
    if([detail isKindOfClass:[NSString class]]
       && detail.length) {
        userInfo[AKQQManagerErrorDetailKey] = detail;
    }
    
    NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                         code:0
                                     userInfo:[userInfo copy]];
    !failure ? : failure(error);
}

@end
