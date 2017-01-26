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

- (SendMessageToQQReq *)request {
    return [SendMessageToQQReq reqWithContent:self.message];
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
    message.title = self.title;
    message.description = self.detail;
    
    NSData *imageData = UIImagePNGRepresentation(self.image);
    if(imageData) {
        imageData = UIImageJPEGRepresentation(self.image, 1.);
    }
    message.data = imageData;
    
    NSData *previewImageData = UIImagePNGRepresentation(self.previewImage);
    if(previewImageData) {
        previewImageData = UIImageJPEGRepresentation(self.previewImage, 1.);
    }
    message.previewImageData = previewImageData;

    return message;
}

@end

@implementation AKQQShareGroupImage

- (QQApiObject *)message {
    QQApiGroupTribeImageObject *message = [[QQApiGroupTribeImageObject alloc] init];
    message.title = self.title;
    message.description = self.detail;
    
    NSData *imageData = UIImagePNGRepresentation(self.image);
    if(imageData) {
        imageData = UIImageJPEGRepresentation(self.image, 1.);
    }
    message.data = imageData;
    
    NSData *previewImageData = UIImagePNGRepresentation(self.previewImage);
    if(previewImageData) {
        previewImageData = UIImageJPEGRepresentation(self.previewImage, 1.);
    }
    message.previewImageData = previewImageData;
    
    message.bid = self.groupBlogID;
    message.bname = self.groupBlogName;
    
    return message;
}

@end

@implementation AKQQShareBaseMedia

- (QQApiObject *)messageWithType:(QQApiURLTargetType)type {
    QQApiURLObject *message = nil;
    switch (type) {
        case QQApiURLTargetTypeNews: {
            message = [[QQApiNewsObject alloc] init];
            break;
        }
        case QQApiURLTargetTypeAudio: {
            message = [[QQApiAudioObject alloc] init];
            break;
        }
        case QQApiURLTargetTypeVideo: {
            message = [[QQApiVideoObject alloc] init];
            break;
        }
        default:
            break;
    }
    
    message.title = self.title;
    message.description = self.detail;
    
    if(self.previewImage) {
        NSData *previewImageData = UIImagePNGRepresentation(self.previewImage);
        if(previewImageData) {
            previewImageData = UIImageJPEGRepresentation(self.previewImage, 1.);
        }
        message.previewImageData = previewImageData;
    }
    
    if(self.previewImageURL.length) {
        message.previewImageURL = self.previewImageURL;
    }
    
    message.targetContentType = type;
    message.url = self.URL;
    
    return message;
}

@end

@implementation AKQQShareWeb

- (QQApiObject *)message {
    return [super messageWithType:QQApiURLTargetTypeNews];
}

@end

@implementation AKQQShareAudio

- (QQApiObject *)message {
    QQApiAudioObject *message = [super messageWithType:QQApiURLTargetTypeAudio];
    if(self.streamURL.length) {
        message.flashURL = [NSURL URLWithString:self.streamURL];
    }
    return message;
}

@end

@implementation AKQQShareVideo

- (QQApiObject *)message {
    QQApiVideoObject *message = [super messageWithType:QQApiURLTargetTypeVideo];
    if(self.streamURL.length) {
        message.flashURL = [NSURL URLWithString:self.streamURL];
    }
    return message;
}

@end

#pragma mark -

@implementation AKQQShareQZoneImage

- (QQApiObject *)message {
    QQApiImageArrayForQZoneObject *message = [[QQApiImageArrayForQZoneObject alloc] init];
    message.title = self.title;
    message.description = self.detail;
    
    NSMutableArray<NSData *> *imageDatas = [NSMutableArray array];
    for(UIImage *image in self.images) {
        NSData *imageData = UIImagePNGRepresentation(image);
        if(imageData) {
            imageData = UIImageJPEGRepresentation(image, 1.);
        }
        
        if(!imageData) {
            continue;
        }
        
        [imageDatas addObject:imageData];
    }
    message.imageDataArray = [imageDatas copy];
    
    return message;
}

@end

@implementation AKQQShareQZoneVideo

- (QQApiObject *)message {
    QQApiVideoForQZoneObject *message = [[QQApiVideoForQZoneObject alloc] init];
    message.title = self.title;
    message.description = self.detail;
    
    message.assetURL = self.assetURL;
    
    return message;
}

@end

