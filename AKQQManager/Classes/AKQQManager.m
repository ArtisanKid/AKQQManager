//
//  AKQQManager.m
//  Pods
//
//  Created by 李翔宇 on 2017/1/22.
//
//

#import "AKQQManager.h"
#import "TencentOAuth.h"
#import "QQApiInterface.h"
#import "AKQQManagerMacro.h"
#import "AKQQUser.h"

const NSString * const AKQQManagerErrorKeyCode = @"code";
const NSString * const AKQQManagerErrorKeyAlert = @"alert";
const NSString * const AKQQManagerErrorKeyDetail = @"errorMsg";

@interface AKQQManager () <TencentSessionDelegate, QQApiInterfaceDelegate>

@property (nonatomic, strong) NSString *appID;
@property (nonatomic, strong) NSString *secretKey;

@property (nonatomic, strong) NSString *partnerID;

@property (nonatomic, strong) AKQQManagerLoginSuccess loginSuccess;
@property (nonatomic, strong) AKQQManagerFailure loginFailure;
@property (nonnull, strong) TencentOAuth *oauth;

@property (nonatomic, strong) AKQQManagerSuccess shareSuccess;
@property (nonatomic, strong) AKQQManagerFailure shareFailure;

@property (nonatomic, strong) AKQQManagerSuccess paySuccess;
@property (nonatomic, strong) AKQQManagerFailure payFailure;

@end

@implementation AKQQManager

+ (AKQQManager *)manager {
    static AKQQManager *weiboManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        weiboManager = [[super allocWithZone:NULL] init];
    });
    return weiboManager;
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
- (NSString *)alertForOpenAPI:(REPONSE_RESULT)detailCode {
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

#pragma mark- Public Method
+ (void)setAppID:(NSString *)appID secretKey:(NSString *)secretKey {
    self.manager.appID = appID;
    self.manager.secretKey = secretKey;
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
    //相关文档在这里：http://wiki.open.qq.com/wiki/IOS_API%E8%B0%83%E7%94%A8%E8%AF%B4%E6%98%8E
    
    self.manager.loginSuccess = success;
    self.manager.loginFailure = failure;
    
    NSArray* permissions = @[kOPEN_PERMISSION_ADD_TOPIC,
                             kOPEN_PERMISSION_ADD_SHARE,
                             kOPEN_PERMISSION_GET_INFO,
                             kOPEN_PERMISSION_GET_OTHER_INFO,
                             kOPEN_PERMISSION_GET_USER_INFO,
                             kOPEN_PERMISSION_GET_SIMPLE_USER_INFO];
    self.manager.oauth = [[TencentOAuth alloc] initWithAppId:self.manager.appID andDelegate:self];
    [self.manager.oauth authorize:permissions inSafari:NO];
}

+ (void)share:(id<AKQQShareProtocol>)item
        scene:(AKQQShareScene)scene
      success:(AKQQManagerSuccess)success
      failure:(AKQQManagerFailure)failure {
    //相关文档在这里：http://wiki.open.qq.com/wiki/IOS_API%E8%B0%83%E7%94%A8%E8%AF%B4%E6%98%8E
    
    AK_QQM_Nilable_Class_Return(self.manager.appID, NO, NSString, {})
    AK_QQM_Nilable_Class_Return(self.manager.partnerID, NO, NSString, {})
    
    self.manager.shareSuccess = success;
    self.manager.shareFailure = failure;
    
    SendMessageToQQReq *request = [item request];
    QQApiSendResultCode code = EQQAPISENDSUCESS;
    if(scene == AKQQShareSceneQQ) {
        code = [QQApiInterface sendReq:request];
    } else {
        code = [QQApiInterface SendReqToQZone:request];
    }
    
    if(code == EQQAPISENDSUCESS) {
        return;
    }
    
    NSString *alert = [self.manager alertForSend:code];
    NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                         code:code
                                     userInfo:@{ AKQQManagerErrorKeyCode : @(code),
                                                 AKQQManagerErrorKeyAlert : alert}];
    !self.manager.shareFailure ? : self.manager.shareFailure(error);
    
    self.manager.shareSuccess = nil;
    self.manager.shareFailure = nil;
}

