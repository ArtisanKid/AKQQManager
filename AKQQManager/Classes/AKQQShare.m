//
//  AKQQShare.m
//  Pods
//
//  Created by 李翔宇 on 2017/1/17.
//
//

#import "AKQQShare.h"

@implementation AKQQShare

/**
 子类重载此方法
 
 @return WBMessageObject
 */
- (QQApiObject *)message {
    return nil;
}

- (void)complete:(QQApiObject *)message {
    if([self.title isKindOfClass:[NSString class]]
       && self.title.length) {
        message.title = self.title;
    }
    
    if([self.detail isKindOfClass:[NSString class]]
       && self.detail.length) {
        message.description = self.detail;
    }
}

- (SendMessageToQQReq *)request {
    return [SendMessageToQQReq reqWithContent:[self message]];
}

@end

#pragma mark -

@implementation AKQQShareText

- (QQApiObject *)message {
    QQApiTextObject *message = [QQApiTextObject objectWithText:self.text];
    return message;
}

@end

@implementation AKQQShareImage

- (QQApiObject *)message {
    QQApiImageObject *message = [[QQApiImageObject alloc] init];
    [self complete:message];
    return message;
}

- (void)complete:(QQApiImageObject *)message {
    [super complete:message];
    
    if([self.image isKindOfClass:[UIImage class]]) {
        NSData *imageData = UIImagePNGRepresentation(self.image);
        if(!imageData.length) {
            imageData = UIImageJPEGRepresentation(self.image, 1.);
        }
        if(imageData.length) {
            message.data = imageData;
        }
    }
    
    if([self.previewImage isKindOfClass:[UIImage class]]) {
        NSData *previewImageData = UIImagePNGRepresentation(self.previewImage);
        if(!previewImageData.length) {
            previewImageData = UIImageJPEGRepresentation(self.previewImage, 1.);
        }
        if(previewImageData.length) {
            message.previewImageData = previewImageData;
        }
    }
}

@end

@implementation AKQQShareFavorImage

- (QQApiObject *)message {
    QQApiImageObject *message = [[QQApiImageObject alloc] init];
    [self complete:message];
    return message;
}

- (void)complete:(QQApiImageObject *)message {
    [super complete:message];
    
    message.cflag = kQQAPICtrlFlagQQShareFavorites;
    
    NSMutableArray<NSData *> *imageDatasM = [NSMutableArray array];
    for(UIImage *image in self.favorImages) {
        if(![image isKindOfClass:[UIImage class]]) {
            continue;
        }
        
        NSData *imageData = UIImagePNGRepresentation(image);
        if(!imageData.length) {
            imageData = UIImageJPEGRepresentation(image, 1.);
        }
        if(!imageData.length) {
            continue;
        }
        
        [imageDatasM addObject:imageData];
    }
    message.imageDataArray = [imageDatasM copy];
}

@end

@implementation AKQQShareGroupImage

- (QQApiObject *)message {
    QQApiGroupTribeImageObject *message = [[QQApiGroupTribeImageObject alloc] init];
    [super complete:message];
    
    message.bid = self.groupBlogID;
    message.bname = self.groupBlogName;
    
    return message;
}

@end

@implementation AKQQShareURL

- (QQApiObject *)message {
    QQApiURLObject *message = [[QQApiURLObject alloc] init];
    [self complete:message];
    return message;
}

- (void)complete:(QQApiURLObject *)message {
    [super complete:message];
    
    if([self.URL isKindOfClass:[NSString class]]
       && self.URL.length) {
        message.url = [NSURL URLWithString:self.URL];
    }
    
    if([self.previewImage isKindOfClass:[UIImage class]]) {
        NSData *previewImageData = UIImagePNGRepresentation(self.previewImage);
        if(!previewImageData.length) {
            previewImageData = UIImageJPEGRepresentation(self.previewImage, 1.);
        }
        if(previewImageData.length) {
            message.previewImageData = previewImageData;
        }
    }
    
    if([self.previewImageURL isKindOfClass:[NSString class]]
       && self.previewImageURL.length) {
        message.previewImageURL = [NSURL URLWithString:self.previewImageURL];
    }
}

@end

@implementation AKQQShareWeb

- (QQApiObject *)message {
    QQApiNewsObject *message = [[QQApiNewsObject alloc] init];
    [super complete:message];
    return message;
}

@end

@implementation AKQQShareAudio

- (QQApiObject *)message {
    QQApiAudioObject *message = [[QQApiAudioObject alloc] init];
    [super complete:message];
    
    if([self.streamURL isKindOfClass:[NSString class]]
       && self.streamURL.length) {
        message.flashURL = [NSURL URLWithString:self.streamURL];
    }
    return message;
}

@end

@implementation AKQQShareVideo

- (QQApiObject *)message {
    QQApiVideoObject *message = [[QQApiVideoObject alloc] init];
    [super complete:message];
    
    if([self.streamURL isKindOfClass:[NSString class]]
       && self.streamURL.length) {
        message.flashURL = [NSURL URLWithString:self.streamURL];
    }
    return message;
}

@end

#pragma mark -

@implementation AKQQShareQZoneImage

- (QQApiObject *)message {
    QQApiImageArrayForQZoneObject *message = [[QQApiImageArrayForQZoneObject alloc] init];
    [self complete:message];
    return message;
}

- (void)complete:(QQApiImageArrayForQZoneObject *)message {
    [super complete:message];
    
    NSMutableArray<NSData *> *imageDatasM = [NSMutableArray array];
    for(UIImage *image in self.images) {
        if(![image isKindOfClass:[UIImage class]]) {
            continue;
        }
        
        NSData *imageData = UIImagePNGRepresentation(image);
        if(!imageData.length) {
            imageData = UIImageJPEGRepresentation(image, 1.);
        }
        if(!imageData.length) {
            continue;
        }
        
        [imageDatasM addObject:imageData];
    }
    message.imageDataArray = [imageDatasM copy];
}

@end

@implementation AKQQShareQZoneVideo

- (QQApiObject *)message {
    QQApiVideoForQZoneObject *message = [[QQApiVideoForQZoneObject alloc] init];
    [self complete:message];
    return message;
}

- (void)complete:(QQApiVideoForQZoneObject *)message {
    [super complete:message];
    
    if([self.assetURL isKindOfClass:[NSString class]]
       && self.assetURL.length) {
        message.assetURL = self.assetURL;
    }
}

@end

