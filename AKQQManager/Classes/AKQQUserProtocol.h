//
//  AKQQUserProtocol.h
//  Pods
//
//  Created by 李翔宇 on 2017/1/17.
//
//

#import <Foundation/Foundation.h>

@protocol AKQQUserProtocol <NSObject>

@property (nonatomic, copy) NSString *accessToken;/**<OAuth2的accessToken*/
@property (nonatomic, copy) NSString *refreshToken;/**<OAuth2的refreshToken*/
@property (nonatomic, assign) NSTimeInterval expiredTime;/**<过期时间戳*/
@property (nonatomic, copy) NSString *openID;/**<用户的openID*/
@property (nonatomic, copy) NSString *unionID;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *portrait;/**<头像*/

@end