+ (void)pay:(NSString *)orderID
     source:(NSString *)source
    success:(AKQQManagerSuccess)success
    failure:(AKQQManagerFailure)failure {
    //相关文档在这里：https://pay.QQ.qq.com/wiki/doc/api/app/app.php?chapter=9_12&index=2
    
    AK_QQM_Nilable_Class_Return(self.manager.appID, NO, NSString, {})
    AK_QQM_Nilable_Class_Return(self.manager.partnerID, NO, NSString, {})
    AK_QQM_Nilable_Class_Return(orderID, NO, NSString, {})
    AK_QQM_Nilable_Class_Return(source, NO, NSString, {})
    
    self.manager.paySuccess = success;
    self.manager.payFailure = failure;
    
    QQApiPayObject *pay = [[QQApiPayObject alloc] init];
    pay.OrderNo = orderID; ///<支付订单号，必填
    pay.AppInfo = source; ///<支付来源信息，必填
    
    SendMessageToQQReq *request = [SendMessageToQQReq reqWithContent:pay];
    
    QQApiSendResultCode code = [QQApiInterface sendReq:request];
    if(code == EQQAPISENDSUCESS) {
        return;
    }
    
    NSString *alert = [self.manager alertForSend:code];
    NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                         code:code
                                     userInfo:@{ AKQQManagerErrorKeyCode : @(code),
                                                 AKQQManagerErrorKeyAlert : alert}];
    !self.manager.payFailure ? : self.manager.payFailure(error);
    
    self.manager.paySuccess = nil;
    self.manager.payFailure = nil;
}

#pragma mark - TencentLoginDelegate

/**
 * 登录成功后的回调
 */
- (void)tencentDidLogin {
    AKQQManagerLog(@"用户登录，获取用户信息");
    [self.oauth getUserInfo];
    if([self.oauth RequestUnionId]) {
        AKQQManagerLog(@"用户登录，获取UnionID");
    }
}

/**
 * 登录失败后的回调
 * \param cancelled 代表用户是否主动退出登录
 */
- (void)tencentDidNotLogin:(BOOL)cancelled {
    AKQQManagerLog(@"用户登录失败");
    
    NSInteger code = [[self.oauth getServerSideCode] integerValue];
    
    NSMutableDictionary *userInfo = [@{@"cancelled" : @(cancelled)} mutableCopy];
    if(cancelled) {
        userInfo[AKQQManagerErrorKeyAlert] = @"取消登录";
    } else {
        userInfo[AKQQManagerErrorKeyCode] = @(code);
        
        NSString *message = [TencentOAuth getLastErrorMsg];
        if(message.length) {
            userInfo[AKQQManagerErrorKeyDetail] = message;
        }
        
        userInfo[AKQQManagerErrorKeyAlert] = @"登录失败";
    }
    NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:code userInfo:userInfo];
    
    !self.loginFailure ? : self.loginFailure(error);
    
    self.loginSuccess = nil;
    self.loginFailure = nil;
}

/**
 * 登录时网络有问题的回调
 */
- (void)tencentDidNotNetWork {
    NSMutableDictionary *userInfo = [@{AKQQManagerErrorKeyAlert : @"登录失败，网络错误❌"} mutableCopy];
    
    NSInteger code = [[self.oauth getServerSideCode] integerValue];
    userInfo[AKQQManagerErrorKeyCode] = @(code);
    
    NSString *message = [TencentOAuth getLastErrorMsg];
    if(message.length) {
        userInfo[AKQQManagerErrorKeyDetail] = message;
    }
    
    NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:code userInfo:userInfo];
    
    !self.loginFailure ? : self.loginFailure(error);
    
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
    AKQQManagerLog(@"获取unionID");
}

/**
 * 退出登录的回调
 */
- (void)tencentDidLogout {
    AKQQManagerLog(@"用户退出登录");
}

/**
 * 因用户未授予相应权限而需要执行增量授权。在用户调用某个api接口时，如果服务器返回操作未被授权，则触发该回调协议接口，由第三方决定是否跳转到增量授权页面，让用户重新授权。
 * \param tencentOAuth 登录授权对象。
 * \param permissions 需增量授权的权限列表。
 * \return 是否仍然回调返回原始的api请求结果。
 * \note 不实现该协议接口则默认为不开启增量授权流程。若需要增量授权请调用\ref TencentOAuth#incrAuthWithPermissions: \n注意：增量授权时用户可能会修改登录的帐号
 */
