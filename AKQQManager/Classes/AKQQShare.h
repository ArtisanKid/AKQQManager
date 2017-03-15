//
//  AKQQShare.h
//  Pods
//
//  Created by 李翔宇 on 2017/1/17.
//
//

#import <Foundation/Foundation.h>
#import "AKQQShareProtocol.h"

@interface AKQQShare : NSObject

@property(nonatomic, copy) NSString* title; ///<标题，最长128个字符
@property(nonatomic, copy) NSString* detail; ///<简要描述，最长512个字符

@end

#pragma mark - AKQQShareText : AKQQShare

@interface AKQQShareText : AKQQShare<AKQQShareProtocol>

@property (nonatomic, copy) NSString *text;///<文本内容，必填，最长1536个字符

@end

#pragma mark - AKQQShareImage : AKQQShare

@interface AKQQShareImage : AKQQShare<AKQQShareProtocol>

@property(nonatomic, strong) UIImage *image; ///<具体数据内容，必填，最大5M字节
@property(nonatomic, strong) UIImage *previewImage; ///<预览图像，最大1M字节

@end

#pragma mark - AKQQShareFavorImage : AKQQShareImage

@interface AKQQShareFavorImage : AKQQShareImage

@property (nonatomic, strong) NSArray<UIImage *> *favorImages; ///<收藏图片数组

@end

#pragma mark - AKQQShareGroupImage : AKQQShareImage

@interface AKQQShareGroupImage : AKQQShareImage

// 群部落id
@property (nonatomic, strong) NSString *groupBlogID;

// 群部落名称
@property (nonatomic, strong) NSString *groupBlogName;

@end

#pragma mark - AKQQShareURL : AKQQShare

@interface AKQQShareURL : AKQQShare

/**
 对象唯一ID，用于唯一标识一个多媒体内容
 当第三方应用分享多媒体内容到微博时，应该将此参数设置为被分享的内容在自己的系统中的唯一标识
 不能为空，长度小于255字节
 */
@property (nonatomic, copy) NSString *mediaID;

//预览图像数据与预览图像URL可二选一
@property(nonatomic, strong) UIImage *previewImage ;///<预览图像数据，最大1M字节
@property(nonatomic, copy) NSString *previewImageURL;///<预览图像URL

@property(nonatomic, copy) NSString *URL; ///<URL地址，必填，最长512个字符

@end

#pragma mark - AKQQShareWeb : AKQQShareURL

@interface AKQQShareWeb : AKQQShareURL<AKQQShareProtocol>

@end

#pragma mark - AKQQShareAudio : AKQQShareURL

@interface AKQQShareAudio : AKQQShareURL

@property (nonatomic, copy) NSString *streamURL;///<音频URL地址，最长512个字符

@end

#pragma mark - AKQQShareVideo : AKQQShareURL

@interface AKQQShareVideo : AKQQShareURL<AKQQShareProtocol>

@property (nonatomic, copy) NSString *streamURL;///<视频URL地址，最长512个字符

@end

#pragma mark - AKQQShareQZoneImage : AKQQShare

@interface AKQQShareQZoneImage : AKQQShare<AKQQShareProtocol>

@property(nonatomic, strong) NSArray<UIImage *> *images;///图片数组

@end

#pragma mark - AKQQShareQZoneVideo : AKQQShare

@interface AKQQShareQZoneVideo : AKQQShare<AKQQShareProtocol>

@property(nonatomic, copy) NSString *assetURL;

@end