- (BOOL)tencentNeedPerformIncrAuth:(TencentOAuth *)tencentOAuth withPermissions:(NSArray *)permissions {
    AKQQManagerLog(@"授权范围不足，需扩大授权范围");
    return YES;
}

/**
 * [该逻辑未实现]因token失效而需要执行重新登录授权。在用户调用某个api接口时，如果服务器返回token失效，则触发该回调协议接口，由第三方决定是否跳转到登录授权页面，让用户重新授权。
 * \param tencentOAuth 登录授权对象。
 * \return 是否仍然回调返回原始的api请求结果。
 * \note 不实现该协议接口则默认为不开启重新登录授权流程。若需要重新登录授权请调用\ref TencentOAuth#reauthorizeWithPermissions: \n注意：重新登录授权时用户可能会修改登录的帐号
 */
- (BOOL)tencentNeedPerformReAuth:(TencentOAuth *)tencentOAuth {
    AKQQManagerLog(@"授权信息过期，需重新授权");
    return NO;
}

/**
 * 用户通过增量授权流程重新授权登录，token及有效期限等信息已被更新。
 * \param tencentOAuth token及有效期限等信息更新后的授权实例对象
 * \note 第三方应用需更新已保存的token及有效期限等信息。
 */
- (void)tencentDidUpdate:(TencentOAuth *)tencentOAuth {
    AKQQManagerLog(@"授权信息更新");
}

/**
 * 用户增量授权过程中因取消或网络问题导致授权失败
 * \param reason 授权失败原因，具体失败原因参见sdkdef.h文件中\ref UpdateFailType
 */
- (void)tencentFailedUpdate:(UpdateFailType)reason {
    AKQQManagerLog(@"授权信息更新失败");
}

/**
 * 获取用户个人信息回调
 * \param response API返回结果，具体定义参见sdkdef.h文件中\ref APIResponse
 * \remarks 正确返回示例: \snippet example/getUserInfoResponse.exp success
 *          错误返回示例: \snippet example/getUserInfoResponse.exp fail
 */
- (void)getUserInfoResponse:(APIResponse*)response {
    if(response.retCode != URLREQUEST_SUCCEED) {
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                             code:response.retCode
                                         userInfo:@{AKQQManagerErrorKeyCode : @(response.retCode),
                                                    AKQQManagerErrorKeyAlert : [self alertForNetwork:response.retCode]}];
        !self.loginFailure ? : self.loginFailure(error);
        
        self.loginSuccess = nil;
        self.loginFailure = nil;
        
        return;
    }
    
    if(response.detailRetCode != kOpenSDKErrorSuccess) {
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                             code:response.detailRetCode
                                         userInfo:@{AKQQManagerErrorKeyCode : @(response.detailRetCode),
                                                    AKQQManagerErrorKeyAlert : [self alertForOpenAPI:response.detailRetCode]}];
        !self.loginFailure ? : self.loginFailure(error);
        
        self.loginSuccess = nil;
        self.loginFailure = nil;
        
        return;
    }
    
    //这些做SDK的都是傻逼么...SDK文档缺失太严重了，没有返回的字段说明！！！
    //获取用户信息相关文档在这里：http://wiki.connect.qq.com/get_user_info
    
    AKQQUser *user = [[AKQQUser alloc] init];
    user.accessToken = self.oauth.accessToken;
    user.refreshToken = nil;
    user.expiredTime = self.oauth.expirationDate.timeIntervalSince1970;
    user.openID = self.oauth.openId;
    user.unionID = self.oauth.unionid;
    user.nickname = response.jsonResponse[@"nickname"];
    user.portrait = response.jsonResponse[@"figureurl_qq_2"];
    if(!user.portrait.length) {
        user.portrait = response.jsonResponse[@"figureurl_qq_1"];
    }
    
    !self.loginSuccess ? : self.loginSuccess(user);
    
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
            if(![resp.result isEqualToString:@"success"]) {
                NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                                     code:0
                                                 userInfo:@{AKQQManagerErrorKeyAlert : resp.result,
                                                            AKQQManagerErrorKeyDetail : resp.errorDescription}];
                !self.shareFailure ? : self.shareFailure(error);
                
                self.shareSuccess = nil;
                self.shareFailure = nil;
                return;
            }
            
            !self.shareSuccess ? : self.shareSuccess();
            
            self.shareSuccess = nil;
            self.shareFailure = nil;
            
            break;
        }
        default:
            break;
    }
}

@end
